import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:jaal/models/network_model/network_info_model.dart';
import 'package:jaal/models/network_model/scan_settings.dart';
import 'package:jaal/models/network_model/scanned_device.dart';
import 'package:jaal/models/storage/router_network_data.dart';
import 'package:jaal/service/device_storage_service/device_storage_service.dart';
import 'package:jaal/service/network_scanner_service/network_scanner_service.dart';

enum ScanState { idle, scanning, done, error }

class NetworkScannerProvider extends ChangeNotifier {
  final _scanner = NetworkScannerService();
  final _storageService = DeviceStorageService();

  ScanState state = ScanState.idle;
  final List<ScannedDevice> devices = [];
  final List<StoredDevice> offlineDevices = [];
  bool isFirstApiCall = true;
  ScanSettings settings = const ScanSettings(
    firstHost: 1,
    lastHost: 50, // Reduce initial scan range for better performance
    pingTimeout: 1,
  );
  String? error;
  NetworkInfoModel? currentNetworkInfo;
  bool hasRouterChanged = false;

  StreamSubscription<ScannedDevice>? _sub;

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

  Future<void> startScan({bool fullScan = false}) async {
    if (state == ScanState.scanning) return;

    stopScan();

    state = ScanState.scanning;
    error = null;
    devices.clear();
    notifyListeners();

    // Use different settings based on scan type
    final scanSettings = fullScan
        ? const ScanSettings(firstHost: 1, lastHost: 254, pingTimeout: 1)
        : const ScanSettings(firstHost: 1, lastHost: 50, pingTimeout: 1);

    // Start scanning asynchronously to prevent UI blocking
    try {
      _sub = _scanner
          .scan(scanSettings)
          .listen(
            (device) {
              if (!devices.any((d) => d.ip == device.ip)) {
                devices.add(device);
                notifyListeners();
              }
            },
            onError: (e) {
              error = e.toString();
              state = ScanState.error;
              notifyListeners();
            },
            onDone: () async {
              state = ScanState.done;

              // Save scan results to storage if we have network info
              if (currentNetworkInfo != null) {
                await _saveScanResults();
                await _loadOfflineDevices(); // Refresh offline devices
              }

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
  Future<Map<String, int>> getDeviceStats() async {
    return await _storageService.getDeviceStats();
  }

  /// Get only online devices
  List<ScannedDevice> getOnlineDevices() {
    return devices;
  }

  /// Get only offline devices
  List<StoredDevice> getOfflineDevices() {
    return offlineDevices;
  }

  /// Get recently offline devices (within 24 hours)
  Future<List<StoredDevice>> getRecentlyOfflineDevices() async {
    return await _storageService.getRecentlyOfflineDevices();
  }

  /// Clear all stored data
  Future<void> clearStoredData() async {
    await _storageService.clearAllData();
    offlineDevices.clear();
    notifyListeners();
  }

  /// Get all router networks
  Future<List<RouterNetworkData>> getAllRouterNetworks() async {
    return await _storageService.getAllRouterNetworks();
  }

  /// Get router summary with statistics
  Future<Map<String, dynamic>> getRouterSummary() async {
    return await _storageService.getRouterSummary();
  }

  /// Switch to a different router's data (for viewing historical data)
  Future<void> switchToRouter(String routerId) async {
    try {
      final routerData = await _storageService.getRouterData(routerId);
      if (routerData != null) {
        // Load devices from the selected router
        devices.clear();
        offlineDevices.clear();
        
        // Separate online and offline devices
        for (final device in routerData.devices) {
          if (device.isOnline) {
            devices.add(device.toScannedDevice());
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
        offlineDevices.clear();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting router data: $e');
      rethrow;
    }
  }

  void stopScan() {
    _sub?.cancel();
    state = ScanState.done;
    notifyListeners();
  }

  void resetScan() {
    _sub?.cancel();
    state = ScanState.idle;
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
