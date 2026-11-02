package com.example.flutter_network_scanner

import org.junit.Assert.assertEquals
import org.junit.Test

class NeighborDiscoveryTest {
    @Test
    fun excludesOldNeighborsEvenWhenTheirMacHasNotChanged() {
        val before = mapOf("192.168.1.111" to "AA:BB:CC:DD:EE:FF")
        val after = before + ("192.168.1.3" to "90:11:95:AD:BF:CC")

        assertEquals(
            mapOf("192.168.1.3" to "90:11:95:AD:BF:CC"),
            newlyObservedNeighbors(before, after)
        )
    }

    @Test
    fun ignoresPreviouslyKnownEntriesThatBecameStale() {
        val neighbor = mapOf("192.168.1.3" to "90:11:95:AD:BF:CC")

        assertEquals(emptyMap<String, String>(), newlyObservedNeighbors(neighbor, neighbor))
    }
}
