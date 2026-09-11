import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_network_scanner/flutter_network_scanner.dart';
import 'package:flutter_network_scanner/src/flutter_network_scanner_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterNetworkScannerPlatform
    with MockPlatformInterfaceMixin
    implements FlutterNetworkScannerPlatform {
  @override
  Future<List<DiscoveredDevice>> scanNetwork({int timeoutMs = 250}) async {
    return [
      const DiscoveredDevice(
        ip: '192.168.1.1',
        hostname: 'Router.local',
        isGateway: true,
        openPorts: [80, 443, 53],
        pingMs: 2,
        deviceType: 'router',
      ),
      const DiscoveredDevice(
        ip: '192.168.1.25',
        hostname: 'Smart-TV',
        openPorts: [8008],
        pingMs: 12,
        deviceType: 'smart_tv',
      ),
    ];
  }

  @override
  Future<NetworkInfoModel?> getNetworkInfo() async {
    return const NetworkInfoModel(
      ip: '192.168.1.100',
      subnet: '255.255.255.0',
      gateway: '192.168.1.1',
      ssid: 'Home_WiFi',
      ifaceName: 'wlan0',
    );
  }

  @override
  Future<int> pingHost(String ip, {int timeoutMs = 500}) async {
    return 15;
  }

  @override
  Future<List<int>> scanPorts(String ip, {List<int>? ports, int timeoutMs = 300}) async {
    return [80, 443];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('scanNetwork returns mocked devices', () async {
    final mockPlatform = MockFlutterNetworkScannerPlatform();
    FlutterNetworkScannerPlatform.instance = mockPlatform;

    final devices = await FlutterNetworkScanner.scanNetwork();
    expect(devices.length, 2);
    expect(devices.first.ip, '192.168.1.1');
    expect(devices.first.isGateway, true);
    expect(devices.first.displayName, 'Router.local');
    expect(devices.first.openPorts, contains(80));
  });

  test('getNetworkInfo returns network details', () async {
    final mockPlatform = MockFlutterNetworkScannerPlatform();
    FlutterNetworkScannerPlatform.instance = mockPlatform;

    final info = await FlutterNetworkScanner.getNetworkInfo();
    expect(info, isNotNull);
    expect(info!.ip, '192.168.1.100');
    expect(info.gateway, '192.168.1.1');
    expect(info.ssid, 'Home_WiFi');
  });

  test('pingHost returns latency', () async {
    final mockPlatform = MockFlutterNetworkScannerPlatform();
    FlutterNetworkScannerPlatform.instance = mockPlatform;

    final ping = await FlutterNetworkScanner.pingHost('192.168.1.1');
    expect(ping, 15);
  });

  test('scanPorts returns open ports', () async {
    final mockPlatform = MockFlutterNetworkScannerPlatform();
    FlutterNetworkScannerPlatform.instance = mockPlatform;

    final openPorts = await FlutterNetworkScanner.scanPorts('192.168.1.1');
    expect(openPorts, [80, 443]);
  });
}
