import 'dart:io';
import 'dart:typed_data';

import 'package:ip_tools/models/utilities_model/wol_result.dart';

class WolService {
  /// Validates whether a MAC address string is valid.
  bool isValidMac(String mac) {
    try {
      parseMac(mac);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Parses MAC string into 6-byte Uint8List.
  Uint8List parseMac(String mac) {
    final clean = mac.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    if (clean.length != 12) {
      throw FormatException('Invalid MAC address length: $mac');
    }

    final bytes = Uint8List(6);
    for (int i = 0; i < 6; i++) {
      final hex = clean.substring(i * 2, i * 2 + 2);
      bytes[i] = int.parse(hex, radix: 16);
    }
    return bytes;
  }

  /// Formats MAC into standard uppercase colon format: `AA:BB:CC:DD:EE:FF`
  String formatMac(String mac) {
    final bytes = parseMac(mac);
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
  }

  /// Builds standard 102-byte Wake-on-LAN Magic Packet payload.
  Uint8List buildMagicPacket(String mac) {
    final macBytes = parseMac(mac);
    final packet = Uint8List(102);

    // 6 bytes of 0xFF
    packet.fillRange(0, 6, 0xFF);

    // 16 repetitions of MAC address (16 * 6 = 96 bytes)
    for (int i = 0; i < 16; i++) {
      packet.setRange(6 + (i * 6), 6 + ((i + 1) * 6), macBytes);
    }

    return packet;
  }

  /// Sends Wake-on-LAN magic packet over UDP broadcast.
  /// Broadcasts to [broadcastIp] (defaults to `255.255.255.255`) and [port] (defaults to 9).
  Future<WolPacketResult> sendMagicPacket({
    required String macAddress,
    String broadcastIp = '255.255.255.255',
    int port = 9,
  }) async {
    final timestamp = DateTime.now();
    try {
      final formatted = formatMac(macAddress);
      final magicPacket = buildMagicPacket(macAddress);

      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      // Broadcast packet
      final sentCount = socket.send(
        magicPacket,
        InternetAddress(broadcastIp),
        port,
      );

      // Also send to global broadcast if custom subnet was given
      if (broadcastIp != '255.255.255.255') {
        socket.send(
          magicPacket,
          InternetAddress('255.255.255.255'),
          port,
        );
      }

      // Also send on alternative WoL port 7
      if (port != 7) {
        socket.send(
          magicPacket,
          InternetAddress(broadcastIp),
          7,
        );
      }

      socket.close();

      final isSuccess = sentCount > 0;
      return WolPacketResult(
        isSuccess: isSuccess,
        macAddress: macAddress,
        formattedMac: formatted,
        broadcastIp: broadcastIp,
        port: port,
        timestamp: timestamp,
        errorMessage: isSuccess ? null : 'Failed to send UDP datagram',
      );
    } catch (e) {
      return WolPacketResult(
        isSuccess: false,
        macAddress: macAddress,
        formattedMac: macAddress,
        broadcastIp: broadcastIp,
        port: port,
        timestamp: timestamp,
        errorMessage: e.toString(),
      );
    }
  }
}
