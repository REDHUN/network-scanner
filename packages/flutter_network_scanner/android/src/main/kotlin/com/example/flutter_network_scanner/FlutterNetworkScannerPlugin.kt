package com.example.flutter_network_scanner

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.LinkProperties
import android.net.LinkAddress
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.net.wifi.WifiManager
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.*
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.CountDownLatch
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import java.util.regex.Pattern
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.min

/** FlutterNetworkScannerPlugin */
class FlutterNetworkScannerPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    data class DiscoveredMeta(
        var friendlyName: String? = null,
        var manufacturer: String? = null,
        var modelName: String? = null,
        var deviceType: String? = null
    )

    private data class LocalNetworkInfo(
        val ip: Inet4Address,
        val prefixLength: Int,
        val subnet: String,
        val gateway: String?,
        val interfaceName: String,
        val ssid: String?
    )

    private class ScanCancelledException(message: String) : IllegalStateException(message)

    companion object {
        private const val DEFAULT_SCAN_TIMEOUT_MS = 250
        private const val DEFAULT_PING_TIMEOUT_MS = 500
        private const val DEFAULT_PORT_TIMEOUT_MS = 300
        private const val MAX_TIMEOUT_MS = 10_000
        private const val MAX_SCAN_HOSTS = 4_096L
        private const val SCAN_MAX_DURATION_MS = 20_000L
        private const val PORT_SCAN_MAX_DURATION_MS = 30_000L
        private val DEFAULT_PORTS = listOf(80, 443, 22, 21, 8080, 445, 53, 3389, 8008, 9100)
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_network_scanner")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "scanNetwork" -> {
                val timeout = try {
                    normalizeTimeout(call.argument<Any?>("timeoutMs"), DEFAULT_SCAN_TIMEOUT_MS)
                } catch (e: IllegalArgumentException) {
                    result.error("INVALID_ARGS", e.message, null)
                    return
                }
                Thread {
                    try {
                        val devices = scanSubnet(timeout)
                        Handler(Looper.getMainLooper()).post {
                            result.success(devices)
                        }
                    } catch (e: Exception) {
                        Handler(Looper.getMainLooper()).post {
                            result.error("SCAN_ERROR", e.localizedMessage, null)
                        }
                    }
                }.start()
            }

            "getNetworkInfo" -> {
                try {
                    val info = getLocalNetworkInfo()
                    result.success(info)
                } catch (e: Exception) {
                    result.error("INFO_ERROR", e.localizedMessage, null)
                }
            }

            "pingHost" -> {
                val ip = call.argument<String>("ip")
                val timeout = try {
                    normalizeTimeout(call.argument<Any?>("timeoutMs"), DEFAULT_PING_TIMEOUT_MS)
                } catch (e: IllegalArgumentException) {
                    result.error("INVALID_ARGS", e.message, null)
                    return
                }
                if (ip == null) {
                    result.error("INVALID_ARGS", "IP cannot be null", null)
                    return
                }
                Thread {
                    try {
                        val pingMs = measurePing(ip, timeout)
                        Handler(Looper.getMainLooper()).post {
                            result.success(pingMs)
                        }
                    } catch (e: Exception) {
                        Handler(Looper.getMainLooper()).post {
                            result.success(-1)
                        }
                    }
                }.start()
            }

            "scanPorts" -> {
                val ip = call.argument<String>("ip")
                val ports = try {
                    normalizePorts(call.argument<Any?>("ports"))
                } catch (e: IllegalArgumentException) {
                    result.error("INVALID_ARGS", e.message, null)
                    return
                }
                val timeout = try {
                    normalizeTimeout(call.argument<Any?>("timeoutMs"), DEFAULT_PORT_TIMEOUT_MS)
                } catch (e: IllegalArgumentException) {
                    result.error("INVALID_ARGS", e.message, null)
                    return
                }
                if (ports.isEmpty()) {
                    result.success(emptyList<Int>())
                    return
                }
                if (ip == null) {
                    result.error("INVALID_ARGS", "IP cannot be null", null)
                    return
                }
                Thread {
                    try {
                        val openPorts = scanHostPorts(ip, ports, timeout)
                        Handler(Looper.getMainLooper()).post {
                            result.success(openPorts)
                        }
                    } catch (e: Exception) {
                        Handler(Looper.getMainLooper()).post {
                            result.error("PORT_SCAN_ERROR", e.localizedMessage, null)
                        }
                    }
                }.start()
            }

            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun getLocalNetworkInfo(): Map<String, Any?>? {
        val info = findLocalNetworkInfo() ?: return null
        var ssid: String? = null
        try {
            val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
            val wifiInfo = wifiManager?.connectionInfo
            if (wifiInfo != null && wifiInfo.ssid != null && wifiInfo.ssid != "<unknown ssid>") {
                ssid = wifiInfo.ssid.replace("\"", "")
            }
        } catch (e: Exception) {
            // Ignored if permissions not granted
        }

        return mapOf(
            "ip" to info.ip.hostAddress,
            "subnet" to info.subnet,
            "gateway" to info.gateway,
            "interface" to info.interfaceName,
            "ssid" to ssid
        )
    }

    /** Uses the active ConnectivityManager network as the sole source of interface selection. */
    private fun findLocalNetworkInfo(): LocalNetworkInfo? {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
            ?: return null
        // The default network can be a VPN or cellular even while Wi-Fi is
        // connected. Prefer the Wi-Fi transport for local discovery.
        val wifiNetwork = cm.allNetworks.firstOrNull { network ->
            cm.getNetworkCapabilities(network)?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true
        } ?: return null
        val linkProperties: LinkProperties = cm.getLinkProperties(wifiNetwork) ?: return null
        val interfaceName = linkProperties.interfaceName ?: return null
        val linkAddress: LinkAddress = linkProperties.linkAddresses.firstOrNull { address ->
            val inetAddress = address.address
            inetAddress is Inet4Address &&
                !inetAddress.isLoopbackAddress &&
                !inetAddress.isLinkLocalAddress &&
                !inetAddress.isAnyLocalAddress
        } ?: return null
        val ip = linkAddress.address as? Inet4Address ?: return null
        val prefixLength = linkAddress.prefixLength
        if (prefixLength !in 0..32) return null

        // Confirm the interface still exists and is usable when the platform exposes it.
        try {
            val networkInterface = NetworkInterface.getByName(interfaceName)
            if (networkInterface != null && (networkInterface.isLoopback || !networkInterface.isUp)) {
                return null
            }
        } catch (_: Exception) {
            return null
        }

        val gateway = linkProperties.routes.firstOrNull { route ->
            route.isDefaultRoute && route.gateway is Inet4Address &&
                !(route.gateway as Inet4Address).isAnyLocalAddress
        }?.gateway?.hostAddress

        return LocalNetworkInfo(
            ip = ip,
            prefixLength = prefixLength,
            subnet = prefixLengthToSubnet(prefixLength),
            gateway = gateway,
            interfaceName = interfaceName,
            ssid = null
        )
    }

    private fun prefixLengthToSubnet(prefix: Int): String {
        val mask = prefixLengthToMask(prefix)
        return "${(mask shr 24) and 0xff}.${(mask shr 16) and 0xff}.${(mask shr 8) and 0xff}.${mask and 0xff}"
    }

    private fun prefixLengthToMask(prefix: Int): Long {
        require(prefix in 0..32)
        return if (prefix == 0) 0L else (0xffffffffL shl (32 - prefix)) and 0xffffffffL
    }

    private fun scanSubnet(timeoutMs: Int): List<Map<String, Any?>> {
        val netInfo = findLocalNetworkInfo() ?: return emptyList()
        val localIp = netInfo.ip.hostAddress ?: return emptyList()
        val gatewayIp = netInfo.gateway
        val localIpLong = ipToLong(localIp)
        val mask = prefixLengthToMask(netInfo.prefixLength)
        val networkAddress = localIpLong and mask
        val broadcastAddress = networkAddress or (mask.inv() and 0xffffffffL)
        val firstHost = if (netInfo.prefixLength >= 31) networkAddress else networkAddress + 1
        val lastHost = if (netInfo.prefixLength >= 31) broadcastAddress else broadcastAddress - 1
        val hostCount = if (lastHost >= firstHost) lastHost - firstHost + 1 else 0
        if (hostCount <= 0) return emptyList()
        if (hostCount > MAX_SCAN_HOSTS) {
            throw ScanCancelledException("Active subnet contains $hostCount hosts; refusing an unsafe scan (maximum $MAX_SCAN_HOSTS)")
        }
        val commonPorts = listOf(
            80, 443, 22, 445, 8080, 53, 8008, 8009, 8443, 62078,
            9100, 3000, 5000, 554, 5555, 7000, 7100, 7236, 49152, 49153
        )

        // Snapshot before sending any probes. Unlike a cached STALE entry,
        // a neighbor that first appears during this scan has supplied a MAC in
        // response to this sweep; keep that evidence even if it ages to STALE
        // before we take the final snapshot.
        val neighborsBefore = readIpNeighborCache(netInfo.interfaceName, includeStale = true)

        val ssdpMetaMap = ConcurrentHashMap<String, DiscoveredMeta>()
        val mdnsMetaMap = ConcurrentHashMap<String, DiscoveredMeta>()
        val ssdpThread = Thread {
            discoverSsdpDevicesWithMulticastLock(
                ssdpMetaMap,
                netInfo.ip,
                netInfo.interfaceName
            )
        }
        val mdnsThread = Thread {
            discoverMdnsServices(mdnsMetaMap, localIpLong, mask)
        }
        ssdpThread.start()
        mdnsThread.start()

        // Snapshot the Wi-Fi neighbor table during the sweep, not only at its
        // end. A quiet host can answer ARP near the beginning but transition to
        // STALE before the TCP sweep finishes. Only REACHABLE entries count.
        val arpMap = ConcurrentHashMap<String, String>()
        val sampling = AtomicBoolean(true)
        val neighborSampler = Executors.newSingleThreadScheduledExecutor()
        neighborSampler.scheduleWithFixedDelay({
            for ((ip, mac) in readNeighborCache(netInfo.interfaceName)) {
                if (!sampling.get()) break
                if (ipToLong(ip) in firstHost..lastHost) arpMap[ip] = mac
            }
        }, 500, 1_000, TimeUnit.MILLISECONDS)
        val discoveredDevices = ConcurrentHashMap<String, Map<String, Any?>>()
        val executor = Executors.newFixedThreadPool(min(hostCount.toInt(), 64))
        val activeSockets = ConcurrentHashMap.newKeySet<Socket>()
        val cancelled = AtomicBoolean(false)

        for (address in firstHost..lastHost) {
            val targetIp = longToIp(address)
            executor.execute {
                try {
                    if (cancelled.get() || Thread.currentThread().isInterrupted) return@execute
                    val isCurrent = targetIp == localIp
                    val isGateway = targetIp == gatewayIp

                    var reachable = isCurrent
                    var pingMs = 0L
                    val openPorts = mutableListOf<Int>()

                    if (isCurrent) {
                        reachable = true
                        pingMs = 1L
                    } else {
                        val start = System.currentTimeMillis()
                        val inetAddress = InetAddress.getByName(targetIp)

                        // A small UDP datagram forces Android to resolve the target's
                        // L2 neighbour even when the target silently drops ICMP/TCP.
                        // The refreshed ARP table is the authoritative signal for
                        // LAN presence in that case.
                        touchHostOnWifi(targetIp, localIp)

                        if (!cancelled.get() && inetAddress.isReachable(timeoutMs)) {
                            reachable = true
                            pingMs = System.currentTimeMillis() - start
                        }

                        for (port in commonPorts) {
                            if (cancelled.get() || Thread.currentThread().isInterrupted) return@execute
                            val socket = Socket()
                            activeSockets.add(socket)
                            try {
                                socket.connect(InetSocketAddress(targetIp, port), min(timeoutMs, 180))
                                openPorts.add(port)
                                reachable = true
                                if (pingMs == 0L) {
                                    pingMs = System.currentTimeMillis() - start
                                }
                            } catch (_: Exception) {
                                // A refused port is not enough to classify a host
                                // during a subnet sweep. Android may report a local
                                // routing/ICMP error as ConnectException, which would
                                // turn every unused address into a fake device.
                            } finally {
                                activeSockets.remove(socket)
                                try { socket.close() } catch (_: Exception) {}
                            }
                        }

                    }

                    if (reachable) {
                        var hostName: String? = null
                        var vendorName: String? = null

                        if (cancelled.get() || Thread.currentThread().isInterrupted) return@execute
                        try {
                            val host = InetAddress.getByName(targetIp).canonicalHostName
                            if (!host.equals(targetIp, ignoreCase = true) && isUsableHostname(host)) {
                                hostName = host
                            }
                        } catch (_: Exception) {}

                        if (hostName == null && (openPorts.contains(445) || openPorts.contains(139))) {
                            hostName = queryNetBiosName(targetIp)
                        }

                        if (!cancelled.get() && (openPorts.contains(80) || openPorts.contains(8080) || openPorts.contains(8008))) {
                            val webInfo = fetchHttpTitleAndServer(targetIp, openPorts)
                            if (webInfo != null) {
                                if (hostName == null && webInfo.first != null) {
                                    hostName = webInfo.first
                                }
                                if (vendorName == null && webInfo.second != null) {
                                    vendorName = webInfo.second
                                }
                            }
                        }

                        if (targetIp.startsWith("10.0.2.")) {
                            when (targetIp) {
                                "10.0.2.2" -> {
                                    hostName = hostName ?: "Host Gateway"
                                    vendorName = vendorName ?: "Android Emulator Host"
                                }
                                "10.0.2.3" -> {
                                    hostName = hostName ?: "Virtual DNS Server"
                                    vendorName = vendorName ?: "QEMU Virtual Network"
                                }
                                "10.0.2.4" -> {
                                    hostName = hostName ?: "Virtual Router / DHCP"
                                    vendorName = vendorName ?: "QEMU Virtual Network"
                                }
                                "10.0.2.15" -> {
                                    hostName = hostName ?: "Android Emulator (This Device)"
                                    vendorName = vendorName ?: "Android Virtual Device"
                                }
                            }
                        }

                        val mac = null
                        val deviceType = inferDeviceType(isGateway, isCurrent, openPorts, hostName)
                        if (vendorName == null) {
                            vendorName = inferVendorFromMacOrPorts(mac, openPorts)
                        }

                        val deviceData = mutableMapOf<String, Any?>(
                            "ip" to targetIp,
                            "hostname" to hostName,
                            "openPorts" to openPorts,
                            "mac" to mac,
                            "vendor" to vendorName,
                            "pingMs" to (if (pingMs <= 0) 1L else pingMs),
                            "deviceType" to deviceType,
                            "isCurrentDevice" to isCurrent,
                            "isGateway" to isGateway
                        )
                        discoveredDevices[targetIp] = deviceData
                    }
                } catch (_: Exception) {
                }
            }
        }

        executor.shutdown()
        try {
            awaitExecutor(executor, SCAN_MAX_DURATION_MS, activeSockets, cancelled, "Network scan timed out")
        } finally {
            sampling.set(false)
            neighborSampler.shutdownNow()
            stopSsdpThread(ssdpThread)
            stopSsdpThread(mdnsThread)
        }

        arpMap.putAll(readNeighborCache(netInfo.interfaceName))
        if (neighborsBefore != null) {
            val neighborsAfter = readIpNeighborCache(netInfo.interfaceName, includeStale = true)
            if (neighborsAfter != null) {
                for ((ip, mac) in newlyObservedNeighbors(neighborsBefore, neighborsAfter)) {
                    if (ipToLong(ip) in firstHost..lastHost) {
                        arpMap.putIfAbsent(ip, mac)
                    }
                }
            }
        }
        for ((arpIp, arpMac) in arpMap) {
            val address = ipToLong(arpIp)
            if (address !in firstHost..lastHost || arpIp == localIp || arpMac == "00:00:00:00:00:00") {
                continue
            }
            val existing = discoveredDevices[arpIp]
            if (existing != null) {
                if (existing["mac"] == null) {
                    val updated = HashMap(existing)
                    updated["mac"] = arpMac
                    if (updated["vendor"] == null) {
                        updated["vendor"] = inferVendorFromMacOrPorts(arpMac, emptyList())
                    }
                    discoveredDevices[arpIp] = updated
                }
                continue
            }
            val vendor = inferVendorFromMacOrPorts(arpMac, emptyList())
            discoveredDevices[arpIp] = mapOf(
                "ip" to arpIp,
                "hostname" to null,
                "openPorts" to emptyList<Int>(),
                "mac" to arpMac,
                "vendor" to vendor,
                "pingMs" to 5L,
                "deviceType" to "generic",
                "isCurrentDevice" to false,
                "isGateway" to (arpIp == gatewayIp)
            )
        }

        val discoveryMeta = HashMap(ssdpMetaMap)
        for ((ip, mdns) in mdnsMetaMap) {
            val previous = discoveryMeta[ip]
            discoveryMeta[ip] = if (previous == null) mdns else DiscoveredMeta(
                previous.friendlyName ?: mdns.friendlyName,
                previous.manufacturer ?: mdns.manufacturer,
                previous.modelName ?: mdns.modelName,
                previous.deviceType ?: mdns.deviceType
            )
        }
        for ((ssdpIp, meta) in discoveryMeta) {
            if (ipToLong(ssdpIp) !in firstHost..lastHost) continue
            val existing = discoveredDevices[ssdpIp]
            if (existing != null) {
                val updated = HashMap(existing)
                if (meta.friendlyName != null &&
                    (!isUsableHostname(updated["hostname"] as? String) ||
                        updated["hostname"] == ssdpIp)) {
                    updated["hostname"] = meta.friendlyName
                }
                if (meta.manufacturer != null && updated["vendor"] == null) {
                    updated["vendor"] = meta.manufacturer
                }
                if (meta.deviceType != null && updated["deviceType"] == "generic") {
                    updated["deviceType"] = meta.deviceType
                }
                discoveredDevices[ssdpIp] = updated
            } else {
                discoveredDevices[ssdpIp] = mapOf(
                    "ip" to ssdpIp,
                    "hostname" to meta.friendlyName,
                    "openPorts" to emptyList<Int>(),
                    "mac" to arpMap[ssdpIp],
                    "vendor" to meta.manufacturer,
                    "pingMs" to 5L,
                    "deviceType" to (meta.deviceType ?: "generic"),
                    "isCurrentDevice" to (ssdpIp == localIp),
                    "isGateway" to (ssdpIp == gatewayIp)
                )
            }
        }

        // The system resolver can use public DNS and miss DHCP names hosted by
        // the Wi-Fi router. Query its PTR records only for confirmed devices;
        // DNS alone must never add an address to the online list.
        if (gatewayIp != null && gatewayIp != localIp) {
            val gateway = try { InetAddress.getByName(gatewayIp) } catch (_: Exception) { null }
            if (gateway is Inet4Address) {
                val dnsExecutor = Executors.newFixedThreadPool(8)
                try {
                    for (ip in discoveredDevices.keys) {
                        if (ip == localIp || isUsableHostname(discoveredDevices[ip]?.get("hostname") as? String)) continue
                        dnsExecutor.execute {
                            val name = GatewayPtrLookup.query(gateway, netInfo.ip, ip)
                            if (name != null) {
                                discoveredDevices.computeIfPresent(ip) { _, existing ->
                                    if (isUsableHostname(existing["hostname"] as? String)) existing
                                    else HashMap(existing).apply { put("hostname", name) }
                                }
                            }
                        }
                    }
                } finally {
                    dnsExecutor.shutdown()
                    try {
                        if (!dnsExecutor.awaitTermination(2, TimeUnit.SECONDS)) dnsExecutor.shutdownNow()
                    } catch (_: InterruptedException) {
                        dnsExecutor.shutdownNow()
                        Thread.currentThread().interrupt()
                    }
                }
            }
        }

        return discoveredDevices.values.sortedWith(Comparator { a, b ->
            val ipA = a["ip"] as? String ?: ""
            val ipB = b["ip"] as? String ?: ""
            ipToLong(ipA).compareTo(ipToLong(ipB))
        })
    }

    private fun measurePing(ip: String, timeoutMs: Int): Long {
        val start = System.currentTimeMillis()
        val inet = InetAddress.getByName(ip)
        if (inet.isReachable(timeoutMs)) {
            return System.currentTimeMillis() - start
        }
        val socket = Socket()
        return try {
            socket.connect(InetSocketAddress(ip, 80), timeoutMs)
            System.currentTimeMillis() - start
        } catch (_: Exception) {
            -1L
        } finally {
            try { socket.close() } catch (_: Exception) {}
        }
    }

    private fun scanHostPorts(ip: String, ports: List<Int>, timeoutMs: Int): List<Int> {
        val openPorts = mutableListOf<Int>()
        val executor = Executors.newFixedThreadPool(min(ports.size, 32))
        val activeSockets = ConcurrentHashMap.newKeySet<Socket>()
        val cancelled = AtomicBoolean(false)
        for (port in ports) {
            executor.submit {
                if (cancelled.get() || Thread.currentThread().isInterrupted) return@submit
                val socket = Socket()
                activeSockets.add(socket)
                try {
                    socket.connect(InetSocketAddress(ip, port), timeoutMs)
                    synchronized(openPorts) {
                        openPorts.add(port)
                    }
                } catch (_: Exception) {
                } finally {
                    activeSockets.remove(socket)
                    try { socket.close() } catch (_: Exception) {}
                }
            }
        }
        executor.shutdown()
        awaitExecutor(executor, PORT_SCAN_MAX_DURATION_MS, activeSockets, cancelled, "Port scan timed out")
        return openPorts.sorted()
    }

    private fun normalizeTimeout(value: Any?, defaultValue: Int): Int {
        if (value == null) return defaultValue
        val number = value as? Number
            ?: throw IllegalArgumentException("timeoutMs must be an integer")
        val timeout = number.toLong()
        if (number.toDouble() != timeout.toDouble()) {
            throw IllegalArgumentException("timeoutMs must be an integer")
        }
        if (timeout !in 1..MAX_TIMEOUT_MS) {
            throw IllegalArgumentException("timeoutMs must be between 1 and $MAX_TIMEOUT_MS milliseconds")
        }
        return timeout.toInt()
    }

    private fun normalizePorts(value: Any?): List<Int> {
        if (value == null) return DEFAULT_PORTS
        val rawPorts = value as? List<*>
            ?: throw IllegalArgumentException("ports must be a list of integers")
        return rawPorts.map { rawPort ->
            val number = rawPort as? Number
                ?: throw IllegalArgumentException("ports must contain only integers")
            val port = number.toLong()
            if (number.toDouble() != port.toDouble()) {
                throw IllegalArgumentException("ports must contain only integers")
            }
            if (port !in 1..65535) {
                throw IllegalArgumentException("ports must be between 1 and 65535")
            }
            port.toInt()
        }.distinct()
    }

    /**
     * Waits for every worker to stop before returning. If the bounded wait expires, all
     * sockets and queued work are cancelled, then termination is awaited uninterruptibly so
     * callers never receive a partial result while native workers remain active.
     */
    private fun awaitExecutor(
        executor: ExecutorService,
        timeoutMs: Long,
        activeSockets: MutableSet<Socket>,
        cancelled: AtomicBoolean,
        timeoutMessage: String
    ) {
        try {
            if (executor.awaitTermination(timeoutMs, TimeUnit.MILLISECONDS)) return
        } catch (_: InterruptedException) {
            cancelled.set(true)
            executor.shutdownNow()
            activeSockets.forEach { socket -> try { socket.close() } catch (_: Exception) {} }
            awaitTerminationUninterruptibly(executor)
            Thread.currentThread().interrupt()
            throw ScanCancelledException("Network scan was cancelled")
        }

        cancelled.set(true)
        executor.shutdownNow()
        activeSockets.forEach { socket -> try { socket.close() } catch (_: Exception) {} }
        awaitTerminationUninterruptibly(executor)
        throw ScanCancelledException(timeoutMessage)
    }

    private fun awaitTerminationUninterruptibly(executor: ExecutorService) {
        var interrupted = false
        while (true) {
            try {
                if (executor.awaitTermination(1, TimeUnit.SECONDS)) break
            } catch (_: InterruptedException) {
                interrupted = true
            }
        }
        if (interrupted) Thread.currentThread().interrupt()
    }

    private fun stopSsdpThread(thread: Thread) {
        var interrupted = false
        try {
            thread.join(9_000)
        } catch (_: InterruptedException) {
            interrupted = true
        }
        if (thread.isAlive) thread.interrupt()
        while (thread.isAlive) {
            try {
                thread.join()
            } catch (_: InterruptedException) {
                interrupted = true
            }
        }
        if (interrupted) Thread.currentThread().interrupt()
    }

    private fun readNeighborCache(interfaceName: String, includeStale: Boolean = false): Map<String, String> {
        // `ip neigh` includes a state. Do not fall back to /proc/net/arp here:
        // that file has no freshness information and can contain devices that left
        // the network days ago, which creates false online devices.
        return readIpNeighborCache(interfaceName, includeStale) ?: emptyMap()
    }

    private fun readIpNeighborCache(interfaceName: String, includeStale: Boolean): Map<String, String>? {
        val map = HashMap<String, String>()
        try {
            val process = ProcessBuilder(
                "/system/bin/ip",
                "neigh",
                "show",
                "dev",
                interfaceName
            ).redirectErrorStream(true).start()
            process.inputStream.bufferedReader().useLines { lines ->
                lines.forEach { line ->
                    val parts = line.trim().split("\\s+".toRegex())
                    if (parts.size < 5) return@forEach
                    val ip = parts.firstOrNull { value ->
                        value.count { it == '.' } == 3 && value.all { it.isDigit() || it == '.' }
                    } ?: return@forEach
                    val macIndex = parts.indexOfFirst { value ->
                        value.count { it == ':' } == 5 && value.length >= 17
                    }
                    val state = parts.lastOrNull()?.uppercase() ?: ""
                    // A STALE entry is only useful when compared with the
                    // pre-scan snapshot; by itself it is not proof of liveness.
                    if (macIndex >= 0 && (state == "REACHABLE" || (includeStale && state == "STALE"))) {
                        val mac = parts[macIndex].uppercase()
                        if (mac != "00:00:00:00:00:00") {
                            map[ip] = mac
                        }
                    }
                }
            }
            if (!process.waitFor(250, TimeUnit.MILLISECONDS) || process.exitValue() != 0) {
                process.destroyForcibly()
                return null
            }
            process.destroy()
        } catch (_: Exception) {
            // Some Android builds do not expose the ip utility to applications.
            return null
        }
        return map
    }

    private fun touchHostOnWifi(targetIp: String, localIp: String) {
        try {
            DatagramSocket().use { socket ->
                socket.bind(InetSocketAddress(localIp, 0))
                val address = InetAddress.getByName(targetIp)
                val ports = intArrayOf(1900, 5353, 5555, 7000, 7236, 8009)
                val payload = byteArrayOf(0)
                for (port in ports) {
                    socket.send(DatagramPacket(payload, payload.size, address, port))
                }
            }
        } catch (_: Exception) {
            // TCP/ICMP probing continues even when UDP neighbour resolution fails.
        }
    }

    private fun discoverMdnsServices(
        metaMap: ConcurrentHashMap<String, DiscoveredMeta>,
        localIp: Long,
        mask: Long
    ) {
        val manager = context.getSystemService(Context.NSD_SERVICE) as? NsdManager ?: return
        val services = ConcurrentLinkedQueue<NsdServiceInfo>()
        val listeners = mutableListOf<NsdManager.DiscoveryListener>()
        val types = listOf(
            "_spotify-connect._tcp.",
            "_amzn-wplay._tcp.", "_amazon-alexa._tcp.",
            "_companion-link._tcp.", "_apple-mobdev2._tcp.",
            "_airplay._tcp.", "_raop._tcp.",
            "_googlecast._tcp.",
            "_http._tcp.", "_https._tcp.", "_homekit._tcp."
        )
        try {
            for (type in types) {
                val listener = object : NsdManager.DiscoveryListener {
                    override fun onDiscoveryStarted(serviceType: String) {}
                    override fun onServiceFound(service: NsdServiceInfo) {
                        services.add(service)
                    }
                    override fun onServiceLost(service: NsdServiceInfo) {
                        services.remove(service)
                    }
                    override fun onDiscoveryStopped(serviceType: String) {}
                    override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {
                        try { manager.stopServiceDiscovery(this) } catch (_: Exception) {}
                    }
                    override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {}
                }
                try {
                    manager.discoverServices(type, NsdManager.PROTOCOL_DNS_SD, listener)
                    listeners.add(listener)
                } catch (_: Exception) {
                    // Some Android versions limit simultaneous DNS-SD discoveries.
                }
            }
            Thread.sleep(2_500)
        } catch (_: InterruptedException) {
            Thread.currentThread().interrupt()
        }

        // A service advertisement is not a host address. Resolve it before
        // reporting it, and only accept IPv4 addresses on the active Wi-Fi LAN.
        try {
        val seen = HashSet<String>()
        var resolvedCount = 0
        val orderedServices = services.toList().sortedBy { info ->
            types.indexOfFirst { info.serviceType.startsWith(it, ignoreCase = true) }
                .let { if (it < 0) types.size else it }
        }
        for (service in orderedServices) {
            if (resolvedCount >= 16 || Thread.currentThread().isInterrupted) break
            if (!seen.add("${service.serviceType}:${service.serviceName}")) continue
            resolvedCount++
            val result = AtomicReference<NsdServiceInfo?>()
            val done = CountDownLatch(1)
            try {
                manager.resolveService(service, object : NsdManager.ResolveListener {
                    override fun onServiceResolved(info: NsdServiceInfo) {
                        result.set(info)
                        done.countDown()
                    }
                    override fun onResolveFailed(info: NsdServiceInfo, errorCode: Int) {
                        done.countDown()
                    }
                })
                if (!done.await(650, TimeUnit.MILLISECONDS)) continue
            } catch (_: Exception) {
                continue
            }
            val resolved = result.get() ?: continue
            val address = resolved.host as? Inet4Address ?: continue
            val ip = address.hostAddress ?: continue
            if ((ipToLong(ip) and mask) != (localIp and mask) || ipToLong(ip) == localIp) continue
            val name = resolved.serviceName.takeIf { it.isNotBlank() }
            val isPhone = name?.contains("iphone", ignoreCase = true) == true ||
                name?.contains("ipad", ignoreCase = true) == true
            val isAmazon = resolved.serviceType.contains("amzn", ignoreCase = true) ||
                resolved.serviceType.contains("alexa", ignoreCase = true) ||
                name?.contains("echo", ignoreCase = true) == true ||
                name?.contains("alexa", ignoreCase = true) == true
            val isApple = isPhone || resolved.serviceType.contains("airplay", ignoreCase = true) ||
                resolved.serviceType.contains("raop", ignoreCase = true) ||
                resolved.serviceType.contains("apple", ignoreCase = true) ||
                resolved.serviceType.contains("companion-link", ignoreCase = true)
            metaMap.compute(ip) { _, previous ->
                DiscoveredMeta(
                    friendlyName = previous?.friendlyName ?: name,
                    manufacturer = previous?.manufacturer ?: when {
                        isAmazon -> "Amazon"
                        isApple -> "Apple"
                        else -> null
                    },
                    deviceType = when {
                        previous?.deviceType != null && previous.deviceType != "generic" -> previous.deviceType
                        isAmazon -> "smart_speaker"
                        isPhone -> "mobile"
                        else -> previous?.deviceType ?: "generic"
                    }
                )
            }
        }
        } finally {
            for (listener in listeners) {
                try { manager.stopServiceDiscovery(listener) } catch (_: Exception) {}
            }
        }
    }

    private fun isUsableHostname(hostname: String?): Boolean {
        val value = hostname?.trim() ?: return false
        if (value.isEmpty() || value.contains(':') || value.contains('@') || value.contains('%')) {
            return false
        }
        if (value.matches(Regex("(?i)^[0-9a-f]{2}([-:][0-9a-f]{2}){5}$"))) {
            return false
        }
        return true
    }

    private fun queryNetBiosName(ip: String): String? {
        try {
            val socket = DatagramSocket()
            socket.soTimeout = 250
            val query = byteArrayOf(
                0x82.toByte(), 0x28, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00, 0x20, 0x43, 0x4b, 0x41,
                0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41,
                0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41,
                0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41,
                0x41, 0x41, 0x41, 0x41, 0x41, 0x00, 0x00, 0x21,
                0x00, 0x01
            )
            val packet = DatagramPacket(query, query.size, InetAddress.getByName(ip), 137)
            socket.send(packet)

            val buffer = ByteArray(1024)
            val responsePacket = DatagramPacket(buffer, buffer.size)
            socket.receive(responsePacket)
            socket.close()

            if (responsePacket.length > 57) {
                val nameBytes = buffer.copyOfRange(57, min(72, responsePacket.length))
                val rawName = String(nameBytes).trim()
                if (rawName.isNotBlank() && !rawName.startsWith("\u0000")) {
                    return rawName.filter { it in 'a'..'z' || it in 'A'..'Z' || it in '0'..'9' || it == '-' || it == '_' }
                }
            }
        } catch (_: Exception) {}
        return null
    }

    private fun fetchHttpTitleAndServer(ip: String, openPorts: List<Int>): Pair<String?, String?>? {
        val port = when {
            openPorts.contains(80) -> 80
            openPorts.contains(8080) -> 8080
            openPorts.contains(8008) -> 8008
            else -> return null
        }

        try {
            val url = URL("http://$ip:$port/")
            val conn = (url.openConnection() as HttpURLConnection).apply {
                connectTimeout = 300
                readTimeout = 400
                requestMethod = "GET"
                instanceFollowRedirects = true
            }

            val server = conn.getHeaderField("Server")
            val reader = BufferedReader(InputStreamReader(conn.inputStream))
            val sb = StringBuilder()
            var lines = 0
            var line: String?
            while (reader.readLine().also { line = it } != null && lines++ < 30) {
                sb.append(line).append("\n")
            }
            reader.close()
            conn.disconnect()

            val html = sb.toString()
            val matcher = Pattern.compile("<title>(.*?)</title>", Pattern.CASE_INSENSITIVE).matcher(html)
            var title: String? = null
            if (matcher.find()) {
                title = matcher.group(1)?.trim()
            }
            return Pair(title, server)
        } catch (_: Exception) {}
        return null
    }

    private fun discoverSsdpDevicesWithMulticastLock(
        metaMap: ConcurrentHashMap<String, DiscoveredMeta>,
        localAddress: Inet4Address,
        interfaceName: String
    ) {
        val wifiManager = context.applicationContext
            .getSystemService(Context.WIFI_SERVICE) as? WifiManager
        val multicastLock = try {
            wifiManager?.createMulticastLock("flutter_network_scanner_ssdp")?.apply {
                setReferenceCounted(false)
                acquire()
            }
        } catch (_: Exception) {
            null
        }
        try {
            discoverSsdpDevices(metaMap, localAddress, interfaceName)
        } finally {
            try {
                if (multicastLock?.isHeld == true) multicastLock.release()
            } catch (_: Exception) {
                // The lock may already have been released by the platform during teardown.
            }
        }
    }

    private fun discoverSsdpDevices(
        metaMap: ConcurrentHashMap<String, DiscoveredMeta>,
        localAddress: Inet4Address,
        interfaceName: String
    ) {
        var socket: DatagramSocket? = null
        try {
            val networkInterface = NetworkInterface.getByName(interfaceName)
            if (networkInterface != null && !networkInterface.isUp) return

            // Bind to the active Wi-Fi address. A plain DatagramSocket may choose a
            // VPN/cellular route on phones with multiple active networks, which makes
            // multicast discovery of Echo/Fire TV devices silently fail.
            socket = DatagramSocket(null).apply {
                reuseAddress = true
                bind(InetSocketAddress(localAddress, 0))
                soTimeout = 450
            }

            val searchTargets = listOf(
                "ssdp:all",
                "upnp:rootdevice",
                "urn:schemas-upnp-org:device:MediaRenderer:1",
                "urn:schemas-upnp-org:device:MediaServer:1",
                "urn:dial-multiscreen-org:service:dial:1"
            )
            val multicastAddress = InetAddress.getByName("239.255.255.250")
            val endTime = System.currentTimeMillis() + 3_000
            val descriptions = LinkedHashMap<String, String>()

            // Send more than one round because sleeping media devices often do not
            // answer the first multicast request after Wi-Fi becomes active.
            repeat(2) { round ->
                if (System.currentTimeMillis() >= endTime) return@repeat
                for (searchTarget in searchTargets) {
                    val ssdpQuery = "M-SEARCH * HTTP/1.1\r\n" +
                        "HOST: 239.255.255.250:1900\r\n" +
                        "MAN: \"ssdp:discover\"\r\n" +
                        "MX: 1\r\n" +
                        "ST: $searchTarget\r\n\r\n"
                    val sendData = ssdpQuery.toByteArray()
                    socket.send(
                        DatagramPacket(sendData, sendData.size, multicastAddress, 1900)
                    )
                }

                val buffer = ByteArray(4096)
                val receiveUntil = minOf(endTime, System.currentTimeMillis() + 1_200L)
                while (System.currentTimeMillis() < receiveUntil) {
                    try {
                        val recvPacket = DatagramPacket(buffer, buffer.size)
                        socket.receive(recvPacket)
                        val response = String(recvPacket.data, 0, recvPacket.length)
                        val senderIp = recvPacket.address.hostAddress ?: continue
                        if (!response.startsWith("HTTP/1.1 200", ignoreCase = true) &&
                            !response.startsWith("HTTP/1.0 200", ignoreCase = true)) continue
                        if (!response.contains("ST:", ignoreCase = true) &&
                            !response.contains("USN:", ignoreCase = true)) continue

                        // The response itself proves that this host is present; XML
                        // fetching must not block the short UDP receive window.
                        val meta = metaMap[senderIp] ?: DiscoveredMeta()
                        val lowerResponse = response.lowercase()
                        when {
                            lowerResponse.contains("fire tv") || lowerResponse.contains("firetv") -> {
                                meta.manufacturer = "Amazon"
                                meta.deviceType = "smart_tv"
                            }
                            lowerResponse.contains("amazon") || lowerResponse.contains("alexa") ||
                                lowerResponse.contains("echo") -> {
                                meta.manufacturer = "Amazon"
                                meta.deviceType = "smart_speaker"
                            }
                            lowerResponse.contains("dial") || lowerResponse.contains("mediarenderer") ->
                                meta.deviceType = "smart_tv"
                        }
                        metaMap[senderIp] = meta

                        val locationMatcher = Pattern.compile(
                            "(?:LOCATION|AL)\\s*:\\s*(https?://[^\\r\\n]+)",
                            Pattern.CASE_INSENSITIVE
                        ).matcher(response)
                        if (locationMatcher.find()) {
                            val locationUrl = locationMatcher.group(1)?.trim() ?: continue
                            // Ignore descriptions hosted elsewhere: they are not
                            // evidence that the advertised sender owns that URL.
                            val url = URL(locationUrl)
                            if (url.host == senderIp) descriptions.putIfAbsent(senderIp, locationUrl)
                        }
                    } catch (_: SocketTimeoutException) {
                        // Responses may arrive later within the MX window.
                    } catch (_: Exception) {
                    }
                }
                if (round == 0) Thread.sleep(150)
            }
            for ((ip, url) in descriptions.entries.take(6)) {
                if (Thread.currentThread().isInterrupted) break
                parseUpnpXmlDescription(url, ip, metaMap)
            }
            if (socket.isClosed.not()) {
                socket.close()
            }
        } catch (_: Exception) {
        } finally {
            try {
                socket?.close()
            } catch (_: Exception) {
            }
        }
    }

    private fun parseUpnpXmlDescription(locationUrl: String, ip: String, metaMap: ConcurrentHashMap<String, DiscoveredMeta>) {
        try {
            val url = URL(locationUrl)
            val conn = (url.openConnection() as HttpURLConnection).apply {
                connectTimeout = 400
                readTimeout = 400
            }
            val reader = BufferedReader(InputStreamReader(conn.inputStream))
            val sb = StringBuilder()
            var line: String?
            while (reader.readLine().also { line = it } != null) {
                sb.append(line).append("\n")
            }
            reader.close()
            conn.disconnect()

            val xml = sb.toString()
            val friendlyNameMatcher = Pattern.compile("<friendlyName>(.*?)</friendlyName>", Pattern.CASE_INSENSITIVE).matcher(xml)
            val manufacturerMatcher = Pattern.compile("<manufacturer>(.*?)</manufacturer>", Pattern.CASE_INSENSITIVE).matcher(xml)
            val modelNameMatcher = Pattern.compile("<modelName>(.*?)</modelName>", Pattern.CASE_INSENSITIVE).matcher(xml)
            val deviceTypeMatcher = Pattern.compile("<deviceType>(.*?)</deviceType>", Pattern.CASE_INSENSITIVE).matcher(xml)

            val meta = metaMap[ip] ?: DiscoveredMeta()
            if (friendlyNameMatcher.find()) meta.friendlyName = friendlyNameMatcher.group(1)?.trim()
            if (manufacturerMatcher.find()) meta.manufacturer = manufacturerMatcher.group(1)?.trim()
            if (modelNameMatcher.find()) meta.modelName = modelNameMatcher.group(1)?.trim()

            if (deviceTypeMatcher.find()) {
                val rawType = deviceTypeMatcher.group(1)?.lowercase() ?: ""
                meta.deviceType = when {
                    rawType.contains("mediaserver") || rawType.contains("tv") -> "smart_tv"
                    rawType.contains("mediarenderer") || rawType.contains("speaker") -> "smart_speaker"
                    rawType.contains("printer") -> "printer"
                    rawType.contains("router") || rawType.contains("gateway") -> "router"
                    else -> "generic"
                }
            }
            val lowerXml = xml.lowercase()
            if (lowerXml.contains("fire tv") || lowerXml.contains("firetv")) {
                meta.manufacturer = meta.manufacturer ?: "Amazon"
                meta.deviceType = "smart_tv"
            } else if (lowerXml.contains("amazon") || lowerXml.contains("alexa") || lowerXml.contains("echo")) {
                meta.manufacturer = meta.manufacturer ?: "Amazon"
                meta.deviceType = "smart_speaker"
            }
            metaMap[ip] = meta
        } catch (_: Exception) {}
    }

    private fun inferDeviceType(
        isGateway: Boolean,
        isCurrent: Boolean,
        openPorts: List<Int>,
        hostName: String?
    ): String {
        if (isGateway) return "router"
        if (isCurrent) return "mobile"

        val lowerHost = hostName?.lowercase() ?: ""
        if (lowerHost.contains("router") || lowerHost.contains("gateway") || lowerHost.contains("modem") || lowerHost.contains("ap")) {
            return "router"
        }
        if (lowerHost.contains("printer") || openPorts.contains(9100) || openPorts.contains(515) || openPorts.contains(631)) {
            return "printer"
        }
        if (lowerHost.contains("tv") || lowerHost.contains("chromecast") || openPorts.contains(8008) || openPorts.contains(8009)) {
            return "smart_tv"
        }
        if (lowerHost.contains("iphone") || lowerHost.contains("ipad") || lowerHost.contains("android") || openPorts.contains(62078)) {
            return "mobile"
        }
        if (openPorts.contains(445) || openPorts.contains(139) || openPorts.contains(3389)) {
            return "pc"
        }
        if (openPorts.contains(22) || openPorts.contains(80) || openPorts.contains(443) || openPorts.contains(8080)) {
            return "server"
        }
        return "generic"
    }

    private fun inferVendorFromMacOrPorts(mac: String?, openPorts: List<Int>): String? {
        val normalizedMac = mac?.uppercase()?.replace("-", ":")
        if (normalizedMac != null) {
            when {
                normalizedMac.startsWith("90:11:95") -> return "Amazon"
                normalizedMac.startsWith("A0:02:DC") -> return "Amazon"
                normalizedMac.startsWith("FC:65:DE") -> return "Amazon"
                normalizedMac.startsWith("44:65:0D") -> return "Amazon"
            }
        }
        if (openPorts.contains(8008) || openPorts.contains(8009)) return "Google Inc."
        if (openPorts.contains(62078)) return "Apple Inc."
        if (openPorts.contains(9100)) return "Network Printer"
        if (openPorts.contains(3389) || openPorts.contains(445)) return "Microsoft / Windows"
        if (openPorts.contains(53)) return "DNS / Gateway"
        return null
    }

    private fun ipToLong(ip: String): Long {
        val parts = ip.split(".")
        if (parts.size != 4) return 0L
        return try {
            (parts[0].toLong() shl 24) or
            (parts[1].toLong() shl 16) or
            (parts[2].toLong() shl 8) or
            parts[3].toLong()
        } catch (_: Exception) {
            0L
        }
    }

    private fun longToIp(value: Long): String {
        return "${(value shr 24) and 0xff}.${(value shr 16) and 0xff}.${(value shr 8) and 0xff}.${value and 0xff}"
    }
}
