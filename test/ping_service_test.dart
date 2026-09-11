import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tools/models/utilities_model/ping_result.dart';
import 'package:ip_tools/service/ping_service/ping_service.dart';

void main() {
  group('PingSummary Calculations', () {
    test('Calculates Min, Max, Avg, Jitter, and Loss correctly', () {
      final now = DateTime.now();
      final packets = [
        PingPacket(
          sequence: 1,
          host: '1.1.1.1',
          ip: '1.1.1.1',
          timeMs: 10.0,
          ttl: 64,
          status: PingPacketStatus.success,
          timestamp: now,
        ),
        PingPacket(
          sequence: 2,
          host: '1.1.1.1',
          ip: '1.1.1.1',
          timeMs: 20.0,
          ttl: 64,
          status: PingPacketStatus.success,
          timestamp: now,
        ),
        PingPacket(
          sequence: 3,
          host: '1.1.1.1',
          ip: '1.1.1.1',
          timeMs: 30.0,
          ttl: 64,
          status: PingPacketStatus.success,
          timestamp: now,
        ),
        PingPacket(
          sequence: 4,
          host: '1.1.1.1',
          ip: '1.1.1.1',
          timeMs: null,
          status: PingPacketStatus.timeout,
          timestamp: now,
        ),
      ];

      final summary = PingSummary.fromPackets(
        host: '1.1.1.1',
        ip: '1.1.1.1',
        packets: packets,
      );

      expect(summary.totalSent, equals(4));
      expect(summary.totalReceived, equals(3));
      expect(summary.totalLost, equals(1));
      expect(summary.packetLossPercentage, equals(25.0));
      expect(summary.minTimeMs, equals(10.0));
      expect(summary.maxTimeMs, equals(30.0));
      expect(summary.avgTimeMs, equals(20.0));
      expect(summary.jitterMs, equals(10.0));
    });

    test('Handles empty packet list gracefully', () {
      final summary = PingSummary.fromPackets(
        host: '8.8.8.8',
        packets: [],
      );

      expect(summary.totalSent, equals(0));
      expect(summary.totalReceived, equals(0));
      expect(summary.minTimeMs, equals(0.0));
      expect(summary.avgTimeMs, equals(0.0));
      expect(summary.packetLossPercentage, equals(0.0));
    });
  });

  group('PingService Unit Tests', () {
    test('PingCancellationToken cancels stream execution', () {
      final token = PingCancellationToken();
      expect(token.isCancelled, isFalse);
      token.cancel();
      expect(token.isCancelled, isTrue);
    });
  });
}
