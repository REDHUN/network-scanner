package com.example.flutter_network_scanner

/** A cached entry alone is not evidence that a peer answered during this scan. */
internal fun newlyObservedNeighbors(
    before: Map<String, String>,
    after: Map<String, String>
): Map<String, String> = after.filterKeys { !before.containsKey(it) }
