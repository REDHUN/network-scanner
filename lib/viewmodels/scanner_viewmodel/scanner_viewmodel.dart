import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ip_tools/models/network_model/network_info_model.dart';
import 'package:ip_tools/models/network_model/scan_settings.dart';
import 'package:ip_tools/models/network_model/scanned_device.dart';
import 'package:ip_tools/models/storage/router_network_data.dart';
import 'package:ip_tools/service/device_storage_service/device_storage_service.dart';
import 'package:ip_tools/service/network_scanner_service/network_scanner_service.dart';
import 'package:ip_tools/service/review_service/review_service.dart';

enum ScanState { idle, scanning, done, error }

class NetworkScannerProvider extends ChangeNotifier {
  final _scanner = NetworkScannerService();
  final _storageService = DeviceStorageService();

  ScanState state = ScanState.idle;
  final List<ScannedDevice> devices = [];
  final List<StoredDevice> offlineDevices = [];
  bool isFirstApiCall = true;

  // Real-time scan progress
  double progress = 0.0;
  int scannedCount = 0;
  int totalCount = 254;

  ScanSettings settings = const ScanSettings(
    firstHost: 1,
    lastHost: 254,
    pingTimeout: 1,
  );
  String? error;
  NetworkInfoModel? currentNetworkInfo;
  bool hasRouterChanged = false;

  StreamSubscription<NetworkScanProgressEvent>? _progressSub;

  /// Initialize with network info and check for router changes
  Future<void> initializeWithNetworkInfo(NetworkInfoModel networkInfo) async {
    currentNetworkInfo = networkInfo;
    hasRouterChanged = await _storageService.hasRouterChanged(networkInfo);

    if (hasRouterChanged) {
      // Router changed, load stored data for this router (if any)
      devices.clear();
      offlineDevices.clear();
      await _loadOfflineDevices();
      notifyListeners();
    } else {
      // Same router, load existing offline devices
      await _loadOfflineDevices();
    }
  }

  /// Load offline devices from storage
  Future<void> _loadOfflineDevices() async {
    try {
      final storedOfflineDevices = await _storageService.getOfflineDevices();
      offlineDevices.clear();
      offlineDevices.addAll(storedOfflineDevices);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading offline devices: $e');
    }
  }

  Future<void> startScan({bool fullScan = true}) async {
    if (state == ScanState.scanning) return;

    stopScan();

    state = ScanState.scanning;
    error = null;
    devices.clear();
    progress = 0.0;
    scannedCount = 0;
    totalCount = 254;
    notifyListeners();

    final scanSettings = fullScan
        ? const ScanSettings(firstHost: 1, lastHost: 254, pingTimeout: 1)
        : const ScanSettings(firstHost: 1, lastHost: 100, pingTimeout: 1);

    try {
      _progressSub = _scanner
          .scanWithProgress(scanSettings, networkInfo: currentNetworkInfo)
          .listen(
            (event) {
              progress = event.progress;
              scannedCount = event.scannedHosts;
              totalCount = event.totalHosts;

              if (event.foundDevice != null) {
                final newDev = event.foundDevice!;
                final index = devices.indexWhere((d) => d.ip == newDev.ip);
                if (index >= 0) {
                  // Enrich existing entry
                  devices[index] = devices[index].copyWith(
                    mac: newDev.mac ?? devices[index].mac,
                    name: (newDev.name != null && !newDev.name!.startsWith('Device ('))
                        ? newDev.name
                        : devices[index].name,
                    mdns: newDev.mdns ?? devices[index].mdns,
                    isSelf: newDev.isSelf || devices[index].isSelf,
                    isGateway: newDev.isGateway || devices[index].isGateway,
                  );
                } else {
                  devices.add(newDev);
                }
              }
              notifyListeners();
            },
            onError: (e) {
              error = e.toString();
              state = ScanState.error;
              notifyListeners();
            },
            onDone: () async {
              state = ScanState.done;
              progress = 1.0;

              if (currentNetworkInfo != null) {
                await _saveScanResults();
                await _loadOfflineDevices();
              }

              unawaited(ReviewService.instance.logScanAndCheckPrompt());
              notifyListeners();
            },
          );
    } catch (e) {
      error = e.toString();
      state = ScanState.error;
      notifyListeners();
    }
  }

  /// Save scan results to storage
  Future<void> _saveScanResults() async {
    if (currentNetworkInfo == null) return;

    try {
      await _storageService.saveDeviceData(currentNetworkInfo!, devices);
    } catch (e) {
      debugPrint('Error saving scan results: $e');
    }
  }

  /// Get all devices (online + offline)
  List<StoredDevice> getAllDevicesWithStatus() {
    final List<StoredDevice> allDevices = [];

    // Add online devices (from current scan)
    for (final device in devices) {
      allDevices.add(StoredDevice.fromScannedDevice(device));
    }

    // Add offline devices (from storage)
    allDevices.addAll(offlineDevices);

    // Remove duplicates (prefer online status)
    final Map<String, StoredDevice> deviceMap = {};
    for (final device in allDevices) {
      final existing = deviceMap[device.ip];
      if (existing == null || device.isOnline) {
        deviceMap[device.ip] = device;
      }
    }

    return deviceMap.values.toList();
  }

  /// Get device statistics
  int get totalDevicesCount => getAllDevicesWithStatus().length;
  int get onlineDevicesCount => devices.length;
  int get offlineDevicesCount => offlineDevices.length;

  /// Get online devices only
  List<StoredDevice> getOnlineDevices() {
    return devices
        .map((device) => StoredDevice.fromScannedDevice(device))
        .toList();
  }

  /// Get offline devices only
  List<StoredDevice> getOfflineDevices() {
    return offlineDevices;
  }

  /// Get all stored router networks
  Future<List<RouterNetworkData>> getAllRouterNetworks() async {
    return await _storageService.getAllRouterNetworks();
  }

  /// Switch to a specific router's history
  Future<void> switchToRouter(String routerId) async {
    try {
      final targetRouter = await _storageService.getRouterData(routerId);

      if (targetRouter != null) {
        devices.clear();
        offlineDevices.clear();

        // Categorize stored devices
        for (final device in targetRouter.devices) {
          if (device.isOnline) {
            // Convert to ScannedDevice for online list
            devices.add(
              ScannedDevice(
                ip: device.ip,
                mac: device.mac,
                name: device.name,
                mdns: device.mdns,
                isSelf: device.isSelf,
                isGateway: device.isGateway,
              ),
            );
          } else {
            offlineDevices.add(device);
          }
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error switching to router $routerId: $e');
    }
  }

  /// Get current router info
  Future<String?> getCurrentRouterId() async {
    return await _storageService.getCurrentRouterId();
  }

  /// Delete specific router data
  Future<void> deleteRouterData(String routerId) async {
    try {
      await _storageService.deleteRouterData(routerId);

      // If we deleted the current router, clear current devices
      final currentRouterId = await _storageService.getCurrentRouterId();
      if (currentRouterId == null || currentRouterId == routerId) {
        devices.clear();
      }
    } catch (e) {
      debugPrint('Error deleting router data: $e');
      rethrow;
    }
  }

  /// Delete an individual offline device
  Future<void> deleteOfflineDevice(String ip) async {
    try {
      await _storageService.deleteOfflineDevice(ip);
      offlineDevices.removeWhere((d) => d.ip == ip);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting offline device: $e');
    }
  }

  void stopScan() {
    _progressSub?.cancel();
    _progressSub = null;
    state = ScanState.done;
    notifyListeners();
  }

  void resetScan() {
    _progressSub?.cancel();
    _progressSub = null;
    state = ScanState.idle;
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }
}
