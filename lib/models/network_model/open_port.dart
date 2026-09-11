class OpenPort {
  final int port;
  final String service;
  final String description;
  final bool isSecure;
  final String? banner;

  OpenPort({
    required this.port,
    required this.service,
    required this.description,
    required this.isSecure,
    this.banner,
  });

  Map<String, dynamic> toJson() {
    return {
      'port': port,
      'service': service,
      'description': description,
      'isSecure': isSecure,
      if (banner != null) 'banner': banner,
    };
  }

  factory OpenPort.fromJson(Map<String, dynamic> json) {
    return OpenPort(
      port: json['port'] as int,
      service: json['service'] as String,
      description: json['description'] as String,
      isSecure: json['isSecure'] as bool,
      banner: json['banner'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OpenPort &&
          runtimeType == other.runtimeType &&
          port == other.port;

  @override
  int get hashCode => port.hashCode;
}

class PortScanProgress {
  final String ipAddress;
  final int totalPorts;
  final int scannedPorts;
  final double progress; // 0.0 to 1.0
  final OpenPort? latestFoundPort;
  final List<OpenPort> openPorts;
  final Duration elapsed;
  final bool isComplete;
  final bool isCancelled;

  PortScanProgress({
    required this.ipAddress,
    required this.totalPorts,
    required this.scannedPorts,
    required this.progress,
    this.latestFoundPort,
    required this.openPorts,
    required this.elapsed,
    this.isComplete = false,
    this.isCancelled = false,
  });

  int get openPortsCount => openPorts.length;
}

class PortScanResult {
  final String ipAddress;
  final List<OpenPort> openPorts;
  final DateTime scanTime;
  final Duration scanDuration;
  final int totalPortsScanned;

  PortScanResult({
    required this.ipAddress,
    required this.openPorts,
    required this.scanTime,
    required this.scanDuration,
    required this.totalPortsScanned,
  });

  Map<String, dynamic> toJson() {
    return {
      'ipAddress': ipAddress,
      'openPorts': openPorts.map((p) => p.toJson()).toList(),
      'scanTime': scanTime.millisecondsSinceEpoch,
      'scanDuration': scanDuration.inMilliseconds,
      'totalPortsScanned': totalPortsScanned,
    };
  }

  factory PortScanResult.fromJson(Map<String, dynamic> json) {
    return PortScanResult(
      ipAddress: json['ipAddress'] as String,
      openPorts: (json['openPorts'] as List<dynamic>)
          .map((p) => OpenPort.fromJson(p as Map<String, dynamic>))
          .toList(),
      scanTime: DateTime.fromMillisecondsSinceEpoch(json['scanTime'] as int),
      scanDuration: Duration(milliseconds: json['scanDuration'] as int),
      totalPortsScanned: json['totalPortsScanned'] as int,
    );
  }

  int get openPortsCount => openPorts.length;
  int get closedPortsCount => totalPortsScanned - openPortsCount;
}
