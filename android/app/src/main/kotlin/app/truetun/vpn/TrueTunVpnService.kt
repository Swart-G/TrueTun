package app.truetun.vpn

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.TrafficStats
import android.net.VpnService
import android.os.Build
import android.os.IBinder
import android.os.ParcelFileDescriptor
import android.os.Process
import android.os.SystemClock
import android.util.Log
import app.truetun.MainActivity
import app.truetun.R
import io.nekohasekai.libbox.CommandServer
import io.nekohasekai.libbox.CommandServerHandler
import io.nekohasekai.libbox.Libbox
import io.nekohasekai.libbox.OverrideOptions
import io.nekohasekai.libbox.SystemProxyStatus
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit

class TrueTunVpnService : VpnService(), CommandServerHandler {
    private val coreExecutor = Executors.newSingleThreadExecutor()
    private val metricsExecutor = Executors.newSingleThreadScheduledExecutor()
    private lateinit var platformInterface: TrueTunPlatformInterface
    private var commandServer: CommandServer? = null
    private var tunDescriptor: ParcelFileDescriptor? = null
    private var metricsTask: ScheduledFuture<*>? = null
    private var lastNotificationUpdate = 0L

    override fun onCreate() {
        super.onCreate()
        LibboxRuntime.ensureInitialized(this)
        platformInterface = TrueTunPlatformInterface(this)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> requestStop()
            ACTION_START, null -> requestStart()
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent): IBinder? = super.onBind(intent)

    override fun onRevoke() {
        TrueTunRuntime.log("Android revoked VPN permission", true)
        requestStop()
    }

    override fun onDestroy() {
        stopMetrics()
        runCatching { closeTunDescriptor() }
        runCatching { commandServer?.closeService() }
        runCatching { commandServer?.close() }
        commandServer = null
        if (::platformInterface.isInitialized) platformInterface.close()
        coreExecutor.shutdownNow()
        metricsExecutor.shutdownNow()
        if (TrueTunRuntime.state != TrueTunRuntime.State.STOPPED) {
            TrueTunRuntime.setState(TrueTunRuntime.State.STOPPED)
        }
        super.onDestroy()
    }

    private fun requestStart() {
        if (TrueTunRuntime.state == TrueTunRuntime.State.STARTING ||
            TrueTunRuntime.state == TrueTunRuntime.State.RUNNING
        ) {
            return
        }
        if (prepare(this) != null) {
            TrueTunRuntime.fail("Android VPN permission is required")
            stopSelf()
            return
        }
        if (!TrueTunConfigStore.wasStarted(this)) {
            TrueTunConfigStore.markStarted(this, true)
        }
        val config = TrueTunConfigStore.readConfig(this)
        if (config.isNullOrBlank()) {
            TrueTunRuntime.fail("No Android VPN configuration is available")
            TrueTunConfigStore.markStarted(this, false)
            stopSelf()
            return
        }

        TrueTunRuntime.setState(TrueTunRuntime.State.STARTING)
        startForeground(NOTIFICATION_ID, buildNotification("Starting…"))
        coreExecutor.execute { startCore(config) }
    }

    private fun startCore(config: String) {
        try {
            Libbox.checkConfig(config)
            stopCoreInternal(updateState = false)
            val server = CommandServer(this, platformInterface)
            server.start()
            server.startOrReloadService(config, OverrideOptions())
            commandServer = server
            TrueTunRuntime.setState(TrueTunRuntime.State.RUNNING)
            TrueTunRuntime.log("Embedded sing-box ${Libbox.version()} started")
            updateNotification("Connected")
            startMetrics()
        } catch (error: Throwable) {
            Log.e(TAG, "Unable to start VPN core", error)
            runCatching { commandServer?.close() }
            commandServer = null
            closeTunDescriptor()
            TrueTunConfigStore.markStarted(this, false)
            TrueTunRuntime.fail(error.message ?: error.toString())
            stopForegroundCompat()
            stopSelf()
        }
    }

    private fun requestStop() {
        if (TrueTunRuntime.state == TrueTunRuntime.State.STOPPING) return
        if (TrueTunRuntime.state == TrueTunRuntime.State.STOPPED) {
            TrueTunConfigStore.markStarted(this, false)
            stopSelf()
            return
        }
        TrueTunRuntime.setState(TrueTunRuntime.State.STOPPING)
        updateNotification("Disconnecting…")
        coreExecutor.execute {
            stopCoreInternal(updateState = true)
            TrueTunConfigStore.markStarted(this, false)
            stopForegroundCompat()
            stopSelf()
        }
    }

    private fun stopCoreInternal(updateState: Boolean) {
        stopMetrics()
        closeTunDescriptor()
        val server = commandServer
        commandServer = null
        if (server != null) {
            runCatching { server.closeService() }
                .onFailure { TrueTunRuntime.log("Core closeService: ${it.message}", true) }
            runCatching { server.close() }
                .onFailure { TrueTunRuntime.log("Core close: ${it.message}", true) }
        }
        if (updateState) {
            TrueTunRuntime.traffic(0, 0, 0, 0)
            TrueTunRuntime.setState(TrueTunRuntime.State.STOPPED)
        }
    }

    @Synchronized
    fun setTunDescriptor(descriptor: ParcelFileDescriptor) {
        tunDescriptor = descriptor
    }

    @Synchronized
    fun closeTunDescriptor() {
        val descriptor = tunDescriptor
        tunDescriptor = null
        descriptor?.close()
    }

    private fun startMetrics() {
        stopMetrics()
        val uid = Process.myUid()
        val baseTx = trafficValue(TrafficStats.getUidTxBytes(uid))
        val baseRx = trafficValue(TrafficStats.getUidRxBytes(uid))
        var previousTx = baseTx
        var previousRx = baseRx
        var previousAt = SystemClock.elapsedRealtime()
        metricsTask = metricsExecutor.scheduleAtFixedRate({
            if (TrueTunRuntime.state != TrueTunRuntime.State.RUNNING) return@scheduleAtFixedRate
            val now = SystemClock.elapsedRealtime()
            val currentTx = trafficValue(TrafficStats.getUidTxBytes(uid))
            val currentRx = trafficValue(TrafficStats.getUidRxBytes(uid))
            val elapsed = (now - previousAt).coerceAtLeast(1)
            val uploadTotal = (currentTx - baseTx).coerceAtLeast(0)
            val downloadTotal = (currentRx - baseRx).coerceAtLeast(0)
            val uploadRate = ((currentTx - previousTx).coerceAtLeast(0) * 1000L) / elapsed
            val downloadRate = ((currentRx - previousRx).coerceAtLeast(0) * 1000L) / elapsed
            previousTx = currentTx
            previousRx = currentRx
            previousAt = now
            TrueTunRuntime.traffic(uploadTotal, downloadTotal, uploadRate, downloadRate)
            if (now - lastNotificationUpdate >= 2000) {
                lastNotificationUpdate = now
                updateNotification(
                    "Connected • ↓ ${formatRate(downloadRate)}  ↑ ${formatRate(uploadRate)}",
                )
            }
        }, 0, 1000, TimeUnit.MILLISECONDS)
    }

    private fun stopMetrics() {
        metricsTask?.cancel(false)
        metricsTask = null
    }

    private fun trafficValue(value: Long): Long =
        if (value == TrafficStats.UNSUPPORTED.toLong() || value < 0) 0 else value

    private fun formatRate(bytesPerSecond: Long): String = when {
        bytesPerSecond >= 1024L * 1024L -> String.format("%.1f MB/s", bytesPerSecond / 1048576.0)
        bytesPerSecond >= 1024L -> String.format("%.0f KB/s", bytesPerSecond / 1024.0)
        else -> "$bytesPerSecond B/s"
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                "TrueTun VPN",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Active TrueTun VPN connection"
                setShowBadge(false)
            },
        )
    }

    private fun buildNotification(status: String): Notification {
        val openIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val stopIntent = PendingIntent.getService(
            this,
            1,
            Intent(this, TrueTunVpnService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        return builder
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(TrueTunConfigStore.profileName(this))
            .setContentText(status)
            .setContentIntent(openIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(Notification.CATEGORY_SERVICE)
            .addAction(
                Notification.Action.Builder(
                    android.R.drawable.ic_menu_close_clear_cancel,
                    "Disconnect",
                    stopIntent,
                ).build(),
            )
            .build()
    }

    private fun updateNotification(status: String) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, buildNotification(status))
    }

    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    override fun serviceStop() {
        requestStop()
    }

    override fun serviceReload() {
        val config = TrueTunConfigStore.readConfig(this)
            ?: error("android: missing saved configuration")
        commandServer?.startOrReloadService(config, OverrideOptions())
            ?: error("android: core is not running")
    }

    override fun getSystemProxyStatus(): SystemProxyStatus? = null

    override fun setSystemProxyEnabled(isEnabled: Boolean) = Unit

    override fun triggerNativeCrash() {
        throw RuntimeException("TrueTun native crash requested")
    }

    override fun writeDebugMessage(message: String?) {
        if (!message.isNullOrBlank()) TrueTunRuntime.log(message)
    }

    override fun connectSSHAgent(): Int = -1

    companion object {
        const val ACTION_START = "app.truetun.action.START_VPN"
        const val ACTION_STOP = "app.truetun.action.STOP_VPN"
        private const val CHANNEL_ID = "truetun-vpn"
        private const val NOTIFICATION_ID = 1001
        private const val TAG = "TrueTunVpnService"
    }
}
