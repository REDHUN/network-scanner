/// Local network interface and connection details.
class NetworkInfoModel {
  final String ip;
  final String subnet;
  final String? gateway;
  final String? ifaceName;
  final String? ssid;

  const NetworkInfoModel({
    required this.ip,
    required this.subnet,
    this.gateway,
    this.ifaceName,
    this.ssid,
  });

  factory NetworkInfoModel.fromMap(Map<dynamic, dynamic> map) {
    return NetworkInfoModel(
      ip: (map['ip'] as String?) ?? '127.0.0.1',
      subnet: (map['subnet'] as String?) ?? '255.255.255.0',
      gateway: map['gateway'] as String?,
      ifaceName: map['interface'] as String?,
      ssid: map['ssid'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ip': ip,
      'subnet': subnet,
      'gateway': gateway,
      'interface': ifaceName,
      'ssid': ssid,
    };
  }
}
