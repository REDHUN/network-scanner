import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tools/service/wol_service/wol_service.dart';

void main() {
  group('WolService Tests', () {
    final wolService = WolService();

    test('Validates MAC formats correctly', () {
      expect(wolService.isValidMac('00:11:22:33:44:55'), isTrue);
      expect(wolService.isValidMac('00-11-22-33-44-55'), isTrue);
      expect(wolService.isValidMac('001122334455'), isTrue);
      expect(wolService.isValidMac('0011.2233.4455'), isTrue);
      expect(wolService.isValidMac('invalid_mac'), isFalse);
      expect(wolService.isValidMac('00:11:22'), isFalse);
    });

    test('Formats MAC into uppercase colon format', () {
      expect(wolService.formatMac('001122334455'), equals('00:11:22:33:44:55'));
      expect(wolService.formatMac('aa-bb-cc-dd-ee-ff'), equals('AA:BB:CC:DD:EE:FF'));
    });

    test('Constructs 102-byte Magic Packet with 6x 0xFF and 16x MAC sequence', () {
      const mac = 'AA:BB:CC:DD:EE:FF';
      final packet = wolService.buildMagicPacket(mac);

      expect(packet.length, equals(102));

      // Check first 6 bytes are 0xFF
      for (int i = 0; i < 6; i++) {
        expect(packet[i], equals(0xFF));
      }

      // Check 16 repetitions of MAC bytes
      final expectedMacBytes = Uint8List.fromList([0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]);
      for (int rep = 0; rep < 16; rep++) {
        final start = 6 + (rep * 6);
        final slice = packet.sublist(start, start + 6);
        expect(slice, equals(expectedMacBytes));
      }
    });
  });
}
