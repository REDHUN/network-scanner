enum PingMode {
  icmp,
  tcp,
}

enum PingPacketStatus {
  success,
  timeout,
  error,
}

class PingPacket {
  final int sequence;
  final String host;
  final String? ip;
  final double? timeMs;
  final int? ttl;
  final PingPacketStatus status;
  final String? errorMessage;
  final DateTime timestamp;

  const PingPacket({
    required this.sequence,
    required this.host,
    this.ip,
    this.timeMs,
    this.ttl,
    required this.status,
    this.errorMessage,
    required this.timestamp,
  });

  bool get isSuccess => status == PingPacketStatus.success;
}

class PingSummary {
  final String host;
  final String? ip;
  final int totalSent;
  final int totalReceived;
  final int totalLost;
  final double packetLossPercentage;
  final double minTimeMs;
  final double maxTimeMs;
  final double avgTimeMs;
  final double jitterMs;

  const PingSummary({
    required this.host,
    this.ip,
    required this.totalSent,
    required this.totalReceived,
    required this.totalLost,
    required this.packetLossPercentage,
    required this.minTimeMs,
    required this.maxTimeMs,
    required this.avgTimeMs,
    required this.jitterMs,
  });

  factory PingSummary.fromPackets({
    required String host,
    String? ip,
    required List<PingPacket> packets,
  }) {
    if (packets.isEmpty) {
      return PingSummary(
        host: host,
        ip: ip,
        totalSent: 0,
        totalReceived: 0,
        totalLost: 0,
        packetLossPercentage: 0.0,
        minTimeMs: 0.0,
        maxTimeMs: 0.0,
        avgTimeMs: 0.0,
        jitterMs: 0.0,
      );
    }

    final sent = packets.length;
    final successfulPackets = packets.where((p) => p.isSuccess && p.timeMs != null).toList();
    final received = successfulPackets.length;
    final lost = sent - received;
    final lossPercent = (lost / sent) * 100;

    if (successfulPackets.isEmpty) {
      return PingSummary(
        host: host,
        ip: ip,
        totalSent: sent,
        totalReceived: 0,
        totalLost: lost,
        packetLossPercentage: 100.0,
        minTimeMs: 0.0,
        maxTimeMs: 0.0,
        avgTimeMs: 0.0,
        jitterMs: 0.0,
      );
    }

    final times = successfulPackets.map((p) => p.timeMs!).toList();
    double min = times.first;
    double max = times.first;
    double sum = 0;

    for (final t in times) {
      if (t < min) min = t;
      if (t > max) max = t;
      sum += t;
    }
    final avg = sum / times.length;

    // Calculate Jitter (Mean Absolute Difference between consecutive packet times)
    double jitter = 0.0;
    if (times.length > 1) {
      double diffSum = 0;
      for (int i = 1; i < times.length; i++) {
        diffSum += (times[i] - times[i - 1]).abs();
      }
      jitter = diffSum / (times.length - 1);
    }

    return PingSummary(
      host: host,
      ip: ip,
      totalSent: sent,
      totalReceived: received,
      totalLost: lost,
      packetLossPercentage: lossPercent,
      minTimeMs: min,
      maxTimeMs: max,
      avgTimeMs: avg,
      jitterMs: jitter,
    );
  }
}
