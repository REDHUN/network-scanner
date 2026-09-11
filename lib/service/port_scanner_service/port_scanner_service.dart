import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ip_tools/models/network_model/open_port.dart';

/// Cancellation token to abort in-flight port scans and forcefully destroy active sockets.
class PortScanCancellationToken {
  bool _isCancelled = false;
  final Set<Socket> _activeSockets = {};

  bool get isCancelled => _isCancelled;

  void registerSocket(Socket socket) {
    if (_isCancelled) {
      try {
        socket.destroy();
      } catch (_) {}
    } else {
      _activeSockets.add(socket);
    }
  }

  void unregisterSocket(Socket socket) {
    _activeSockets.remove(socket);
  }

  void cancel() {
    _isCancelled = true;
    for (final socket in _activeSockets.toList()) {
      try {
        socket.destroy();
      } catch (_) {}
    }
    _activeSockets.clear();
  }
}

class PortScannerService {
  static final PortScannerService _instance = PortScannerService._internal();
  factory PortScannerService() => _instance;
  PortScannerService._internal();

  /// 22 Popular & Common LAN Ports
  static const List<int> commonPorts = [
    21, // FTP
    22, // SSH
    23, // Telnet
    25, // SMTP
    53, // DNS
    80, // HTTP
    110, // POP3
    135, // MS RPC
    139, // NetBIOS
    143, // IMAP
    443, // HTTPS
    445, // SMB
    548, // AFP
    554, // RTSP
    993, // IMAPS
    995, // POP3S
    1723, // PPTP
    3306, // MySQL
    3389, // RDP
    5432, // PostgreSQL
    5900, // VNC
    8080, // HTTP-Proxy / Alt
  ];

  /// Top 100 most frequent TCP ports
  static const List<int> top100Ports = [
    7,
    9,
    13,
    21,
    22,
    23,
    25,
    26,
    37,
    53,
    79,
    80,
    81,
    88,
    106,
    110,
    111,
    113,
    119,
    135,
    139,
    143,
    144,
    179,
    199,
    389,
    427,
    443,
    444,
    445,
    465,
    513,
    514,
    515,
    543,
    544,
    548,
    554,
    587,
    631,
    646,
    873,
    990,
    993,
    995,
    1025,
    1026,
    1027,
    1028,
    1029,
    1110,
    1433,
    1720,
    1723,
    1755,
    1900,
    2000,
    2001,
    2049,
    2121,
    2717,
    3000,
    3128,
    3306,
    3389,
    3986,
    4899,
    5000,
    5009,
    5051,
    5060,
    5101,
    5190,
    5357,
    5432,
    5631,
    5666,
    5800,
    5900,
    6000,
    6001,
    6646,
    7070,
    8000,
    8008,
    8009,
    8080,
    8081,
    8443,
    8888,
    9100,
    9999,
    10000,
    32768,
    49152,
    49153,
    49154,
    49155,
    49156,
    49157,
  ];

  /// Standard Well-Known Ports Range (1 to 1024)
  static List<int> get standardRange =>
      List.generate(1024, (index) => index + 1);

  /// Full Range (1 to 65535)
  static List<int> get fullRange =>
      List.generate(65535, (index) => index + 1);

  /// Bounded asynchronous TCP connect scanner with adaptive timeout and real-time streaming.
  Stream<PortScanProgress> scanPorts({
    required String ipAddress,
    required List<int> ports,
    int concurrency = 25,
    int initialTimeoutMs = 350,
    bool enableBannerProbing = true,
    PortScanCancellationToken? cancelToken,
  }) {
    late StreamController<PortScanProgress> controller;
    final startTime = DateTime.now();
    final openPorts = <OpenPort>[];
    final totalPorts = ports.length;

    int scannedPorts = 0;
    int nextPortIndex = 0;

    // Adaptive timeout controller
    int currentTimeoutMs = initialTimeoutMs;
    int consecutiveTimeouts = 0;

    void updateAdaptiveTimeout(int durationMs, bool isTimeout) {
      if (isTimeout) {
        consecutiveTimeouts++;
        if (consecutiveTimeouts >= 15 && currentTimeoutMs < 750) {
          // Increase timeout on congested/slow network
          currentTimeoutMs = (currentTimeoutMs * 1.15).round().clamp(250, 750);
          consecutiveTimeouts = 0;
        }
      } else {
        consecutiveTimeouts = 0;
        if (durationMs < 60 && currentTimeoutMs > 250) {
          // Fast responsive network, optimize towards lower bound
          currentTimeoutMs = (currentTimeoutMs * 0.95).round().clamp(250, 750);
        }
      }
    }

    controller = StreamController<PortScanProgress>(
      onListen: () async {
        if (totalPorts == 0) {
          controller.add(PortScanProgress(
            ipAddress: ipAddress,
            totalPorts: 0,
            scannedPorts: 0,
            progress: 1.0,
            openPorts: [],
            elapsed: Duration.zero,
            isComplete: true,
          ));
          await controller.close();
          return;
        }

        // Worker routine
        Future<void> runWorker() async {
          while (true) {
            if (cancelToken?.isCancelled == true || controller.isClosed) {
              break;
            }

            if (nextPortIndex >= ports.length) {
              break;
            }
            final port = ports[nextPortIndex++];

            final stopwatch = Stopwatch()..start();
            final openPort = await _checkSinglePort(
              ipAddress,
              port,
              currentTimeoutMs,
              cancelToken: cancelToken,
              enableBannerProbing: enableBannerProbing,
            );
            stopwatch.stop();

            final isTimeout = openPort == null;
            updateAdaptiveTimeout(stopwatch.elapsedMilliseconds, isTimeout);

            scannedPorts++;
            if (openPort != null) {
              openPorts.add(openPort);
            }

            if (!controller.isClosed) {
              final elapsed = DateTime.now().difference(startTime);
              final progress = (scannedPorts / totalPorts).clamp(0.0, 1.0);

              controller.add(PortScanProgress(
                ipAddress: ipAddress,
                totalPorts: totalPorts,
                scannedPorts: scannedPorts,
                progress: progress,
                latestFoundPort: openPort,
                openPorts: List.unmodifiable(openPorts),
                elapsed: elapsed,
                isCancelled: cancelToken?.isCancelled == true,
              ));
            }
          }
        }

        // Spawn bounded pool of workers
        final workerCount = concurrency.clamp(1, totalPorts);
        final workers = List.generate(workerCount, (_) => runWorker());

        await Future.wait(workers);

        if (!controller.isClosed) {
          final elapsed = DateTime.now().difference(startTime);
          controller.add(PortScanProgress(
            ipAddress: ipAddress,
            totalPorts: totalPorts,
            scannedPorts: scannedPorts,
            progress: 1.0,
            openPorts: List.unmodifiable(openPorts),
            elapsed: elapsed,
            isComplete: true,
            isCancelled: cancelToken?.isCancelled == true,
          ));
          await controller.close();
        }
      },
      onCancel: () {
        cancelToken?.cancel();
      },
    );

    return controller.stream;
  }

  /// Check if a single port is open, and optionally probe lightweight banner/service info.
  Future<OpenPort?> _checkSinglePort(
    String ipAddress,
    int port,
    int timeoutMs, {
    PortScanCancellationToken? cancelToken,
    bool enableBannerProbing = true,
  }) async {
    if (cancelToken?.isCancelled == true) return null;

    Socket? socket;
    try {
      socket = await Socket.connect(
        ipAddress,
        port,
        timeout: Duration(milliseconds: timeoutMs),
      );

      cancelToken?.registerSocket(socket);

      // Extract banner / service information if enabled
      String? banner;
      if (enableBannerProbing && cancelToken?.isCancelled != true) {
        banner = await _probeServiceBanner(socket, ipAddress, port);
      }

      try {
        socket.destroy();
      } catch (_) {}
      cancelToken?.unregisterSocket(socket);

      return OpenPort(
        port: port,
        service: _getServiceName(port),
        description: _getServiceDescription(port),
        isSecure: _isSecurePort(port),
        banner: banner,
      );
    } catch (e) {
      if (socket != null) {
        try {
          socket.destroy();
        } catch (_) {}
        cancelToken?.unregisterSocket(socket);
      }
      return null;
    }
  }

  /// Lightweight service banner probing for discovered open ports
  Future<String?> _probeServiceBanner(
    Socket socket,
    String ipAddress,
    int port,
  ) async {
    try {
      final isHttpPort = [80, 8080, 8000, 8081, 8888, 3000, 5000].contains(port);
      final isSshPort = port == 22;
      final isFtpOrSmtp = port == 21 || port == 25;

      if (isHttpPort) {
        socket.write('HEAD / HTTP/1.1\r\nHost: $ipAddress\r\nUser-Agent: NetworkScanner\r\nConnection: close\r\n\r\n');
        await socket.flush();
      }

      // Read response with strict 400ms timeout
      final rawData = await socket.first
          .timeout(const Duration(milliseconds: 400));
      final text = utf8.decode(rawData, allowMalformed: true).trim();

      if (text.isEmpty) return null;

      if (isHttpPort) {
        for (final line in text.split('\r\n')) {
          if (line.toLowerCase().startsWith('server:')) {
            return line.substring(7).trim();
          }
        }
        final firstLine = text.split('\r\n').first;
        if (firstLine.startsWith('HTTP/')) return firstLine;
      } else if (isSshPort || isFtpOrSmtp) {
        return text.split('\n').first.trim();
      }

      if (text.length <= 60) return text;
      return text.substring(0, 60);
    } catch (_) {
      return null;
    }
  }

  /// Comprehensive port scan with full result aggregation
  Future<PortScanResult> performComprehensiveScan(
    String ipAddress, {
    List<int>? customPorts,
    int startPort = 1,
    int endPort = 1024,
    int timeout = 350,
    int concurrency = 25,
    bool useCommonPorts = false,
    bool useTop100 = false,
    PortScanCancellationToken? cancelToken,
  }) async {
    final startTime = DateTime.now();

    List<int> portsToScan;
    if (customPorts != null) {
      portsToScan = customPorts;
    } else if (useCommonPorts) {
      portsToScan = commonPorts;
    } else if (useTop100) {
      portsToScan = top100Ports;
    } else {
      portsToScan = List.generate(
        endPort - startPort + 1,
        (i) => startPort + i,
      );
    }

    final openPorts = <OpenPort>[];
    await for (final progress in scanPorts(
      ipAddress: ipAddress,
      ports: portsToScan,
      concurrency: concurrency,
      initialTimeoutMs: timeout,
      cancelToken: cancelToken,
    )) {
      if (progress.isComplete || progress.isCancelled) {
        openPorts.addAll(progress.openPorts);
      }
    }

    final endTime = DateTime.now();
    return PortScanResult(
      ipAddress: ipAddress,
      openPorts: openPorts,
      scanTime: startTime,
      scanDuration: endTime.difference(startTime),
      totalPortsScanned: portsToScan.length,
    );
  }

  /// Fast single port check
  Future<bool> isPortOpen(
    String ipAddress,
    int port, {
    int timeout = 400,
  }) async {
    try {
      final socket = await Socket.connect(
        ipAddress,
        port,
        timeout: Duration(milliseconds: timeout),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Service name mapping
  String _getServiceName(int port) {
    switch (port) {
      case 21:
        return 'FTP';
      case 22:
        return 'SSH';
      case 23:
        return 'Telnet';
      case 25:
        return 'SMTP';
      case 53:
        return 'DNS';
      case 80:
        return 'HTTP';
      case 110:
        return 'POP3';
      case 135:
        return 'RPC';
      case 139:
        return 'NetBIOS';
      case 143:
        return 'IMAP';
      case 443:
        return 'HTTPS';
      case 445:
        return 'SMB / CIFS';
      case 548:
        return 'AFP';
      case 554:
        return 'RTSP';
      case 993:
        return 'IMAPS';
      case 995:
        return 'POP3S';
      case 1723:
        return 'PPTP';
      case 3389:
        return 'RDP';
      case 5900:
        return 'VNC';
      case 3306:
        return 'MySQL';
      case 5432:
        return 'PostgreSQL';
      case 1433:
        return 'MSSQL';
      case 8080:
        return 'HTTP-Alt';
      case 8443:
        return 'HTTPS-Alt';
      case 9100:
        return 'RAW Printer';
      default:
        return 'Port $port';
    }
  }

  /// Service description mapping
  String _getServiceDescription(int port) {
    switch (port) {
      case 21:
        return 'File Transfer Protocol';
      case 22:
        return 'Secure Shell';
      case 23:
        return 'Telnet Protocol';
      case 25:
        return 'Simple Mail Transfer Protocol';
      case 53:
        return 'Domain Name System';
      case 80:
        return 'HyperText Transfer Protocol';
      case 110:
        return 'Post Office Protocol v3';
      case 135:
        return 'Microsoft RPC';
      case 139:
        return 'NetBIOS Session Service';
      case 143:
        return 'Internet Message Access Protocol';
      case 443:
        return 'HTTP Secure (TLS/SSL)';
      case 445:
        return 'Server Message Block';
      case 548:
        return 'Apple Filing Protocol';
      case 554:
        return 'Real Time Streaming Protocol';
      case 993:
        return 'IMAP over SSL';
      case 995:
        return 'POP3 over SSL';
      case 1723:
        return 'Point-to-Point Tunneling Protocol';
      case 3389:
        return 'Remote Desktop Protocol';
      case 5900:
        return 'Virtual Network Computing';
      case 3306:
        return 'MySQL Database';
      case 5432:
        return 'PostgreSQL Database';
      case 1433:
        return 'Microsoft SQL Server';
      case 8080:
        return 'HTTP Alternative / Web Proxy';
      case 8443:
        return 'HTTPS Alternative';
      case 9100:
        return 'Network Direct Printing';
      default:
        return 'TCP Service';
    }
  }

  /// Check if a port is typically secure
  bool _isSecurePort(int port) {
    const securePorts = [22, 443, 993, 995, 8443];
    return securePorts.contains(port);
  }

  /// Get port vulnerability risk level
  String getPortRiskLevel(int port) {
    switch (port) {
      case 21:
      case 23:
      case 135:
      case 139:
      case 445:
        return 'High'; // Unencrypted or legacy Windows services
      case 22:
      case 443:
      case 993:
      case 995:
        return 'Low'; // Encrypted protocols
      case 80:
      case 8080:
        return 'Medium'; // Plaintext HTTP
      default:
        return 'Unknown';
    }
  }
}
