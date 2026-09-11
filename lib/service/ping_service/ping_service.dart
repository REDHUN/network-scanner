import 'dart:async';
import 'dart:io';

import 'package:ip_tools/models/utilities_model/ping_result.dart';

class PingCancellationToken {
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}

class PingService {
  /// Resolves hostname to an IPv4 string if possible.
  Future<String?> resolveHost(String host) async {
    try {
      final addresses = await InternetAddress.lookup(host);
      if (addresses.isNotEmpty) {
        final ipv4 = addresses.firstWhere(
          (a) => a.type == InternetAddressType.IPv4,
          orElse: () => addresses.first,
        );
        return ipv4.address;
      }
    } catch (_) {}
    return null;
  }

  /// Streams real-time ping packets to the given [host].
  /// [count] = 0 means continuous ping until cancelled or stopped.
  Stream<PingPacket> startPing({
    required String host,
    int count = 0,
    int intervalMs = 1000,
    int timeoutMs = 2000,
    PingMode mode = PingMode.icmp,
    int tcpPort = 80,
    PingCancellationToken? token,
  }) async* {
    final effectiveToken = token ?? PingCancellationToken();
    final cleanHost = host.trim();
    if (cleanHost.isEmpty) return;

    final resolvedIp = await resolveHost(cleanHost);
    int sequence = 1;

    while (!effectiveToken.isCancelled && (count == 0 || sequence <= count)) {
      final packet = (mode == PingMode.icmp)
          ? await _pingIcmpSingle(
              host: cleanHost,
              resolvedIp: resolvedIp,
              sequence: sequence,
              timeoutMs: timeoutMs,
            )
          : await _pingTcpSingle(
              host: cleanHost,
              resolvedIp: resolvedIp,
              port: tcpPort,
              sequence: sequence,
              timeoutMs: timeoutMs,
            );

      yield packet;

      sequence++;

      if (!effectiveToken.isCancelled && (count == 0 || sequence <= count)) {
        await Future.delayed(Duration(milliseconds: intervalMs));
      }
    }
  }

  /// Single ICMP ping attempt
  Future<PingPacket> _pingIcmpSingle({
    required String host,
    String? resolvedIp,
    required int sequence,
    required int timeoutMs,
  }) async {
    final timestamp = DateTime.now();
    try {
      List<String> args;
      if (Platform.isWindows) {
        args = ['-n', '1', '-w', timeoutMs.toString(), host];
      } else if (Platform.isMacOS) {
        args = ['-c', '1', '-W', (timeoutMs / 1000).ceil().toString(), host];
      } else {
        // Android / Linux
        final timeoutSec = (timeoutMs / 1000).ceil().clamp(1, 10).toString();
        args = ['-c', '1', '-W', timeoutSec, host];
      }

      final stopwatch = Stopwatch()..start();
      final result = await Process.run(
        'ping',
        args,
        runInShell: false,
      ).timeout(Duration(milliseconds: timeoutMs + 500));
      stopwatch.stop();

      final output = '${result.stdout} ${result.stderr}';
      final parsed = _parseIcmpOutput(output);

      if (parsed.timeMs != null) {
        return PingPacket(
          sequence: sequence,
          host: host,
          ip: parsed.ip ?? resolvedIp,
          timeMs: parsed.timeMs,
          ttl: parsed.ttl,
          status: PingPacketStatus.success,
          timestamp: timestamp,
        );
      } else if (output.toLowerCase().contains('timed out') ||
          output.toLowerCase().contains('100% packet loss') ||
          output.toLowerCase().contains('100.0% packet loss') ||
          output.toLowerCase().contains('unreachable')) {
        return PingPacket(
          sequence: sequence,
          host: host,
          ip: resolvedIp,
          status: PingPacketStatus.timeout,
          errorMessage: 'Request timed out',
          timestamp: timestamp,
        );
      } else {
        // Fallback to TCP ping if ICMP is blocked/unsupported by OS sandbox
        return await _pingTcpSingle(
          host: host,
          resolvedIp: resolvedIp,
          port: 80,
          sequence: sequence,
          timeoutMs: timeoutMs,
        );
      }
    } on TimeoutException {
      return PingPacket(
        sequence: sequence,
        host: host,
        ip: resolvedIp,
        status: PingPacketStatus.timeout,
        errorMessage: 'Request timed out',
        timestamp: timestamp,
      );
    } catch (_) {
      // Fallback to TCP connection measurement
      return await _pingTcpSingle(
        host: host,
        resolvedIp: resolvedIp,
        port: 80,
        sequence: sequence,
        timeoutMs: timeoutMs,
      );
    }
  }

  /// Single TCP Ping (measures socket connection establishment time)
  Future<PingPacket> _pingTcpSingle({
    required String host,
    String? resolvedIp,
    int port = 80,
    required int sequence,
    required int timeoutMs,
  }) async {
    final timestamp = DateTime.now();
    final stopwatch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: Duration(milliseconds: timeoutMs),
      );
      stopwatch.stop();
      final rtt = stopwatch.elapsedMicroseconds / 1000.0;
      socket.destroy();

      return PingPacket(
        sequence: sequence,
        host: host,
        ip: resolvedIp ?? socket.remoteAddress.address,
        timeMs: double.parse(rtt.toStringAsFixed(2)),
        ttl: null,
        status: PingPacketStatus.success,
        timestamp: timestamp,
      );
    } on SocketException catch (e) {
      stopwatch.stop();
      final rtt = stopwatch.elapsedMicroseconds / 1000.0;
      // Connection refused means host is UP and responded with RST!
      if (e.osError?.errorCode == 111 ||
          e.osError?.errorCode == 10061 ||
          e.message.toLowerCase().contains('connection refused')) {
        return PingPacket(
          sequence: sequence,
          host: host,
          ip: resolvedIp,
          timeMs: double.parse(rtt.toStringAsFixed(2)),
          ttl: null,
          status: PingPacketStatus.success,
          timestamp: timestamp,
        );
      }
      return PingPacket(
        sequence: sequence,
        host: host,
        ip: resolvedIp,
        status: PingPacketStatus.timeout,
        errorMessage: 'Host unreachable / timed out',
        timestamp: timestamp,
      );
    } on TimeoutException {
      return PingPacket(
        sequence: sequence,
        host: host,
        ip: resolvedIp,
        status: PingPacketStatus.timeout,
        errorMessage: 'Connection timed out',
        timestamp: timestamp,
      );
    } catch (e) {
      return PingPacket(
        sequence: sequence,
        host: host,
        ip: resolvedIp,
        status: PingPacketStatus.error,
        errorMessage: e.toString(),
        timestamp: timestamp,
      );
    }
  }

  _ParsedIcmp _parseIcmpOutput(String output) {
    double? timeMs;
    int? ttl;
    String? ip;

    // Regex for IP: [192.168.1.1] or from 192.168.1.1
    final ipMatch = RegExp(r'(?:from|From|\[)\s*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)').firstMatch(output);
    if (ipMatch != null) {
      ip = ipMatch.group(1);
    }

    // Regex for time: time=12.4ms or time<1ms or time=12ms
    final timeMatch = RegExp(r'time[=<]\s*([0-9.]+)\s*ms', caseSensitive: false).firstMatch(output);
    if (timeMatch != null) {
      timeMs = double.tryParse(timeMatch.group(1) ?? '');
    }

    // Regex for TTL: TTL=64 or ttl=117
    final ttlMatch = RegExp(r'ttl[=:]\s*([0-9]+)', caseSensitive: false).firstMatch(output);
    if (ttlMatch != null) {
      ttl = int.tryParse(ttlMatch.group(1) ?? '');
    }

    return _ParsedIcmp(timeMs: timeMs, ttl: ttl, ip: ip);
  }
}

class _ParsedIcmp {
  final double? timeMs;
  final int? ttl;
  final String? ip;
  _ParsedIcmp({this.timeMs, this.ttl, this.ip});
}
