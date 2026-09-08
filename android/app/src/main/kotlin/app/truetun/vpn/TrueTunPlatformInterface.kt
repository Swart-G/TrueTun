package app.truetun.vpn

import android.annotation.SuppressLint
import android.content.Context
import android.net.ConnectivityManager
import android.net.IpPrefix
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.system.OsConstants
import android.util.Log
import io.nekohasekai.libbox.BridgeOptions
import io.nekohasekai.libbox.BridgeSession
import io.nekohasekai.libbox.ConnectionOwner
import io.nekohasekai.libbox.InterfaceUpdateListener
import io.nekohasekai.libbox.Libbox
import io.nekohasekai.libbox.LocalDNSTransport
import io.nekohasekai.libbox.NeighborUpdateListener
import io.nekohasekai.libbox.NetworkInterfaceIterator
import io.nekohasekai.libbox.Notification
import io.nekohasekai.libbox.PlatformInterface
import io.nekohasekai.libbox.PlatformUser
import io.nekohasekai.libbox.ShellSession
import io.nekohasekai.libbox.StringIterator
import io.nekohasekai.libbox.TunOptions
import io.nekohasekai.libbox.WIFIState
import java.net.Inet6Address
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.NetworkInterface as JavaNetworkInterface
import java.util.Collections
import io.nekohasekai.libbox.NetworkInterface as BoxNetworkInterface

class TrueTunPlatformInterface(
    private val service: TrueTunVpnService,
) : PlatformInterface {
    private val connectivity =
        service.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    private val defaultNetworkMonitor = DefaultNetworkMonitor(connectivity)

    override fun localDNSTransport(): LocalDNSTransport? = null

    override fun usePlatformAutoDetectInterfaceControl(): Boolean = true

    override fun autoDetectInterfaceControl(fd: Int) {
        check(service.protect(fd)) { "android: unable to protect core socket from VPN recapture" }
    }

    override fun openTun(options: TunOptions): Int {
        check(android.net.VpnService.prepare(service) == null) {
            "android: missing VPN permission"
        }

        service.closeTunDescriptor()
        val builder = service.Builder()
            .setSession("TrueTun")
            .setMtu(options.mtu)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            builder.setMetered(false)
        }

        val inet4Address = options.inet4Address
        while (inet4Address.hasNext()) {
            val address = inet4Address.next()
            builder.addAddress(address.address(), address.prefix())
        }
        val inet6Address = options.inet6Address
        while (inet6Address.hasNext()) {
            val address = inet6Address.next()
            builder.addAddress(address.address(), address.prefix())
        }

        if (options.autoRoute) {
            if (options.dnsMode.value != Libbox.DNSModeDisabled) {
                val dnsServers = options.dnsServerAddress
                while (dnsServers.hasNext()) {
                    builder.addDnsServer(dnsServers.next())
                }
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                val inet4Routes = options.inet4RouteAddress
                if (inet4Routes.hasNext()) {
                    while (inet4Routes.hasNext()) {
                        val route = inet4Routes.next()
                        builder.addRoute(IpPrefix(InetAddress.getByName(route.address()), route.prefix()))
                    }
                } else if (options.inet4Address.hasNext()) {
                    builder.addRoute("0.0.0.0", 0)
                }

                val inet6Routes = options.inet6RouteAddress
                if (inet6Routes.hasNext()) {
                    while (inet6Routes.hasNext()) {
                        val route = inet6Routes.next()
                        builder.addRoute(IpPrefix(InetAddress.getByName(route.address()), route.prefix()))
                    }
                } else if (options.inet6Address.hasNext()) {
                    builder.addRoute("::", 0)
                }

                val inet4Exclude = options.inet4RouteExcludeAddress
                while (inet4Exclude.hasNext()) {
                    val route = inet4Exclude.next()
                    builder.excludeRoute(IpPrefix(InetAddress.getByName(route.address()), route.prefix()))
                }
                val inet6Exclude = options.inet6RouteExcludeAddress
                while (inet6Exclude.hasNext()) {
                    val route = inet6Exclude.next()
                    builder.excludeRoute(IpPrefix(InetAddress.getByName(route.address()), route.prefix()))
                }
            } else {
                val inet4Routes = options.inet4RouteRange
                while (inet4Routes.hasNext()) {
                    val route = inet4Routes.next()
                    builder.addRoute(route.address(), route.prefix())
                }
                val inet6Routes = options.inet6RouteRange
                while (inet6Routes.hasNext()) {
                    val route = inet6Routes.next()
                    builder.addRoute(route.address(), route.prefix())
                }
            }

            val includePackage = options.includePackage
            while (includePackage.hasNext()) {
                val packageName = includePackage.next()
                runCatching { builder.addAllowedApplication(packageName) }
                    .onFailure { Log.w(TAG, "Unable to allow package $packageName", it) }
            }
            val excludePackage = options.excludePackage
            while (excludePackage.hasNext()) {
                val packageName = excludePackage.next()
                runCatching { builder.addDisallowedApplication(packageName) }
                    .onFailure { Log.w(TAG, "Unable to exclude package $packageName", it) }
            }
        }

        val descriptor = builder.establish()
            ?: error("android: VPN interface could not be established")
        service.setTunDescriptor(descriptor)
        return descriptor.fd
    }

    override fun useProcFS(): Boolean = Build.VERSION.SDK_INT < Build.VERSION_CODES.Q

    @SuppressLint("NewApi")
    override fun findConnectionOwner(
        ipProtocol: Int,
        sourceAddress: String,
        sourcePort: Int,
        destinationAddress: String,
        destinationPort: Int,
    ): ConnectionOwner {
        check(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            "android: connection owner lookup requires Android 10+"
        }
        val uid = connectivity.getConnectionOwnerUid(
            ipProtocol,
            InetSocketAddress(sourceAddress, sourcePort),
            InetSocketAddress(destinationAddress, destinationPort),
        )
        check(uid != Process.INVALID_UID) { "android: connection owner not found" }
        val packages = service.packageManager.getPackagesForUid(uid)?.toList().orEmpty()
        return ConnectionOwner().also {
            it.userId = uid
            it.userName = packages.firstOrNull().orEmpty()
            it.setAndroidPackageNames(StringArray(packages))
        }
    }

    override fun startDefaultInterfaceMonitor(listener: InterfaceUpdateListener) {
        defaultNetworkMonitor.start(listener)
    }

    override fun closeDefaultInterfaceMonitor(listener: InterfaceUpdateListener) {
        defaultNetworkMonitor.stop(listener)
    }

    override fun getInterfaces(): NetworkInterfaceIterator {
        val androidNetworks = connectivity.allNetworks.mapNotNull { network ->
            val properties = connectivity.getLinkProperties(network) ?: return@mapNotNull null
            val name = properties.interfaceName ?: return@mapNotNull null
            val capabilities = connectivity.getNetworkCapabilities(network)
            name to NetworkMetadata(properties, capabilities)
        }.toMap()

        val interfaces = Collections.list(JavaNetworkInterface.getNetworkInterfaces()).map { networkInterface ->
            val metadata = androidNetworks[networkInterface.name]
            BoxNetworkInterface().also { boxInterface ->
                boxInterface.index = networkInterface.index
                boxInterface.name = networkInterface.name
                boxInterface.mtu = runCatching { networkInterface.mtu }.getOrDefault(1500)
                boxInterface.addresses = StringArray(
                    networkInterface.interfaceAddresses.map { address ->
                        val host = if (address.address is Inet6Address) {
                            Inet6Address.getByAddress(address.address.address).hostAddress
                        } else {
                            address.address.hostAddress
                        }
                        "$host/${address.networkPrefixLength}"
                    },
                )
                var flags = 0
                if (runCatching { networkInterface.isUp }.getOrDefault(false)) {
                    flags = flags or OsConstants.IFF_UP or OsConstants.IFF_RUNNING
                }
                if (runCatching { networkInterface.isLoopback }.getOrDefault(false)) {
                    flags = flags or OsConstants.IFF_LOOPBACK
                }
                if (runCatching { networkInterface.isPointToPoint }.getOrDefault(false)) {
                    flags = flags or OsConstants.IFF_POINTOPOINT
                }
                if (runCatching { networkInterface.supportsMulticast() }.getOrDefault(false)) {
                    flags = flags or OsConstants.IFF_MULTICAST
                }
                boxInterface.flags = flags
                boxInterface.type = when {
                    metadata?.capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true ->
                        Libbox.InterfaceTypeWIFI
                    metadata?.capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) == true ->
                        Libbox.InterfaceTypeCellular
                    metadata?.capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) == true ->
                        Libbox.InterfaceTypeEthernet
                    else -> Libbox.InterfaceTypeOther
                }
                boxInterface.dnsServer = StringArray(
                    metadata?.properties?.dnsServers?.mapNotNull { it.hostAddress }.orEmpty(),
                )
                boxInterface.gateway = StringArray(
                    metadata?.properties?.routes
                        ?.filter { it.destination.prefixLength == 0 }
                        ?.mapNotNull { it.gateway?.hostAddress }
                        .orEmpty(),
                )
                boxInterface.metered = metadata?.capabilities
                    ?.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED) == false
            }
        }
        return InterfaceArray(interfaces)
    }

    override fun underNetworkExtension(): Boolean = false

    override fun includeAllNetworks(): Boolean = false

    override fun readWIFIState(): WIFIState? = null

    override fun clearDNSCache() = Unit

    override fun sendNotification(notification: Notification) {
        TrueTunRuntime.log("Core notification: ${notification.title}: ${notification.body}")
    }

    override fun cancelNotification(identifier: String, typeID: Int) = Unit

    override fun startNeighborMonitor(listener: NeighborUpdateListener?) = Unit

    override fun closeNeighborMonitor(listener: NeighborUpdateListener?) = Unit

    override fun registerMyInterface(name: String?) = Unit

    override fun usePlatformShell(): Boolean = false

    override fun checkPlatformShell() {
        error("android: platform shell is disabled")
    }

    override fun openShellSession(
        user: PlatformUser?,
        command: String?,
        environ: StringIterator?,
        term: String?,
        rows: Int,
        cols: Int,
    ): ShellSession = error("android: platform shell is disabled")

    override fun lookupUser(username: String?): PlatformUser {
        val applicationInfo = runCatching {
            service.packageManager.getApplicationInfo(username ?: service.packageName, 0)
        }.getOrElse { service.applicationInfo }
        return PlatformUser().also {
            it.username = applicationInfo.packageName
            it.uid = applicationInfo.uid
            it.gid = applicationInfo.uid
            it.homeDir = service.filesDir.path
        }
    }

    override fun lookupSFTPServer(): String = error("android: SFTP server is unavailable")

    override fun readSystemSSHHostKey(): String = error("android: system SSH host key is unavailable")

    override fun tailscaleHostname(): String = "${Build.MANUFACTURER} ${Build.MODEL}"

    override fun usePlatformBridge(): Boolean = false

    override fun createBridge(options: BridgeOptions?): BridgeSession =
        error("android: platform bridge is disabled")

    fun close() {
        defaultNetworkMonitor.close()
    }

    private data class NetworkMetadata(
        val properties: android.net.LinkProperties,
        val capabilities: NetworkCapabilities?,
    )

    private class InterfaceArray(values: List<BoxNetworkInterface>) : NetworkInterfaceIterator {
        private val iterator = values.iterator()
        override fun hasNext(): Boolean = iterator.hasNext()
        override fun next(): BoxNetworkInterface = iterator.next()
    }

    class StringArray(values: Iterable<String>) : StringIterator {
        private val values = values.toList()
        private var index = 0
        override fun len(): Int = values.size
        override fun hasNext(): Boolean = index < values.size
        override fun next(): String = values[index++]
    }

    private class DefaultNetworkMonitor(
        private val connectivity: ConnectivityManager,
    ) {
        private val mainHandler = Handler(Looper.getMainLooper())
        private var listener: InterfaceUpdateListener? = null
        private var callback: ConnectivityManager.NetworkCallback? = null
        private var currentNetwork: Network? = null

        @Synchronized
        fun start(newListener: InterfaceUpdateListener) {
            listener = newListener
            if (callback == null) register()
            update(connectivity.activeNetwork)
        }

        @Synchronized
        fun stop(oldListener: InterfaceUpdateListener) {
            if (listener === oldListener) listener = null
            if (listener == null) close()
        }

        @Synchronized
        fun close() {
            val currentCallback = callback ?: return
            runCatching { connectivity.unregisterNetworkCallback(currentCallback) }
            callback = null
            currentNetwork = null
        }

        private fun register() {
            val request = NetworkRequest.Builder()
                .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                .addCapability(NetworkCapabilities.NET_CAPABILITY_NOT_RESTRICTED)
                .build()
            val networkCallback = object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) {
                    currentNetwork = network
                    update(network)
                }

                override fun onCapabilitiesChanged(
                    network: Network,
                    networkCapabilities: NetworkCapabilities,
                ) {
                    if (currentNetwork == network) update(network)
                }

                override fun onLinkPropertiesChanged(
                    network: Network,
                    linkProperties: android.net.LinkProperties,
                ) {
                    if (currentNetwork == network) update(network)
                }

                override fun onLost(network: Network) {
                    if (currentNetwork != network) return
                    currentNetwork = null
                    listener?.updateDefaultInterface("", -1, false, false)
                }
            }
            callback = networkCallback
            when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ->
                    connectivity.registerBestMatchingNetworkCallback(request, networkCallback, mainHandler)
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.P ->
                    connectivity.requestNetwork(request, networkCallback, mainHandler)
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.O ->
                    connectivity.registerDefaultNetworkCallback(networkCallback, mainHandler)
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.N ->
                    connectivity.registerDefaultNetworkCallback(networkCallback)
                else -> connectivity.requestNetwork(request, networkCallback)
            }
        }

        private fun update(network: Network?) {
            val target = listener ?: return
            if (network == null) {
                target.updateDefaultInterface("", -1, false, false)
                return
            }
            val properties = connectivity.getLinkProperties(network) ?: return
            val interfaceName = properties.interfaceName ?: return
            val interfaceIndex = runCatching {
                JavaNetworkInterface.getByName(interfaceName)?.index ?: -1
            }.getOrDefault(-1)
            if (interfaceIndex < 0) return
            val capabilities = connectivity.getNetworkCapabilities(network)
            val expensive = capabilities
                ?.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED) == false
            target.updateDefaultInterface(interfaceName, interfaceIndex, expensive, false)
        }
    }

    companion object {
        private const val TAG = "TrueTunPlatform"
    }
}
