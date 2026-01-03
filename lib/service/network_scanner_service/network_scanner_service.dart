import 'dart:async';
import 'package:netra/models/network_model/scan_settings.dart';
import 'package:netra/models/network_model/scanned_device.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:network_tools/network_tools.dart';


class NetworkScannerService {
  static final NetworkScannerService _instance =
  NetworkScannerService._internal();
  factory NetworkScannerService() => _instance;
  NetworkScannerService._internal();

  /// Get local IP, gateway and subnet
  Future<_NetInfo?> _getNetInfo() async {
    final info = NetworkInfo();
    final ip = await info.getWifiIP();
    if (ip == null) return null;

    final subnet = ip.substring(0, ip.lastIndexOf('.'));
    final gateway = await info.getWifiGatewayIP() ?? '$subnet.1';

    return _NetInfo(ip, gateway, subnet);
  }

  /// MAIN SCAN STREAM
  Stream<ScannedDevice> scan(ScanSettings settings) async* {
    final net = await _getNetInfo();
    if (net == null) throw Exception('No Wi-Fi connection');

    /// Phase 1: Ping discovery (MOST IMPORTANT)
    final pingStream =
    HostScannerService.instance.getAllPingableDevices(
      net.subnet,
      firstHostId: settings.firstHost,
      lastHostId: settings.lastHost,
      timeoutInSeconds: settings.pingTimeout,
    );

    await for (final host in pingStream) {
      yield await _mapHost(host, net);
    }

    /// Phase 2: mDNS discovery
    final mdnsHosts =
    await MdnsScannerService.instance.searchMdnsDevices();

    for (final host in mdnsHosts) {
      yield await _mapHost(host, net);
    }
  }

  /// Convert ActiveHost → ScannedDevice
  Future<ScannedDevice> _mapHost(
      ActiveHost host,
      _NetInfo net,
      ) async {
    final ip = host.internetAddress.address;




    return ScannedDevice(

      ip: ip,
      mac: (await host.arpData)?.macAddress,
      name: await host.deviceName,
      mdns: (await host.mdnsInfo)?.mdnsName,
      isSelf: ip == net.ip,
      isGateway: ip == net.gateway,
    );
  }
}

class _NetInfo {
  final String ip;
  final String gateway;
  final String subnet;

  _NetInfo(this.ip, this.gateway, this.subnet);
}
