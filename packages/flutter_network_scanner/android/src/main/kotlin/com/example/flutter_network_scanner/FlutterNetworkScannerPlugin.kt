package com.example.flutter_network_scanner

import android.content.Context
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.wifi.WifiManager
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.BufferedReader
import java.io.FileReader
import java.io.InputStreamReader
import java.net.*
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.regex.Pattern
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

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_network_scanner")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "scanNetwork" -> {
                val timeout = (call.argument<Int>("timeoutMs") ?: 250)
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
                val timeout = call.argument<Int>("timeoutMs") ?: 500
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
                val ports = call.argument<List<Int>>("ports") ?: listOf(80, 443, 22, 21, 8080, 445, 53, 3389)
                val timeout = call.argument<Int>("timeoutMs") ?: 300
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

    private fun getLocalNetworkInfo(): Map<String, Any?> {
        var localIp = "127.0.0.1"
        var subnet = "255.255.255.0"
        var gateway: String? = null
        var ifaceName = "wlan0"

        try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val iface = interfaces.nextElement()
                if (iface.isLoopback || !iface.isUp) continue

                for (addr in iface.interfaceAddresses) {
                    val inetAddr = addr.address
                    if (inetAddr is Inet4Address && !inetAddr.isLoopbackAddress) {
                        localIp = inetAddr.hostAddress ?: localIp
                        ifaceName = iface.name
                        val prefixLength = addr.networkPrefixLength.toInt()
                        subnet = prefixLengthToSubnet(prefixLength)
                        break
                    }
                }
                if (localIp != "127.0.0.1") break
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        try {
            val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
            val activeNetwork = cm?.activeNetwork
            val linkProps: LinkProperties? = cm?.getLinkProperties(activeNetwork)
            if (linkProps != null) {
                for (route in linkProps.routes) {
                    if (route.isDefaultRoute && route.gateway is Inet4Address) {
                        gateway = route.gateway?.hostAddress
                        break
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        if (gateway == null && localIp != "127.0.0.1") {
            val parts = localIp.split(".")
            if (parts.size == 4) {
                gateway = "${parts[0]}.${parts[1]}.${parts[2]}.1"
            }
        }

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
            "ip" to localIp,
            "subnet" to subnet,
            "gateway" to gateway,
            "interface" to ifaceName,
            "ssid" to ssid
        )
    }

    private fun prefixLengthToSubnet(prefix: Int): String {
        val mask = (0xffffffffL shl (32 - prefix)) and 0xffffffffL
        return "${(mask shr 24) and 0xff}.${(mask shr 16) and 0xff}.${(mask shr 8) and 0xff}.${mask and 0xff}"
    }

    private fun scanSubnet(timeoutMs: Int): List<Map<String, Any?>> {
        val netInfo = getLocalNetworkInfo()
        val localIp = netInfo["ip"] as? String ?: "192.168.1.1"
        val gatewayIp = netInfo["gateway"] as? String

        val parts = localIp.split(".")
        if (parts.size != 4) return emptyList()

        val subnetPrefix = "${parts[0]}.${parts[1]}.${parts[2]}"
        val commonPorts = listOf(80, 443, 22, 445, 8080, 53, 8008, 62078, 9100, 3000, 5000, 8443)

        val ssdpMetaMap = ConcurrentHashMap<String, DiscoveredMeta>()
        val ssdpThread = Thread {
            discoverSsdpDevices(ssdpMetaMap)
        }
        ssdpThread.start()

        val arpMap = readArpCache()
        val discoveredDevices = ConcurrentHashMap<String, Map<String, Any?>>()
        val executor = Executors.newFixedThreadPool(64)

        for (i in 1..254) {
            val targetIp = "$subnetPrefix.$i"
            executor.execute {
                try {
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

                        if (inetAddress.isReachable(timeoutMs)) {
                            reachable = true
                            pingMs = System.currentTimeMillis() - start
                        }

                        for (port in commonPorts) {
                            val socket = Socket()
                            try {
                                socket.connect(InetSocketAddress(targetIp, port), min(timeoutMs, 180))
                                openPorts.add(port)
                                reachable = true
                                if (pingMs == 0L) {
                                    pingMs = System.currentTimeMillis() - start
                                }
                            } catch (_: Exception) {
                            } finally {
                                try { socket.close() } catch (_: Exception) {}
                            }
                        }

                        if (!reachable && arpMap.containsKey(targetIp)) {
                            val arpMac = arpMap[targetIp]
                            if (arpMac != null && arpMac != "00:00:00:00:00:00") {
                                reachable = true
                                pingMs = 5L
                            }
                        }
                    }

                    if (reachable) {
                        var hostName: String? = null
                        var vendorName: String? = null

                        try {
                            val host = InetAddress.getByName(targetIp).canonicalHostName
                            if (!host.equals(targetIp, ignoreCase = true)) {
                                hostName = host
                            }
                        } catch (_: Exception) {}

                        if (hostName == null && (openPorts.contains(445) || openPorts.contains(139))) {
                            hostName = queryNetBiosName(targetIp)
                        }

                        if (openPorts.contains(80) || openPorts.contains(8080) || openPorts.contains(8008)) {
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

                        val mac = arpMap[targetIp]
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
        executor.awaitTermination(20, TimeUnit.SECONDS)

        try {
            ssdpThread.join(1000)
        } catch (_: Exception) {}

        for ((ssdpIp, meta) in ssdpMetaMap) {
            val existing = discoveredDevices[ssdpIp]
            if (existing != null) {
                val updated = HashMap(existing)
                if (meta.friendlyName != null && (updated["hostname"] == null || updated["hostname"] == ssdpIp)) {
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
        for (port in ports) {
            executor.submit {
                val socket = Socket()
                try {
                    socket.connect(InetSocketAddress(ip, port), timeoutMs)
                    synchronized(openPorts) {
                        openPorts.add(port)
                    }
                } catch (_: Exception) {
                } finally {
                    try { socket.close() } catch (_: Exception) {}
                }
            }
        }
        executor.shutdown()
        executor.awaitTermination(5, TimeUnit.SECONDS)
        return openPorts.sorted()
    }

    private fun readArpCache(): Map<String, String> {
        val map = HashMap<String, String>()
        try {
            val br = BufferedReader(FileReader("/proc/net/arp"))
            var line: String?
            while (br.readLine().also { line = it } != null) {
                val tokens = line?.split("\\s+".toRegex()) ?: continue
                if (tokens.size >= 4 && tokens[0] != "IP") {
                    val ip = tokens[0]
                    val mac = tokens[3]
                    if (mac != "00:00:00:00:00:00") {
                        map[ip] = mac.uppercase()
                    }
                }
            }
            br.close()
        } catch (_: Exception) {
        }
        return map
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

    private fun discoverSsdpDevices(metaMap: ConcurrentHashMap<String, DiscoveredMeta>) {
        try {
            val socket = DatagramSocket()
            socket.soTimeout = 800

            val ssdpQuery = "M-SEARCH * HTTP/1.1\r\n" +
                    "HOST: 239.255.255.250:1900\r\n" +
                    "MAN: \"ssdp:discover\"\r\n" +
                    "MX: 1\r\n" +
                    "ST: ssdp:all\r\n\r\n"

            val sendData = ssdpQuery.toByteArray()
            val packet = DatagramPacket(
                sendData,
                sendData.size,
                InetAddress.getByName("239.255.255.250"),
                1900
            )
            socket.send(packet)

            val buffer = ByteArray(2048)
            val endTime = System.currentTimeMillis() + 1000
            while (System.currentTimeMillis() < endTime) {
                try {
                    val recvPacket = DatagramPacket(buffer, buffer.size)
                    socket.receive(recvPacket)
                    val response = String(recvPacket.data, 0, recvPacket.length)
                    val senderIp = recvPacket.address.hostAddress ?: continue

                    val locationMatcher = Pattern.compile("LOCATION:\\s*(http://[^\\r\\n]+)", Pattern.CASE_INSENSITIVE).matcher(response)
                    if (locationMatcher.find()) {
                        val locationUrl = locationMatcher.group(1)?.trim() ?: continue
                        parseUpnpXmlDescription(locationUrl, senderIp, metaMap)
                    }
                } catch (_: SocketTimeoutException) {
                    break
                } catch (_: Exception) {}
            }
            socket.close()
        } catch (_: Exception) {}
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
                    rawType.contains("printer") -> "printer"
                    rawType.contains("router") || rawType.contains("gateway") -> "router"
                    else -> "generic"
                }
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
}
