import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'flutter_network_scanner_method_channel.dart';
import 'models/discovered_device.dart';
import 'models/network_info_model.dart';

abstract class FlutterNetworkScannerPlatform extends PlatformInterface {
  FlutterNetworkScannerPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterNetworkScannerPlatform _instance = MethodChannelFlutterNetworkScanner();

  static FlutterNetworkScannerPlatform get instance => _instance;

  static set instance(FlutterNetworkScannerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<List<DiscoveredDevice>> scanNetwork({int timeoutMs = 250}) {
    throw UnimplementedError('scanNetwork() has not been implemented.');
  }

  Future<NetworkInfoModel?> getNetworkInfo() {
    throw UnimplementedError('getNetworkInfo() has not been implemented.');
  }

  Future<int> pingHost(String ip, {int timeoutMs = 500}) {
    throw UnimplementedError('pingHost() has not been implemented.');
  }

  Future<List<int>> scanPorts(String ip, {List<int>? ports, int timeoutMs = 300}) {
    throw UnimplementedError('scanPorts() has not been implemented.');
  }
}
