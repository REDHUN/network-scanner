import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Subnet Calculator Logic Tests', () {
    int ipToInt(String ip) {
      final parts = ip.trim().split('.');
      int res = 0;
      for (final p in parts) {
        final val = int.parse(p);
        res = (res << 8) | val;
      }
      return res;
    }

    String intToIp(int val) {
      return '${(val >> 24) & 0xFF}.${(val >> 16) & 0xFF}.${(val >> 8) & 0xFF}.${val & 0xFF}';
    }

    int cidrToMask(int cidr) {
      if (cidr == 0) return 0;
      return (-1 << (32 - cidr)) & 0xFFFFFFFF;
    }

    test('/24 Subnet calculations are correct for 192.168.1.100', () {
      final ip = ipToInt('192.168.1.100');
      final mask = cidrToMask(24);
      final wildcard = ~mask & 0xFFFFFFFF;
      final network = ip & mask;
      final broadcast = network | wildcard;
      final totalHosts = pow(2, 32 - 24).toInt();
      final usableHosts = totalHosts - 2;

      expect(intToIp(mask), equals('255.255.255.0'));
      expect(intToIp(network), equals('192.168.1.0'));
      expect(intToIp(broadcast), equals('192.168.1.255'));
      expect(intToIp(network + 1), equals('192.168.1.1'));
      expect(intToIp(broadcast - 1), equals('192.168.1.254'));
      expect(totalHosts, equals(256));
      expect(usableHosts, equals(254));
    });

    test('/16 Subnet calculations are correct for 10.0.5.20', () {
      final ip = ipToInt('10.0.5.20');
      final mask = cidrToMask(16);
      final network = ip & mask;
      final broadcast = network | (~mask & 0xFFFFFFFF);

      expect(intToIp(mask), equals('255.255.0.0'));
      expect(intToIp(network), equals('10.0.0.0'));
      expect(intToIp(broadcast), equals('10.0.255.255'));
    });
  });
}
