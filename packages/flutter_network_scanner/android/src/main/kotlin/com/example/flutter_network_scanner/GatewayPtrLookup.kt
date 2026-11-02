package com.example.flutter_network_scanner

import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.Inet4Address
import java.net.InetSocketAddress
import java.util.concurrent.ThreadLocalRandom

/** Looks up names held by the Wi-Fi router without using system/public DNS. */
internal object GatewayPtrLookup {
    fun query(gateway: Inet4Address, localAddress: Inet4Address, ip: String): String? {
        val id = ThreadLocalRandom.current().nextInt(0x10000)
        val request = buildQuery(ip, id) ?: return null
        return try {
            DatagramSocket(null).use { socket ->
                socket.bind(InetSocketAddress(localAddress, 0))
                socket.soTimeout = 350
                socket.send(DatagramPacket(request, request.size, gateway, 53))
                val buffer = ByteArray(1500)
                val response = DatagramPacket(buffer, buffer.size)
                socket.receive(response)
                if (response.address != gateway || response.port != 53) return null
                parseResponse(buffer.copyOf(response.length), id, ip)
            }
        } catch (_: Exception) {
            null
        }
    }

    internal fun buildQuery(ip: String, id: Int): ByteArray? {
        val octets = ip.split('.').map { it.toIntOrNull() }
        if (octets.size != 4 || octets.any { it == null || it !in 0..255 }) return null
        val name = octets.asReversed().joinToString(".") + ".in-addr.arpa"
        val bytes = ArrayList<Byte>()
        fun word(value: Int) {
            bytes.add((value ushr 8).toByte())
            bytes.add(value.toByte())
        }
        word(id)
        word(0x0100) // recursion desired
        word(1) // one question
        repeat(3) { word(0) }
        for (label in name.split('.')) {
            bytes.add(label.length.toByte())
            bytes.addAll(label.toByteArray(Charsets.US_ASCII).toList())
        }
        bytes.add(0)
        word(12) // PTR
        word(1) // IN
        return bytes.toByteArray()
    }

    internal fun parseResponse(data: ByteArray, id: Int, ip: String): String? {
        if (data.size < 12 || word(data, 0) != id) return null
        val flags = word(data, 2)
        if (flags and 0x8000 == 0 || flags and 0x000f != 0 ||
            flags and 0x0200 != 0 || word(data, 4) != 1) return null
        val expectedQuestion = buildQuery(ip, id) ?: return null
        val questionEnd = expectedQuestion.size
        if (data.size < questionEnd ||
            !data.copyOfRange(12, questionEnd).contentEquals(expectedQuestion.copyOfRange(12, questionEnd))) {
            return null
        }
        var offset = questionEnd
        repeat(minOf(word(data, 6), 64)) {
            val name = readName(data, offset) ?: return null
            offset = name.second
            if (offset + 10 > data.size) return null
            val type = word(data, offset)
            val klass = word(data, offset + 2)
            val length = word(data, offset + 8)
            offset += 10
            if (offset + length > data.size) return null
            if (type == 12 && klass == 1) {
                val decoded = readName(data, offset) ?: return null
                if (decoded.second > offset + length) return null
                val host = decoded.first.trimEnd('.')
                if (host.isNotBlank() && host.length <= 253 &&
                    host.all { it.isLetterOrDigit() || it == '-' || it == '.' || it == '_' } &&
                    host != ip) return host
            }
            offset += length
        }
        return null
    }

    private fun word(data: ByteArray, offset: Int): Int =
        ((data[offset].toInt() and 0xff) shl 8) or (data[offset + 1].toInt() and 0xff)

    private fun readName(data: ByteArray, start: Int): Pair<String, Int>? {
        val labels = ArrayList<String>()
        var offset = start
        var end = -1
        val visited = HashSet<Int>()
        while (true) {
            if (offset !in data.indices || !visited.add(offset)) return null
            val length = data[offset].toInt() and 0xff
            if (length == 0) return labels.joinToString(".") to (if (end < 0) offset + 1 else end)
            if (length and 0xc0 == 0xc0) {
                if (offset + 1 >= data.size) return null
                val target = ((length and 0x3f) shl 8) or (data[offset + 1].toInt() and 0xff)
                if (end < 0) end = offset + 2
                offset = target
            } else {
                if (length > 63 || offset + 1 + length > data.size || labels.size >= 32) return null
                labels.add(String(data, offset + 1, length, Charsets.US_ASCII))
                offset += length + 1
            }
        }
    }
}
