import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'flutter_network_scanner_platform_interface.dart';
import 'models/discovered_device.dart';
import 'models/network_info_model.dart';

class MethodChannelFlutterNetworkScanner extends FlutterNetworkScannerPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_network_scanner');

  @override
  Future<List<DiscoveredDevice>> scanNetwork({int timeoutMs = 250}) async {
    try {
      final List<dynamic>? rawList = await methodChannel.invokeListMethod<dynamic>(
        'scanNetwork',
        {'timeoutMs': timeoutMs},
      );
      if (rawList == null) return [];
      return rawList
          .map((item) => DiscoveredDevice.fromMap(item as Map<dynamic, dynamic>))
          .toList();
    } on PlatformException catch (e) {
      debugPrint('PlatformException in scanNetwork: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<NetworkInfoModel?> getNetworkInfo() async {
    try {
      final Map<dynamic, dynamic>? map =
          await methodChannel.invokeMethod<Map<dynamic, dynamic>>('getNetworkInfo');
      if (map == null) return null;
      return NetworkInfoModel.fromMap(map);
    } catch (e) {
      debugPrint('Error in getNetworkInfo: $e');
      return null;
    }
  }

  @override
  Future<int> pingHost(String ip, {int timeoutMs = 500}) async {
    try {
      final int? ping = await methodChannel.invokeMethod<int>(
        'pingHost',
        {'ip': ip, 'timeoutMs': timeoutMs},
      );
      return ping ?? -1;
    } catch (e) {
      debugPrint('Error in pingHost: $e');
      return -1;
    }
  }

  @override
  Future<List<int>> scanPorts(String ip, {List<int>? ports, int timeoutMs = 300}) async {
    try {
      final List<dynamic>? result = await methodChannel.invokeListMethod<dynamic>(
        'scanPorts',
        {
          'ip': ip,
          'ports': ports ?? [80, 443, 22, 21, 8080, 445, 53, 3389, 8008, 9100],
          'timeoutMs': timeoutMs,
        },
      );
      if (result == null) return [];
      return result.map((e) => (e as num).toInt()).toList();
    } catch (e) {
      debugPrint('Error in scanPorts: $e');
      return [];
    }
  }
}
