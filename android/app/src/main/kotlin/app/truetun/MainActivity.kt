package app.truetun

import android.app.Activity
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.VpnService
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import app.truetun.vpn.LibboxRuntime
import app.truetun.vpn.TrueTunConfigStore
import app.truetun.vpn.TrueTunRuntime
import app.truetun.vpn.TrueTunVpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.nekohasekai.libbox.Libbox
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val worker = Executors.newSingleThreadExecutor()
    private var pendingVpnPermissionResult: MethodChannel.Result? = null
    private var eventListener: ((Map<String, Any?>) -> Unit)? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        LibboxRuntime.ensureInitialized(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "prepareVpn" -> prepareVpn(result)
                    "start" -> {
                        val config = call.argument<String>("configJson")
                        val profileName = call.argument<String>("profileName")
                        if (config.isNullOrBlank()) {
                            result.error("INVALID_CONFIG", "Configuration is empty", null)
                        } else {
                            startVpn(config, profileName, result)
                        }
                    }
                    "stop" -> {
                        startService(
                            Intent(this, TrueTunVpnService::class.java)
                                .setAction(TrueTunVpnService.ACTION_STOP),
                        )
                        result.success(true)
                    }
                    "openVpnSettings" -> {
                        startActivity(Intent(Settings.ACTION_VPN_SETTINGS))
                        result.success(true)
                    }
                    "getState" -> result.success(TrueTunRuntime.snapshot())
                    "getCapabilities" -> result.success(
                        mapOf(
                            "name" to "sing-box libbox",
                            "version" to LibboxRuntime.version(this),
                            "protocols" to listOf(
                                "vless",
                                "vmess",
                                "trojan",
                                "shadowsocks",
                                "hysteria2",
                                "tuic",
                                "ssh",
                                "wireguard",
                            ),
                            "features" to listOf(
                                "tun",
                                "route-rules",
                                "rule-sets",
                                "urltest",
                                "android-app-routing",
                                "native-metrics",
                            ),
                        ),
                    )
                    "validateConfig" -> {
                        val config = call.argument<String>("configJson")
                        if (config.isNullOrBlank()) {
                            result.error("INVALID_CONFIG", "Configuration is empty", null)
                        } else {
                            worker.execute {
                                runCatching { Libbox.checkConfig(config) }
                                    .onSuccess { runOnUiThread { result.success(true) } }
                                    .onFailure {
                                        runOnUiThread {
                                            result.error(
                                                "CONFIG_REJECTED",
                                                it.message ?: it.toString(),
                                                null,
                                            )
                                        }
                                    }
                            }
                        }
                    }
                    "getInstalledApps" -> worker.execute {
                        val apps = installedApps()
                        runOnUiThread { result.success(apps) }
                    }
                    "getDiagnostics" -> result.success(
                        mapOf(
                            "appVersion" to BuildConfig.VERSION_NAME,
                            "coreVersion" to LibboxRuntime.version(this),
                            "androidVersion" to Build.VERSION.RELEASE,
                            "sdk" to Build.VERSION.SDK_INT,
                            "manufacturer" to Build.MANUFACTURER,
                            "model" to Build.MODEL,
                            "packageName" to packageName,
                            "state" to TrueTunRuntime.snapshot(),
                        ),
                    )
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    val listener: (Map<String, Any?>) -> Unit = { event -> events.success(event) }
                    eventListener?.let(TrueTunRuntime::removeListener)
                    eventListener = listener
                    TrueTunRuntime.addListener(listener)
                    events.success(mapOf("type" to "state", "state" to TrueTunRuntime.state.wireName))
                    val snapshot = TrueTunRuntime.snapshot()
                    events.success(
                        mapOf(
                            "type" to "traffic",
                            "upload" to snapshot["upload"],
                            "download" to snapshot["download"],
                            "uploadPerSecond" to snapshot["uploadPerSecond"],
                            "downloadPerSecond" to snapshot["downloadPerSecond"],
                        ),
                    )
                }

                override fun onCancel(arguments: Any?) {
                    eventListener?.let(TrueTunRuntime::removeListener)
                    eventListener = null
                }
            })
    }

    private fun prepareVpn(result: MethodChannel.Result) {
        val intent = VpnService.prepare(this)
        if (intent == null) {
            result.success(true)
            return
        }
        if (pendingVpnPermissionResult != null) {
            result.error("VPN_PERMISSION_PENDING", "VPN permission request is already active", null)
            return
        }
        pendingVpnPermissionResult = result
        @Suppress("DEPRECATION")
        startActivityForResult(intent, VPN_PERMISSION_REQUEST)
    }

    private fun startVpn(
        config: String,
        profileName: String?,
        result: MethodChannel.Result,
    ) {
        if (VpnService.prepare(this) != null) {
            result.error("VPN_PERMISSION_REQUIRED", "Call prepareVpn before start", null)
            return
        }
        TrueTunConfigStore.save(this, config, profileName)
        TrueTunConfigStore.markStarted(this, true)
        val intent = Intent(this, TrueTunVpnService::class.java)
            .setAction(TrueTunVpnService.ACTION_START)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        result.success(true)
    }

    @Deprecated("Deprecated in Android")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != VPN_PERMISSION_REQUEST) return
        val pending = pendingVpnPermissionResult ?: return
        pendingVpnPermissionResult = null
        pending.success(resultCode == Activity.RESULT_OK)
    }

    override fun onDestroy() {
        eventListener?.let(TrueTunRuntime::removeListener)
        eventListener = null
        pendingVpnPermissionResult?.error(
            "ACTIVITY_DESTROYED",
            "VPN permission activity was destroyed",
            null,
        )
        pendingVpnPermissionResult = null
        worker.shutdownNow()
        super.onDestroy()
    }

    private fun installedApps(): List<Map<String, Any?>> {
        val packageManager = packageManager
        val applications = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getInstalledApplications(
                PackageManager.ApplicationInfoFlags.of(0),
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.getInstalledApplications(0)
        }
        return applications.map { app ->
            val packageName = app.packageName
            val isSystem = app.flags and ApplicationInfo.FLAG_SYSTEM != 0
            mapOf(
                "packageName" to packageName,
                "label" to runCatching { packageManager.getApplicationLabel(app).toString() }
                    .getOrDefault(packageName),
                "category" to classifyApp(packageName, app, isSystem),
                "isSystem" to isSystem,
                "uid" to app.uid,
            )
        }.sortedWith(
            compareBy<Map<String, Any?>>(
                { it["isSystem"] as Boolean },
                { (it["label"] as String).lowercase() },
            ),
        )
    }

    private fun classifyApp(
        packageName: String,
        app: ApplicationInfo,
        isSystem: Boolean,
    ): String {
        if (packageName == this.packageName) return "vpnOrProxy"
        if (isSystem) return "system"
        val value = packageName.lowercase()
        if (listOf("vpn", "proxy", "wireguard", "clash", "hiddify", "v2ray", "singbox", "sing-box")
                .any(value::contains)
        ) return "vpnOrProxy"
        if (listOf("chrome", "firefox", "browser", "edge", "brave", "opera").any(value::contains)) {
            return "browser"
        }
        if (listOf("telegram", "whatsapp", "signal", "discord", "messenger").any(value::contains)) {
            return "messaging"
        }
        if (listOf("youtube", "netflix", "spotify", "twitch", "kinopoisk").any(value::contains)) {
            return "streaming"
        }
        if (listOf("instagram", "tiktok", "reddit", "twitter", "threads").any(value::contains)) {
            return "social"
        }
        if (listOf("bank", "banking", "wallet", "pay").any(value::contains)) return "banking"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && app.category == ApplicationInfo.CATEGORY_GAME) {
            return "game"
        }
        return "other"
    }

    companion object {
        private const val METHOD_CHANNEL = "truetun/core"
        private const val EVENT_CHANNEL = "truetun/core/events"
        private const val VPN_PERMISSION_REQUEST = 7101
    }
}
