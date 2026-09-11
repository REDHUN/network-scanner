library flutter_network_scanner;

import 'src/flutter_network_scanner_platform_interface.dart';
import 'src/models/discovered_device.dart';
import 'src/models/network_info_model.dart';

export 'src/models/discovered_device.dart';
export 'src/models/network_info_model.dart';

/// Flutter interface for scanning local network devices, testing latency,
/// and probing network ports.
class FlutterNetworkScanner {
  /// Scans the local /24 subnet and returns all discovered responsive devices.
  static Future<List<DiscoveredDevice>> scanNetwork({int timeoutMs = 250}) {
    return FlutterNetworkScannerPlatform.instance.scanNetwork(timeoutMs: timeoutMs);
  }

  /// Retrieves current connection info (Local IP, subnet, gateway, SSID).
  static Future<NetworkInfoModel?> getNetworkInfo() {
    return FlutterNetworkScannerPlatform.instance.getNetworkInfo();
  }

  /// Measures roundtrip ping latency to a specific IP address in milliseconds.
  static Future<int> pingHost(String ip, {int timeoutMs = 500}) {
    return FlutterNetworkScannerPlatform.instance.pingHost(ip, timeoutMs: timeoutMs);
  }

  /// Performs a targeted TCP port scan on a specific IP.
  static Future<List<int>> scanPorts(
    String ip, {
    List<int>? ports,
    int timeoutMs = 300,
  }) {
    return FlutterNetworkScannerPlatform.instance.scanPorts(
      ip,
      ports: ports,
      timeoutMs: timeoutMs,
    );
  }
}
