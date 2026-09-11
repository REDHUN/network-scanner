import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ip_tools/models/utilities_model/traceroute_hop.dart';

class TracerouteCancellationToken {
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}

class TracerouteService {
  /// Resolves hostname or IP reverse DNS.
  Future<String?> reverseDns(String ip) async {
    try {
      final addr = InternetAddress(ip);
      final host = await addr.reverse();
      if (host.host != ip) {
        return host.host;
      }
    } catch (_) {}
    return null;
  }

  /// Streams discovered hops for [host] up to [maxHops].
  /// Continues probing through consecutive timeouts until destination is reached or maxHops is reached.
  Stream<TracerouteHop> startTraceroute({
    required String host,
    int maxHops = 30,
    int timeoutMs = 2000,
    TracerouteCancellationToken? token,
  }) async* {
    final effectiveToken = token ?? TracerouteCancellationToken();
    final cleanHost = host.trim().replaceAll(RegExp(r'^https?://'), '').split('/')[0];
    if (cleanHost.isEmpty) return;

    // Resolve target IP upfront to accurately recognize when destination is reached
    String? targetIp;
    try {
      final addrs = await InternetAddress.lookup(cleanHost).timeout(const Duration(seconds: 3));
      if (addrs.isNotEmpty) {
        targetIp = addrs.first.address;
      }
    } catch (_) {}

    if (Platform.isWindows) {
      yield* _traceWindows(cleanHost, targetIp, maxHops, timeoutMs, effectiveToken);
    } else {
      yield* _traceUnixOrTtl(cleanHost, targetIp, maxHops, timeoutMs, effectiveToken);
    }
  }

  /// Tracert execution on Windows
  Stream<TracerouteHop> _traceWindows(
    String host,
    String? targetIp,
    int maxHops,
    int timeoutMs,
    TracerouteCancellationToken token,
  ) async* {
    try {
      final process = await Process.start(
        'tracert',
        ['-d', '-h', maxHops.toString(), '-w', timeoutMs.toString(), host],
        runInShell: false,
      );

      final lineStream = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lineStream) {
        if (token.isCancelled) {
          process.kill();
          break;
        }

        final hop = _parseWindowsHopLine(line);
        if (hop != null) {
          String? hostname;
          final isDest = _isDestinationMatch(hop.ip, host, targetIp);
          if (hop.ip != null && hop.ip != '*') {
            hostname = await reverseDns(hop.ip!);
          }

          yield TracerouteHop(
            hopNumber: hop.hopNumber,
            ip: hop.ip,
            hostname: hostname,
            latenciesMs: hop.latenciesMs,
            avgLatencyMs: hop.avgLatencyMs,
            status: hop.status,
            isDestination: isDest,
            errorMessage: hop.errorMessage,
          );

          if (isDest) {
            process.kill();
            break;
          }
        }
      }
    } catch (_) {
      // Fallback to TTL probe if process execution fails
      yield* _ttlSteppingProbe(host, targetIp, maxHops, timeoutMs, token);
    }
  }

  /// Traceroute on Linux/Android/macOS with TTL fallback
  Stream<TracerouteHop> _traceUnixOrTtl(
    String host,
    String? targetIp,
    int maxHops,
    int timeoutMs,
    TracerouteCancellationToken token,
  ) async* {
    bool processSucceeded = false;
    try {
      final timeoutSec = (timeoutMs / 1000).ceil().clamp(1, 10).toString();
      final process = await Process.start(
        'traceroute',
        ['-n', '-m', maxHops.toString(), '-w', timeoutSec, host],
        runInShell: false,
      );

      final lineStream = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lineStream) {
        if (token.isCancelled) {
          process.kill();
          break;
        }

        final hop = _parseUnixHopLine(line);
        if (hop != null) {
          processSucceeded = true;
          String? hostname;
          final isDest = _isDestinationMatch(hop.ip, host, targetIp);
          if (hop.ip != null && hop.ip != '*') {
            hostname = await reverseDns(hop.ip!);
          }

          yield TracerouteHop(
            hopNumber: hop.hopNumber,
            ip: hop.ip,
            hostname: hostname,
            latenciesMs: hop.latenciesMs,
            avgLatencyMs: hop.avgLatencyMs,
            status: hop.status,
            isDestination: isDest,
            errorMessage: hop.errorMessage,
          );

          if (isDest) {
            process.kill();
            break;
          }
        }
      }
    } catch (_) {
      processSucceeded = false;
    }

    if (!processSucceeded && !token.isCancelled) {
      yield* _ttlSteppingProbe(host, targetIp, maxHops, timeoutMs, token);
    }
  }

  /// TTL stepping probe: Sends probes with increasing TTL (1..maxHops).
  /// Continues past unresponding routers until the destination responds or maxHops is reached.
  Stream<TracerouteHop> _ttlSteppingProbe(
    String host,
    String? targetIp,
    int maxHops,
    int timeoutMs,
    TracerouteCancellationToken token,
  ) async* {
    for (int ttl = 1; ttl <= maxHops && !token.isCancelled; ttl++) {
      final hop = await _probeTtl(host, ttl, timeoutMs);
      String? hostname;
      final isDest = _isDestinationMatch(hop.ip, host, targetIp);
      if (hop.ip != null && hop.ip != '*') {
        hostname = await reverseDns(hop.ip!);
      }

      yield TracerouteHop(
        hopNumber: hop.hopNumber,
        ip: hop.ip,
        hostname: hostname,
        latenciesMs: hop.latenciesMs,
        avgLatencyMs: hop.avgLatencyMs,
        status: hop.status,
        isDestination: isDest,
        errorMessage: hop.errorMessage,
      );

      if (isDest) {
        break;
      }
    }
  }

  Future<TracerouteHop> _probeTtl(String host, int ttl, int timeoutMs) async {
    final latencies = <double?>[];
    String? responderIp;

    // Send 3 probes per hop
    for (int probe = 0; probe < 3; probe++) {
      final stopwatch = Stopwatch()..start();
      try {
        List<String> args;
        if (Platform.isWindows) {
          args = ['-n', '1', '-i', ttl.toString(), '-w', timeoutMs.toString(), host];
        } else {
          final timeoutSec = (timeoutMs / 1000).ceil().clamp(1, 5).toString();
          args = ['-c', '1', '-t', ttl.toString(), '-W', timeoutSec, host];
        }

        final result = await Process.run('ping', args).timeout(Duration(milliseconds: timeoutMs + 300));
        stopwatch.stop();

        final output = '${result.stdout} ${result.stderr}';
        final ipMatch = RegExp(r'(?:from|From|\[)\s*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)').firstMatch(output);
        final rtt = stopwatch.elapsedMilliseconds.toDouble();

        if (ipMatch != null) {
          responderIp ??= ipMatch.group(1);
          latencies.add(rtt);
        } else {
          latencies.add(null);
        }
      } catch (_) {
        latencies.add(null);
      }
    }

    final validLatencies = latencies.whereType<double>().toList();
    final avg = validLatencies.isNotEmpty
        ? validLatencies.reduce((a, b) => a + b) / validLatencies.length
        : null;

    final isTimeout = responderIp == null;

    return TracerouteHop(
      hopNumber: ttl,
      ip: isTimeout ? '*' : responderIp,
      latenciesMs: latencies,
      avgLatencyMs: avg != null ? double.parse(avg.toStringAsFixed(1)) : null,
      status: isTimeout ? HopStatus.timeout : HopStatus.completed,
    );
  }

  bool _isDestinationMatch(String? hopIp, String host, String? targetIp) {
    if (hopIp == null || hopIp == '*' || hopIp.isEmpty) return false;
    if (hopIp == host || hopIp == targetIp) return true;
    return false;
  }

  TracerouteHop? _parseWindowsHopLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;

    final regex = RegExp(r'^\s*([0-9]+)\s+([<0-9*]+(?:\s*ms)?)\s+([<0-9*]+(?:\s*ms)?)\s+([<0-9*]+(?:\s*ms)?)\s+([0-9a-fA-F.:*]+|\*|Request timed out\.)');
    final match = regex.firstMatch(trimmed);

    if (match != null) {
      final hopNum = int.tryParse(match.group(1) ?? '') ?? 0;
      if (hopNum == 0) return null;

      final rtt1Str = match.group(2) ?? '';
      final rtt2Str = match.group(3) ?? '';
      final rtt3Str = match.group(4) ?? '';
      final target = match.group(5) ?? '';

      final latencies = [_parseRtt(rtt1Str), _parseRtt(rtt2Str), _parseRtt(rtt3Str)];
      final validLatencies = latencies.whereType<double>().toList();
      final avg = validLatencies.isNotEmpty
          ? validLatencies.reduce((a, b) => a + b) / validLatencies.length
          : null;

      final isTimeout = target.contains('*') || target.contains('timed out');
      final ip = isTimeout ? '*' : target;

      return TracerouteHop(
        hopNumber: hopNum,
        ip: ip,
        latenciesMs: latencies,
        avgLatencyMs: avg != null ? double.parse(avg.toStringAsFixed(1)) : null,
        status: isTimeout ? HopStatus.timeout : HopStatus.completed,
      );
    }
    return null;
  }

  TracerouteHop? _parseUnixHopLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;

    final parts = trimmed.split(RegExp(r'\s+'));
    final hopNum = int.tryParse(parts.first);
    if (hopNum == null) return null;

    if (parts.contains('*') && parts.length <= 4) {
      return TracerouteHop(
        hopNumber: hopNum,
        ip: '*',
        latenciesMs: [null, null, null],
        avgLatencyMs: null,
        status: HopStatus.timeout,
      );
    }

    String? ip;
    final latencies = <double?>[];

    for (int i = 1; i < parts.length; i++) {
      final p = parts[i];
      if (RegExp(r'^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$').hasMatch(p) && ip == null) {
        ip = p;
      } else if (RegExp(r'^[0-9.]+$').hasMatch(p)) {
        final val = double.tryParse(p);
        if (val != null) latencies.add(val);
      }
    }

    final valid = latencies.whereType<double>().toList();
    final avg = valid.isNotEmpty ? valid.reduce((a, b) => a + b) / valid.length : null;

    return TracerouteHop(
      hopNumber: hopNum,
      ip: ip ?? '*',
      latenciesMs: latencies.isNotEmpty ? latencies : [null],
      avgLatencyMs: avg != null ? double.parse(avg.toStringAsFixed(1)) : null,
      status: ip != null ? HopStatus.completed : HopStatus.timeout,
    );
  }

  double? _parseRtt(String s) {
    if (s.contains('<1')) return 0.5;
    final match = RegExp(r'([0-9.]+)').firstMatch(s);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '');
    }
    return null;
  }
}
