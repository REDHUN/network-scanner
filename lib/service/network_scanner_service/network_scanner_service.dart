import 'dart:async';
import 'dart:io';

import 'package:flutter_network_scanner/flutter_network_scanner.dart'
    hide NetworkInfoModel;
import 'package:ip_tools/models/network_model/network_info_model.dart';
import 'package:ip_tools/models/network_model/scan_settings.dart';
import 'package:ip_tools/models/network_model/scanned_device.dart';

class NetworkScanProgressEvent {
  final double progress; // 0.0 to 1.0
  final int scannedHosts;
  final int totalHosts;
  final ScannedDevice? foundDevice;
  final bool isComplete;

  NetworkScanProgressEvent({
    required this.progress,
    required this.scannedHosts,
    required this.totalHosts,
    this.foundDevice,
    this.isComplete = false,
  });
}

class NetworkScannerService {
  static final NetworkScannerService _instance =
      NetworkScannerService._internal();
  factory NetworkScannerService() => _instance;
  NetworkScannerService._internal();

  /// Real-time streaming scan with fine-grained progress reporting
  Stream<NetworkScanProgressEvent> scanWithProgress(
    ScanSettings settings, {
    NetworkInfoModel? networkInfo,
  }) {
    late StreamController<NetworkScanProgressEvent> controller;

    controller = StreamController<NetworkScanProgressEvent>(
      onListen: () async {
        final netInfo = networkInfo ?? await _resolveNetworkInfo();
        final localIp = netInfo?.wifiIP ?? '192.168.1.2';
        final gatewayIp = netInfo?.gateway ?? '192.168.1.1';

        final parts = localIp.split('.');
        if (parts.length != 4) {
          controller.add(NetworkScanProgressEvent(
            progress: 1.0,
            scannedHosts: 0,
            totalHosts: 0,
            isComplete: true,
          ));
          await controller.close();
          return;
        }

        final subnetPrefix = '${parts[0]}.${parts[1]}.${parts[2]}';
        final firstHost = settings.firstHost.clamp(1, 254);
        final lastHost = settings.lastHost.clamp(firstHost, 254);
        final totalHosts = lastHost - firstHost + 1;

        final knownDevices = <String, ScannedDevice>{};
        int scannedCount = 0;

        // 1. Immediately add Self device and Gateway device if in range
        final selfDevice = ScannedDevice(
          ip: localIp,
          name: 'This Device',
          isSelf: true,
          isGateway: false,
        );
        knownDevices[localIp] = selfDevice;
        controller.add(NetworkScanProgressEvent(
          progress: 0.02,
          scannedHosts: 0,
          totalHosts: totalHosts,
          foundDevice: selfDevice,
        ));

        if (gatewayIp.startsWith(subnetPrefix)) {
          final gwDevice = ScannedDevice(
            ip: gatewayIp,
            name: 'Router / Gateway',
            isSelf: false,
            isGateway: true,
          );
          knownDevices[gatewayIp] = gwDevice;
          controller.add(NetworkScanProgressEvent(
            progress: 0.04,
            scannedHosts: 0,
            totalHosts: totalHosts,
            foundDevice: gwDevice,
          ));
        }

        // 2. Start native ARP/ICMP scan in background to resolve MACs & vendors
        final nativeScanFuture = FlutterNetworkScanner.scanNetwork(
          timeoutMs: settings.pingTimeout > 0 ? settings.pingTimeout * 250 : 250,
        ).catchError((_) => <DiscoveredDevice>[]);

        // 3. Concurrently run bounded worker pool across the subnet
        final hostList = List.generate(
          totalHosts,
          (index) => firstHost + index,
        );
        int nextIndex = 0;
        final concurrency = 25.clamp(1, totalHosts);

        Future<void> runWorker() async {
          while (true) {
            if (controller.isClosed) break;

            int hostNum;
            if (nextIndex >= hostList.length) break;
            hostNum = hostList[nextIndex++];

            final targetIp = '$subnetPrefix.$hostNum';
            ScannedDevice? discoveredDevice;

            if (targetIp == localIp) {
              discoveredDevice = selfDevice;
            } else if (targetIp == gatewayIp) {
              discoveredDevice = knownDevices[gatewayIp];
            } else {
              final isAlive = await _probeHost(targetIp);
              if (isAlive) {
                String? hostname;
                try {
                  final lookup = await InternetAddress(targetIp)
                      .reverse()
                      .timeout(const Duration(milliseconds: 150));
                  if (lookup.host.isNotEmpty && lookup.host != targetIp) {
                    hostname = lookup.host;
                  }
                } catch (_) {}

                discoveredDevice = ScannedDevice(
                  ip: targetIp,
                  name: hostname ?? 'Device ($targetIp)',
                  isSelf: false,
                  isGateway: false,
                );
              }
            }

            scannedCount++;
            if (!controller.isClosed) {
              if (discoveredDevice != null && !knownDevices.containsKey(discoveredDevice.ip)) {
                knownDevices[discoveredDevice.ip] = discoveredDevice;
              }

              final progress = (scannedCount / totalHosts).clamp(0.0, 0.95);
              controller.add(NetworkScanProgressEvent(
                progress: progress,
                scannedHosts: scannedCount,
                totalHosts: totalHosts,
                foundDevice: discoveredDevice,
              ));
            }
          }
        }

        final workers = List.generate(concurrency, (_) => runWorker());
        await Future.wait(workers);

        // 4. Merge results from native ARP/MAC scan
        try {
          final nativeDevices = await nativeScanFuture;
          for (final nd in nativeDevices) {
            final existing = knownDevices[nd.ip];
            final enriched = ScannedDevice(
              ip: nd.ip,
              mac: nd.mac ?? existing?.mac,
              name: nd.hostname ?? nd.vendor ?? existing?.name,
              mdns: nd.hostname ?? existing?.mdns,
              isSelf: nd.isCurrentDevice || (existing?.isSelf ?? false),
              isGateway: nd.isGateway || (existing?.isGateway ?? false),
            );

            knownDevices[nd.ip] = enriched;
            if (!controller.isClosed) {
              controller.add(NetworkScanProgressEvent(
                progress: 0.98,
                scannedHosts: totalHosts,
                totalHosts: totalHosts,
                foundDevice: enriched,
              ));
            }
          }
        } catch (_) {}

        if (!controller.isClosed) {
          controller.add(NetworkScanProgressEvent(
            progress: 1.0,
            scannedHosts: totalHosts,
            totalHosts: totalHosts,
            isComplete: true,
          ));
          await controller.close();
        }
      },
    );

    return controller.stream;
  }

  /// Fast probe to test if a host is active on the network
  Future<bool> _probeHost(String ip) async {
    const probePorts = [80, 443, 22, 53, 445, 135, 8080, 8008, 9100, 62078, 5000, 3000];
    for (final port in probePorts) {
      try {
        final socket = await Socket.connect(
          ip,
          port,
          timeout: const Duration(milliseconds: 160),
        );
        socket.destroy();
        return true;
      } on SocketException catch (e) {
        // If connection was actively refused by the target (RST packet), host is UP!
        final msg = e.osError?.message.toLowerCase() ?? e.message.toLowerCase();
        if (msg.contains('refused') || msg.contains('reset') || e.osError?.errorCode == 111 || e.osError?.errorCode == 10061) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  Future<NetworkInfoModel?> _resolveNetworkInfo() async {
    try {
      final nativeInfo = await FlutterNetworkScanner.getNetworkInfo();
      if (nativeInfo != null) {
        return NetworkInfoModel(
          wifiIP: nativeInfo.ip,
          subnet: nativeInfo.subnet,
          gateway: nativeInfo.gateway,
          wifiName: nativeInfo.ssid,
        );
      }
    } catch (_) {}
    return null;
  }

  /// Backward-compatible scan stream
  Stream<ScannedDevice> scan(ScanSettings settings) async* {
    final seenIps = <String>{};
    await for (final event in scanWithProgress(settings)) {
      if (event.foundDevice != null && !seenIps.contains(event.foundDevice!.ip)) {
        seenIps.add(event.foundDevice!.ip);
        yield event.foundDevice!;
      }
    }
  }
}
