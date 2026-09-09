class NetworkInfoModel {
  final String? wifiName;
  final String? wifiIP;
  final String? subnet;
  final String? gateway;
  final String? bssid;
  final String? ipv6;
  final String? broadcast;

  // Connection & State
  final String? wifiState;
  final String? connectionType;
  final String? localhost;

  // Public IP, ISP & Location Info
  final String? publicIp;
  final String? isp;
  final String? organization;
  final String? asn;
  final String? timezone;
  final String? city;
  final String? region;
  final String? country;
  final double? latitude;
  final double? longitude;

  const NetworkInfoModel({
    this.wifiName,
    this.wifiIP,
    this.subnet,
    this.gateway,
    this.bssid,
    this.ipv6,
    this.broadcast,
    this.wifiState = 'Online',
    this.connectionType = 'WIFI',
    this.localhost = '127.0.0.1',
    this.publicIp,
    this.isp,
    this.organization,
    this.asn,
    this.timezone,
    this.city,
    this.region,
    this.country,
    this.latitude,
    this.longitude,
  });

  NetworkInfoModel copyWith({
    String? wifiName,
    String? wifiIP,
    String? subnet,
    String? gateway,
    String? bssid,
    String? ipv6,
    String? broadcast,
    String? wifiState,
    String? connectionType,
    String? localhost,
    String? publicIp,
    String? isp,
    String? organization,
    String? asn,
    String? timezone,
    String? city,
    String? region,
    String? country,
    double? latitude,
    double? longitude,
  }) {
    return NetworkInfoModel(
      wifiName: wifiName ?? this.wifiName,
      wifiIP: wifiIP ?? this.wifiIP,
      subnet: subnet ?? this.subnet,
      gateway: gateway ?? this.gateway,
      bssid: bssid ?? this.bssid,
      ipv6: ipv6 ?? this.ipv6,
      broadcast: broadcast ?? this.broadcast,
      wifiState: wifiState ?? this.wifiState,
      connectionType: connectionType ?? this.connectionType,
      localhost: localhost ?? this.localhost,
      publicIp: publicIp ?? this.publicIp,
      isp: isp ?? this.isp,
      organization: organization ?? this.organization,
      asn: asn ?? this.asn,
      timezone: timezone ?? this.timezone,
      city: city ?? this.city,
      region: region ?? this.region,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  /// Get formatted coordinates string (e.g. "9.9406, 76.2653")
  String? get coordinatesDisplay {
    if (latitude == null || longitude == null) return null;
    return 'Latitude: ${latitude!.toStringAsFixed(4)}\nLongitude: ${longitude!.toStringAsFixed(4)}';
  }

  /// Get CIDR prefix notation (e.g. "/24")
  String? get cidr {
    if (subnet == null || subnet!.isEmpty) return null;
    try {
      final parts = subnet!.split('.').map(int.parse).toList();
      if (parts.length != 4) return null;
      int bits = 0;
      for (final p in parts) {
        bits += p.toRadixString(2).replaceAll('0', '').length;
      }
      return '/$bits';
    } catch (_) {
      return null;
    }
  }

  /// Get Broadcast address if available or calculated from IP and subnet
  String? get resolvedBroadcast {
    if (broadcast != null && broadcast!.isNotEmpty && broadcast != 'null') {
      return broadcast;
    }
    if (wifiIP == null || subnet == null) return null;
    try {
      final ipParts = wifiIP!.split('.').map(int.parse).toList();
      final subParts = subnet!.split('.').map(int.parse).toList();
      if (ipParts.length != 4 || subParts.length != 4) return null;
      final bc = List.generate(4, (i) => (ipParts[i] | (~subParts[i] & 0xFF)));
      return bc.join('.');
    } catch (_) {
      return null;
    }
  }

  /// Get Usable IP range (e.g. "192.168.1.1 - 192.168.1.254")
  String? get ipRange {
    if (wifiIP == null || subnet == null) return null;
    try {
      final ipParts = wifiIP!.split('.').map(int.parse).toList();
      final subParts = subnet!.split('.').map(int.parse).toList();
      if (ipParts.length != 4 || subParts.length != 4) return null;
      final net = List.generate(4, (i) => (ipParts[i] & subParts[i]));
      final bc = List.generate(4, (i) => (ipParts[i] | (~subParts[i] & 0xFF)));

      final firstHost = [...net];
      firstHost[3] += 1;
      final lastHost = [...bc];
      lastHost[3] -= 1;

      return '${firstHost.join('.')} - ${lastHost.join('.')}';
    } catch (_) {
      return null;
    }
  }

  /// Get Total Usable Host Capacity
  String? get totalHosts {
    if (subnet == null || subnet!.isEmpty) return null;
    try {
      final parts = subnet!.split('.').map(int.parse).toList();
      if (parts.length != 4) return null;
      int bits = 0;
      for (final p in parts) {
        bits += p.toRadixString(2).replaceAll('0', '').length;
      }
      if (bits >= 31) return '2 Hosts';
      final hosts = (1 << (32 - bits)) - 2;
      return '$hosts Hosts';
    } catch (_) {
      return null;
    }
  }
}
