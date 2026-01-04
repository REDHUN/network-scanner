class OpenPort {
  final int port;
  final String service;
  final String description;
  final bool isSecure;

  OpenPort({
    required this.port,
    required this.service,
    required this.description,
    required this.isSecure,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OpenPort &&
          runtimeType == other.runtimeType &&
          port == other.port;

  @override
  int get hashCode => port.hashCode;
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

  int get openPortsCount => openPorts.length;
  int get closedPortsCount => totalPortsScanned - openPortsCount;
}
