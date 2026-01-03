import 'package:flutter/material.dart';

class ScannedDevice {
  final String ip;
  final String? mac;
  final String? name;
  final String? mdns;
  final bool isSelf;
  final bool isGateway;

  const ScannedDevice({
    required this.ip,
    this.mac,
    this.name,
    this.mdns,
    this.isSelf = false,
    this.isGateway = false,
  });

  String get displayName {
    if (isSelf) return 'This Device';
    if (isGateway) return 'Router';
    if (mdns != null) return mdns!;
    if (name != null) return name!;
    return 'Unknown Device';
  }

  IconData get icon {
    if (isGateway) return Icons.router;
    if (isSelf) return Icons.smartphone;
    if (mdns != null) return Icons.cast;
    return Icons.devices;
  }

  @override
  bool operator ==(Object other) =>
      other is ScannedDevice && other.ip == ip;

  @override
  int get hashCode => ip.hashCode;
}
