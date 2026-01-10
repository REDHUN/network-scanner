import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ip_tools/models/network_model/open_port.dart';

class PortScannerService {
  static final PortScannerService _instance = PortScannerService._internal();
  factory PortScannerService() => _instance;
  PortScannerService._internal();

  /// Common ports to scan (similar to Vernet's popular ports)
  static const List<int> commonPorts = [
    21,
    22,
    23,
    25,
    53,
    80,
    110,
    135,
    139,
    143,
    443,
    993,
    995,
    1723,
    3389,
    5900,
  ];

  /// Top 100 most common ports
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

  /// Scan specific ports on a target IP
  Stream<OpenPort> scanSpecificPorts(
    String ipAddress,
    List<int> ports, {
    int timeout = 500,
    bool async = true,
  }) async* {
    debugPrint('Starting port scan on $ipAddress for ${ports.length} ports');

    if (async) {
      // Parallel scanning for better performance
      final futures = ports.map(
        (port) => _checkSinglePort(ipAddress, port, timeout),
      );
      final results = await Future.wait(futures);
      for (final result in results) {
        if (result != null) {
          yield result;
        }
      }
    } else {
      // Sequential scanning
      for (final port in ports) {
        final result = await _checkSinglePort(ipAddress, port, timeout);
        if (result != null) {
          yield result;
        }
      }
    }
  }

  /// Scan port range on a target IP
  Stream<OpenPort> scanPortRange(
    String ipAddress, {
    int startPort = 1,
    int endPort = 1000,
    int timeout = 500,
    bool async = true,
  }) async* {
    final ports = List.generate(endPort - startPort + 1, (i) => startPort + i);
    yield* scanSpecificPorts(ipAddress, ports, timeout: timeout, async: async);
  }

  /// Scan common ports (quick scan)
  Stream<OpenPort> scanCommonPorts(
    String ipAddress, {
    int timeout = 500,
  }) async* {
    yield* scanSpecificPorts(ipAddress, commonPorts, timeout: timeout);
  }

  /// Scan top 100 ports
  Stream<OpenPort> scanTop100Ports(
    String ipAddress, {
    int timeout = 500,
  }) async* {
    yield* scanSpecificPorts(ipAddress, top100Ports, timeout: timeout);
  }

  /// Comprehensive port scan with result object
  Future<PortScanResult> performComprehensiveScan(
    String ipAddress, {
    List<int>? customPorts,
    int startPort = 1,
    int endPort = 1000,
    int timeout = 500,
    bool useCommonPorts = false,
    bool useTop100 = false,
  }) async {
    final startTime = DateTime.now();
    final openPorts = <OpenPort>[];

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

    await for (final openPort in scanSpecificPorts(
      ipAddress,
      portsToScan,
      timeout: timeout,
    )) {
      openPorts.add(openPort);
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    return PortScanResult(
      ipAddress: ipAddress,
      openPorts: openPorts,
      scanTime: startTime,
      scanDuration: duration,
      totalPortsScanned: portsToScan.length,
    );
  }

  /// Check if a single port is open
  Future<OpenPort?> _checkSinglePort(
    String ipAddress,
    int port,
    int timeout,
  ) async {
    try {
      final socket = await Socket.connect(
        ipAddress,
        port,
        timeout: Duration(milliseconds: timeout),
      );
      await socket.close();

      return OpenPort(
        port: port,
        service: _getServiceName(port),
        description: _getServiceDescription(port),
        isSecure: _isSecurePort(port),
      );
    } catch (e) {
      // Port is closed or filtered
      return null;
    }
  }

  /// Check if a specific port is open (public method)
  Future<bool> isPortOpen(
    String ipAddress,
    int port, {
    int timeout = 500,
  }) async {
    try {
      final socket = await Socket.connect(
        ipAddress,
        port,
        timeout: Duration(milliseconds: timeout),
      );
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get service name for a port
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
      default:
        return 'Unknown';
    }
  }

  /// Get service description for a port
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
        return 'HTTP Secure';
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
        return 'HTTP Alternative';
      case 8443:
        return 'HTTPS Alternative';
      default:
        return 'Unknown Service';
    }
  }

  /// Check if a port is typically secure
  bool _isSecurePort(int port) {
    const securePorts = [22, 443, 993, 995, 8443];
    return securePorts.contains(port);
  }

  /// Get port vulnerability level (informational)
  String getPortRiskLevel(int port) {
    switch (port) {
      case 21:
      case 23:
      case 135:
      case 139:
        return 'High'; // Commonly exploited
      case 22:
      case 443:
      case 993:
      case 995:
        return 'Low'; // Secure protocols
      case 80:
      case 8080:
        return 'Medium'; // HTTP services
      default:
        return 'Unknown';
    }
  }
}
