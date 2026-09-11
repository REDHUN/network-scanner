enum HopStatus {
  completed,
  timeout,
  error,
}

class TracerouteHop {
  final int hopNumber;
  final String? ip;
  final String? hostname;
  final List<double?> latenciesMs;
  final double? avgLatencyMs;
  final HopStatus status;
  final bool isDestination;
  final String? errorMessage;

  const TracerouteHop({
    required this.hopNumber,
    this.ip,
    this.hostname,
    required this.latenciesMs,
    this.avgLatencyMs,
    required this.status,
    this.isDestination = false,
    this.errorMessage,
  });

  bool get isTimeout => status == HopStatus.timeout || ip == null || ip == '*';
  bool get isSuccess => status == HopStatus.completed && ip != null && ip != '*';

  /// Formatted probe latencies (e.g., "24 ms  25 ms  24 ms" or "*  *  *")
  String get formattedProbes {
    if (latenciesMs.isEmpty) {
      return isTimeout ? '*   *   *' : '-';
    }
    return latenciesMs.map((l) => l != null ? '${l.toStringAsFixed(0)} ms' : '*').join('   ');
  }
}
