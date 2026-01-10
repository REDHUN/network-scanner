import 'package:ip_tools/models/network_model/scanned_device.dart';

class RouterNetworkData {
  final String routerId; // Combination of gateway IP + WiFi name
  final String gatewayIp;
  final String? wifiName;
  final String? subnet;
  final DateTime lastScanTime;
  final List<StoredDevice> devices;

  const RouterNetworkData({
    required this.routerId,
    required this.gatewayIp,
    this.wifiName,
    this.subnet,
    required this.lastScanTime,
    required this.devices,
  });

  Map<String, dynamic> toJson() {
    return {
      'routerId': routerId,
      'gatewayIp': gatewayIp,
      'wifiName': wifiName,
      'subnet': subnet,
      'lastScanTime': lastScanTime.millisecondsSinceEpoch,
      'devices': devices.map((d) => d.toJson()).toList(),
    };
  }

  factory RouterNetworkData.fromJson(Map<String, dynamic> json) {
    return RouterNetworkData(
      routerId: json['routerId'] as String,
      gatewayIp: json['gatewayIp'] as String,
      wifiName: json['wifiName'] as String?,
      subnet: json['subnet'] as String?,
      lastScanTime: DateTime.fromMillisecondsSinceEpoch(
        json['lastScanTime'] as int,
      ),
      devices: (json['devices'] as List<dynamic>)
          .map((d) => StoredDevice.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }

  RouterNetworkData copyWith({
    String? routerId,
    String? gatewayIp,
    String? wifiName,
    String? subnet,
    DateTime? lastScanTime,
    List<StoredDevice>? devices,
  }) {
    return RouterNetworkData(
      routerId: routerId ?? this.routerId,
      gatewayIp: gatewayIp ?? this.gatewayIp,
      wifiName: wifiName ?? this.wifiName,
      subnet: subnet ?? this.subnet,
      lastScanTime: lastScanTime ?? this.lastScanTime,
      devices: devices ?? this.devices,
    );
  }
}

class StoredDevice {
  final String ip;
  final String? mac;
  final String? name;
  final String? mdns;
  final bool isSelf;
  final bool isGateway;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final bool isOnline;

  const StoredDevice({
    required this.ip,
    this.mac,
    this.name,
    this.mdns,
    this.isSelf = false,
    this.isGateway = false,
    required this.firstSeen,
    required this.lastSeen,
    this.isOnline = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'ip': ip,
      'mac': mac,
      'name': name,
      'mdns': mdns,
      'isSelf': isSelf,
      'isGateway': isGateway,
      'firstSeen': firstSeen.millisecondsSinceEpoch,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
      'isOnline': isOnline,
    };
  }

  factory StoredDevice.fromJson(Map<String, dynamic> json) {
    return StoredDevice(
      ip: json['ip'] as String,
      mac: json['mac'] as String?,
      name: json['name'] as String?,
      mdns: json['mdns'] as String?,
      isSelf: json['isSelf'] as bool? ?? false,
      isGateway: json['isGateway'] as bool? ?? false,
      firstSeen: DateTime.fromMillisecondsSinceEpoch(json['firstSeen'] as int),
      lastSeen: DateTime.fromMillisecondsSinceEpoch(json['lastSeen'] as int),
      isOnline: json['isOnline'] as bool? ?? true,
    );
  }

  factory StoredDevice.fromScannedDevice(
    ScannedDevice device, {
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    return StoredDevice(
      ip: device.ip,
      mac: device.mac,
      name: device.name,
      mdns: device.mdns,
      isSelf: device.isSelf,
      isGateway: device.isGateway,
      firstSeen: now,
      lastSeen: now,
      isOnline: true,
    );
  }

  ScannedDevice toScannedDevice() {
    return ScannedDevice(
      ip: ip,
      mac: mac,
      name: name,
      mdns: mdns,
      isSelf: isSelf,
      isGateway: isGateway,
    );
  }

  StoredDevice copyWith({
    String? ip,
    String? mac,
    String? name,
    String? mdns,
    bool? isSelf,
    bool? isGateway,
    DateTime? firstSeen,
    DateTime? lastSeen,
    bool? isOnline,
  }) {
    return StoredDevice(
      ip: ip ?? this.ip,
      mac: mac ?? this.mac,
      name: name ?? this.name,
      mdns: mdns ?? this.mdns,
      isSelf: isSelf ?? this.isSelf,
      isGateway: isGateway ?? this.isGateway,
      firstSeen: firstSeen ?? this.firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  bool operator ==(Object other) => other is StoredDevice && other.ip == ip;

  @override
  int get hashCode => ip.hashCode;
}
