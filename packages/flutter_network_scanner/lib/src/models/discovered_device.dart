/// Representation of a network device discovered during scanning.
class DiscoveredDevice {
  final String ip;
  final String? hostname;
  final List<int> openPorts;
  final String? mac;
  final String? vendor;
  final int pingMs;
  final String deviceType;
  final bool isCurrentDevice;
  final bool isGateway;

  const DiscoveredDevice({
    required this.ip,
    this.hostname,
    this.openPorts = const [],
    this.mac,
    this.vendor,
    this.pingMs = 0,
    this.deviceType = 'generic',
    this.isCurrentDevice = false,
    this.isGateway = false,
  });

  factory DiscoveredDevice.fromMap(Map<dynamic, dynamic> map) {
    return DiscoveredDevice(
      ip: (map['ip'] as String?) ?? '0.0.0.0',
      hostname: map['hostname'] as String?,
      openPorts: (map['openPorts'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      mac: map['mac'] as String?,
      vendor: map['vendor'] as String?,
      pingMs: (map['pingMs'] as num?)?.toInt() ?? 0,
      deviceType: (map['deviceType'] as String?) ?? 'generic',
      isCurrentDevice: (map['isCurrentDevice'] as bool?) ?? false,
      isGateway: (map['isGateway'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ip': ip,
      'hostname': hostname,
      'openPorts': openPorts,
      'mac': mac,
      'vendor': vendor,
      'pingMs': pingMs,
      'deviceType': deviceType,
      'isCurrentDevice': isCurrentDevice,
      'isGateway': isGateway,
    };
  }

  String get displayName {
    if (hostname != null && hostname!.isNotEmpty) {
      return hostname!;
    }
    if (isGateway) {
      return 'Router / Gateway';
    }
    if (isCurrentDevice) {
      return 'This Device';
    }
    return 'Device ($ip)';
  }

  static String getPortServiceName(int port) {
    switch (port) {
      case 20:
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
      case 139:
      case 445:
        return 'SMB / NetBIOS';
      case 143:
        return 'IMAP';
      case 443:
        return 'HTTPS';
      case 3000:
        return 'Dev (3000)';
      case 3389:
        return 'RDP';
      case 5000:
        return 'UPnP / AirPlay';
      case 5353:
        return 'mDNS';
      case 62078:
        return 'Apple Sync';
      case 8008:
      case 8009:
        return 'Chromecast';
      case 8080:
        return 'HTTP-Alt';
      case 8443:
        return 'HTTPS-Alt';
      case 9100:
        return 'Printer / JetDirect';
      default:
        return 'Port $port';
    }
  }
}
