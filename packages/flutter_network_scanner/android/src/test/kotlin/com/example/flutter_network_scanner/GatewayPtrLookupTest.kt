package com.example.flutter_network_scanner

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class GatewayPtrLookupTest {
    @Test
    fun readsRouterPtrForDiscoveredDevice() {
        val id = 0x2244
        val query = GatewayPtrLookup.buildQuery("192.168.1.7", id)!!
        val answerName = byteArrayOf(8) + "OPPO-A3x".toByteArray() +
            byteArrayOf(6) + "domain".toByteArray() + byteArrayOf(4) + "name".toByteArray() + byteArrayOf(0)
        val response = query.clone()
        response[2] = 0x81.toByte()
        response[3] = 0x80.toByte()
        response[7] = 1
        val answer = byteArrayOf(
            0xc0.toByte(), 12, 0, 12, 0, 1, 0, 0, 0, 30,
            0, answerName.size.toByte()
        ) + answerName

        assertEquals("OPPO-A3x.domain.name", GatewayPtrLookup.parseResponse(response + answer, id, "192.168.1.7"))
        assertNull(GatewayPtrLookup.parseResponse(response + answer, id + 1, "192.168.1.7"))
        assertNull(GatewayPtrLookup.parseResponse(response + answer, id, "192.168.1.8"))
    }

    @Test
    fun refusesInvalidAddressesAndCyclicCompressedNames() {
        assertNull(GatewayPtrLookup.buildQuery("192.168.1.999", 1))
        val query = GatewayPtrLookup.buildQuery("192.168.1.7", 1)!!
        query[2] = 0x81.toByte()
        query[3] = 0x80.toByte()
        query[7] = 1
        val offset = query.size
        val loop = byteArrayOf(
            0xc0.toByte(), 12, 0, 12, 0, 1, 0, 0, 0, 30,
            0, 2, 0xc0.toByte(), offset.plus(12).toByte()
        )
        assertNull(GatewayPtrLookup.parseResponse(query + loop, 1, "192.168.1.7"))
    }
}
