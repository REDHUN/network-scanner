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
    var cancelled = false;

    controller = StreamController<NetworkScanProgressEvent>(
      onListen: () async {
        final netInfo = networkInfo ?? await _resolveNetworkInfo();
        if (cancelled) return;

        // Native scanning is the authoritative path on mobile. It already performs the
        // subnet sweep, so starting Dart probes here would double the network traffic.
        // The package scans the complete active subnet, so use it only for the
        // complete scan mode; partial ranges retain the Dart implementation's
        // range semantics.
        if ((Platform.isAndroid || Platform.isIOS) &&
            settings.firstHost == 1 &&
            settings.lastHost == 254) {
          try {
            await _scanWithNativePackage(
              controller,
              settings,
              netInfo,
              cancelled: () => cancelled,
            );
            return;
          } catch (_) {
            // A missing/failed native implementation falls back to the existing Dart
            // worker path below. This also keeps the service usable during plugin rollout.
          }
        }

        final localIp = netInfo?.wifiIP;
        final gatewayIp = netInfo?.gateway ?? '';
        final parts = localIp?.split('.') ?? const <String>[];
        if (localIp == null ||
            parts.length != 4 ||
            parts.any((part) => int.tryParse(part) == null)) {
          controller.add(
            NetworkScanProgressEvent(
              progress: 1.0,
              scannedHosts: 0,
              totalHosts: 0,
              isComplete: true,
            ),
          );
          await controller.close();
          return;
        }

        final resolvedLocalIp = localIp;

        final subnetPrefix = '${parts[0]}.${parts[1]}.${parts[2]}';
        final firstHost = settings.firstHost.clamp(1, 254).toInt();
        final lastHost = settings.lastHost.clamp(firstHost, 254).toInt();
        final totalHosts = lastHost - firstHost + 1;

        await _scanWithDartWorkers(
          controller,
          settings,
          resolvedLocalIp,
          gatewayIp,
          subnetPrefix,
          firstHost,
          lastHost,
          totalHosts,
          cancelled: () => cancelled,
        );
      },
      onCancel: () {
        cancelled = true;
      },
    );

    return controller.stream;
  }

  Future<void> _scanWithNativePackage(
    StreamController<NetworkScanProgressEvent> controller,
    ScanSettings settings,
    NetworkInfoModel? netInfo, {
    required bool Function() cancelled,
  }) async {
    final localIp = netInfo?.wifiIP;
    final gatewayIp = netInfo?.gateway;
    final timeoutMs =
        (settings.pingTimeout > 0 ? settings.pingTimeout * 250 : 250)
            .clamp(1, 10000)
            .toInt();
    final totalHosts = _hostCountFromNetworkInfo(netInfo) ?? 254;
    controller.add(
      NetworkScanProgressEvent(
        // Native scanning returns one final MethodChannel result rather than
        // streaming every host probe. Start above zero so the UI does not look
        // frozen while the native sweep is running.
        progress: 0.01,
        scannedHosts: 0,
        totalHosts: totalHosts,
      ),
    );

    // Keep the progress indicator useful during the native sweep. The native
    // scanner has a 20-second safety deadline, so this is deliberately an
    // estimate and is capped below completion until the real result arrives.
    final startedAt = Stopwatch()..start();
    final progressTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (cancelled() || controller.isClosed) return;
      final estimatedProgress =
          (startedAt.elapsedMilliseconds / 20000 * 0.89 + 0.01).clamp(
            0.01,
            0.90,
          ).toDouble();
      final estimatedScanned = (totalHosts * estimatedProgress).floor().clamp(
        0,
        totalHosts - 1,
      ).toInt();
      controller.add(
        NetworkScanProgressEvent(
          progress: estimatedProgress,
          scannedHosts: estimatedScanned,
          totalHosts: totalHosts,
        ),
      );
    });

    late final List<DiscoveredDevice> nativeDevices;
    try {
      nativeDevices = await FlutterNetworkScanner.scanNetwork(
        timeoutMs: timeoutMs,
      );
    } finally {
      progressTimer.cancel();
      startedAt.stop();
    }
    if (cancelled() || controller.isClosed) return;

    final seen = <String>{};
    var scannedHosts = 0;

    for (final nativeDevice in nativeDevices) {
      if (cancelled() || controller.isClosed) return;
      if (!seen.add(nativeDevice.ip)) continue;
      final device = ScannedDevice(
        ip: nativeDevice.ip,
        mac: nativeDevice.mac,
        name: nativeDevice.hostname ?? nativeDevice.vendor,
        mdns: nativeDevice.hostname,
        isSelf: nativeDevice.isCurrentDevice || nativeDevice.ip == localIp,
        isGateway: nativeDevice.isGateway || nativeDevice.ip == gatewayIp,
      );
      scannedHosts++;
      controller.add(
        NetworkScanProgressEvent(
          progress: (scannedHosts / (totalHosts == 0 ? 1 : totalHosts)).clamp(
            0.05,
            0.98,
          ),
          scannedHosts: scannedHosts,
          totalHosts: totalHosts,
          foundDevice: device,
        ),
      );
    }

    if (!cancelled() && !controller.isClosed) {
      controller.add(
        NetworkScanProgressEvent(
          progress: 1.0,
          scannedHosts: totalHosts,
          totalHosts: totalHosts,
          isComplete: true,
        ),
      );
      await controller.close();
    }
  }

  int? _hostCountFromNetworkInfo(NetworkInfoModel? info) {
    final ip = info?.wifiIP;
    final subnet = info?.subnet;
    if (ip == null || subnet == null) return null;

    final ipParts = ip.split('.').map(int.tryParse).toList();
    final maskParts = subnet.split('.').map(int.tryParse).toList();
    if (ipParts.length != 4 ||
        maskParts.length != 4 ||
        ipParts.any((part) => part == null || part < 0 || part > 255) ||
        maskParts.any((part) => part == null || part < 0 || part > 255)) {
      return null;
    }

    var prefix = 0;
    var sawZero = false;
    for (final part in maskParts.cast<int>()) {
      final bits = part.toRadixString(2).padLeft(8, '0');
      for (final bit in bits.split('')) {
        if (bit == '1') {
          if (sawZero) return null;
          prefix++;
        } else {
          sawZero = true;
        }
      }
    }

    if (prefix >= 31) return 2;
    final hostCount = (1 << (32 - prefix)) - 2;
    return hostCount > 0 ? hostCount : null;
  }

  Future<void> _scanWithDartWorkers(
    StreamController<NetworkScanProgressEvent> controller,
    ScanSettings settings,
    String localIp,
    String gatewayIp,
    String subnetPrefix,
    int firstHost,
    int lastHost,
    int totalHosts, {
    required bool Function() cancelled,
  }) async {
    // Immediately add Self device and Gateway device if in range.
    final knownDevices = <String, ScannedDevice>{};
    var scannedCount = 0;
    final selfDevice = ScannedDevice(
      ip: localIp,
      name: 'This Device',
      isSelf: true,
      isGateway: false,
    );
    knownDevices[localIp] = selfDevice;
    controller.add(
      NetworkScanProgressEvent(
        progress: 0.02,
        scannedHosts: 0,
        totalHosts: totalHosts,
        foundDevice: selfDevice,
      ),
    );

    if (gatewayIp.startsWith(subnetPrefix)) {
      final gwDevice = ScannedDevice(
        ip: gatewayIp,
        name: 'Router / Gateway',
        isSelf: false,
        isGateway: true,
      );
      knownDevices[gatewayIp] = gwDevice;
      controller.add(
        NetworkScanProgressEvent(
          progress: 0.04,
          scannedHosts: 0,
          totalHosts: totalHosts,
          foundDevice: gwDevice,
        ),
      );
    }

    // Run a bounded worker pool across the subnet as the portable fallback.
    final hostList = List.generate(totalHosts, (index) => firstHost + index);
    int nextIndex = 0;
    final concurrency = 25.clamp(1, totalHosts).toInt();

    Future<void> runWorker() async {
      while (true) {
        if (controller.isClosed || cancelled()) break;

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
              final lookup = await InternetAddress(
                targetIp,
              ).reverse().timeout(const Duration(milliseconds: 150));
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
          if (discoveredDevice != null &&
              !knownDevices.containsKey(discoveredDevice.ip)) {
            knownDevices[discoveredDevice.ip] = discoveredDevice;
          }

          final progress = (scannedCount / totalHosts).clamp(0.0, 0.95);
          controller.add(
            NetworkScanProgressEvent(
              progress: progress,
              scannedHosts: scannedCount,
              totalHosts: totalHosts,
              foundDevice: discoveredDevice,
            ),
          );
        }
      }
    }

    final workers = List.generate(concurrency, (_) => runWorker());
    await Future.wait(workers);

    if (!controller.isClosed && !cancelled()) {
      controller.add(
        NetworkScanProgressEvent(
          progress: 1.0,
          scannedHosts: totalHosts,
          totalHosts: totalHosts,
          isComplete: true,
        ),
      );
      await controller.close();
    }
  }

  /// Fast probe to test if a host is active on the network
  Future<bool> _probeHost(String ip) async {
    const probePorts = [
      80,
      443,
      22,
      53,
      445,
      135,
      8080,
      8008,
      9100,
      62078,
      5000,
      3000,
    ];
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
        if (msg.contains('refused') ||
            msg.contains('reset') ||
            e.osError?.errorCode == 111 ||
            e.osError?.errorCode == 10061) {
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
      if (event.foundDevice != null &&
          !seenIps.contains(event.foundDevice!.ip)) {
        seenIps.add(event.foundDevice!.ip);
        yield event.foundDevice!;
      }
    }
  }
}
