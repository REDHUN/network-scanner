import 'dart:convert';
import 'dart:developer';

import 'package:jaal/models/network_model/network_info_model.dart';
import 'package:jaal/models/network_model/scanned_device.dart';
import 'package:jaal/models/storage/router_network_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceStorageService {
  static const String _storageKey = 'router_network_data';
  static const String _currentRouterKey = 'current_router_id';

  /// Generate a unique router ID based on gateway IP and WiFi name
  String generateRouterId(NetworkInfoModel networkInfo) {
    final gateway = networkInfo.gateway ?? 'unknown_gateway';
    final wifiName = networkInfo.wifiName ?? 'unknown_wifi';
    return '${gateway}_$wifiName';
  }

  /// Get current router ID from storage
  Future<String?> getCurrentRouterId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_currentRouterKey);
    } catch (e) {
      log('Error getting current router ID: $e');
      return null;
    }
  }

  /// Set current router ID
  Future<void> setCurrentRouterId(String routerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentRouterKey, routerId);
    } catch (e) {
      log('Error setting current router ID: $e');
    }
  }

  /// Check if router has changed and handle setup
  Future<bool> hasRouterChanged(NetworkInfoModel networkInfo) async {
    final newRouterId = generateRouterId(networkInfo);
    final currentRouterId = await getCurrentRouterId();

    if (currentRouterId == null) {
      // First time setup
      await setCurrentRouterId(newRouterId);
      return false;
    }

    if (currentRouterId != newRouterId) {
      // Router changed - just switch to new router (keep old data)
      await setCurrentRouterId(newRouterId);
      return true;
    }

    return false;
  }

  /// Get all router data from storage
  Future<Map<String, RouterNetworkData>> _getAllRouterData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null) return {};

      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final Map<String, RouterNetworkData> result = {};

      for (final entry in jsonData.entries) {
        try {
          result[entry.key] = RouterNetworkData.fromJson(entry.value);
        } catch (e) {
          log('Error parsing router data for ${entry.key}: $e');
        }
      }

      return result;
    } catch (e) {
      log('Error getting all router data: $e');
      return {};
    }
  }

  /// Save all router data to storage
  Future<void> _saveAllRouterData(Map<String, RouterNetworkData> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> jsonData = {};

      for (final entry in data.entries) {
        jsonData[entry.key] = entry.value.toJson();
      }

      await prefs.setString(_storageKey, json.encode(jsonData));
    } catch (e) {
      log('Error saving all router data: $e');
    }
  }

  /// Get stored data for current router
  Future<RouterNetworkData?> getCurrentRouterData() async {
    try {
      final currentRouterId = await getCurrentRouterId();
      if (currentRouterId == null) return null;

      final allData = await _getAllRouterData();
      return allData[currentRouterId];
    } catch (e) {
      log('Error getting current router data: $e');
      return null;
    }
  }

  /// Save/update device data for current router
  Future<void> saveDeviceData(
    NetworkInfoModel networkInfo,
    List<ScannedDevice> scannedDevices,
  ) async {
    try {
      final routerId = generateRouterId(networkInfo);
      final allData = await _getAllRouterData();
      final existingData = allData[routerId];
      final now = DateTime.now();

      // Convert scanned devices to stored devices
      final Map<String, StoredDevice> newDevicesMap = {};
      for (final device in scannedDevices) {
        newDevicesMap[device.ip] = StoredDevice.fromScannedDevice(
          device,
          timestamp: now,
        );
      }

      List<StoredDevice> finalDevices;

      if (existingData != null) {
        // Merge with existing data
        final Map<String, StoredDevice> existingDevicesMap = {
          for (final device in existingData.devices) device.ip: device,
        };

        finalDevices = [];

        // Process all devices (existing and new)
        final allIps = {...existingDevicesMap.keys, ...newDevicesMap.keys};

        for (final ip in allIps) {
          final existingDevice = existingDevicesMap[ip];
          final newDevice = newDevicesMap[ip];

          if (newDevice != null) {
            // Device is currently online
            if (existingDevice != null) {
              // Update existing device
              finalDevices.add(
                existingDevice.copyWith(
                  lastSeen: now,
                  isOnline: true,
                  // Update device info if it has changed
                  mac: newDevice.mac ?? existingDevice.mac,
                  name: newDevice.name ?? existingDevice.name,
                  mdns: newDevice.mdns ?? existingDevice.mdns,
                ),
              );
            } else {
              // New device
              finalDevices.add(newDevice);
            }
          } else if (existingDevice != null) {
            // Device is offline (was seen before but not in current scan)
            finalDevices.add(existingDevice.copyWith(isOnline: false));
          }
        }
      } else {
        // First scan for this router
        finalDevices = newDevicesMap.values.toList();
      }

      // Create updated router data
      final updatedData = RouterNetworkData(
        routerId: routerId,
        gatewayIp: networkInfo.gateway ?? '',
        wifiName: networkInfo.wifiName,
        subnet: networkInfo.subnet,
        lastScanTime: now,
        devices: finalDevices,
      );

      // Save to storage
      allData[routerId] = updatedData;
      await _saveAllRouterData(allData);

      log(
        'Saved device data for router $routerId: ${finalDevices.length} devices',
      );
    } catch (e) {
      log('Error saving device data: $e');
    }
  }

  /// Get devices with online/offline status
  Future<List<StoredDevice>> getDevicesWithStatus() async {
    try {
      final routerData = await getCurrentRouterData();
      return routerData?.devices ?? [];
    } catch (e) {
      log('Error getting devices with status: $e');
      return [];
    }
  }

  /// Get only online devices
  Future<List<StoredDevice>> getOnlineDevices() async {
    try {
      final devices = await getDevicesWithStatus();
      return devices.where((device) => device.isOnline).toList();
    } catch (e) {
      log('Error getting online devices: $e');
      return [];
    }
  }

  /// Get only offline devices
  Future<List<StoredDevice>> getOfflineDevices() async {
    try {
      final devices = await getDevicesWithStatus();
      return devices.where((device) => !device.isOnline).toList();
    } catch (e) {
      log('Error getting offline devices: $e');
      return [];
    }
  }

  /// Get device statistics
  Future<Map<String, int>> getDeviceStats() async {
    try {
      final devices = await getDevicesWithStatus();
      final onlineCount = devices.where((d) => d.isOnline).length;
      final offlineCount = devices.where((d) => !d.isOnline).length;

      return {
        'total': devices.length,
        'online': onlineCount,
        'offline': offlineCount,
      };
    } catch (e) {
      log('Error getting device stats: $e');
      return {'total': 0, 'online': 0, 'offline': 0};
    }
  }

  /// Clear all stored data (for debugging/reset)
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      await prefs.remove(_currentRouterKey);
      log('Cleared all device storage data');
    } catch (e) {
      log('Error clearing all data: $e');
    }
  }

  /// Get all stored router networks
  Future<List<RouterNetworkData>> getAllRouterNetworks() async {
    try {
      final allData = await _getAllRouterData();
      return allData.values.toList()
        ..sort((a, b) => b.lastScanTime.compareTo(a.lastScanTime)); // Sort by most recent
    } catch (e) {
      log('Error getting all router networks: $e');
      return [];
    }
  }

  /// Get router data by router ID
  Future<RouterNetworkData?> getRouterData(String routerId) async {
    try {
      final allData = await _getAllRouterData();
      return allData[routerId];
    } catch (e) {
      log('Error getting router data for $routerId: $e');
      return null;
    }
  }

  /// Get total device count across all routers
  Future<int> getTotalDeviceCount() async {
    try {
      final allRouters = await getAllRouterNetworks();
      final Set<String> uniqueDevices = {};
      
      for (final router in allRouters) {
        for (final device in router.devices) {
          uniqueDevices.add(device.ip);
        }
      }
      
      return uniqueDevices.length;
    } catch (e) {
      log('Error getting total device count: $e');
      return 0;
    }
  }

  /// Get router network summary
  Future<Map<String, dynamic>> getRouterSummary() async {
    try {
      final allRouters = await getAllRouterNetworks();
      final currentRouterId = await getCurrentRouterId();
      
      return {
        'totalRouters': allRouters.length,
        'currentRouter': currentRouterId,
        'routers': allRouters.map((router) => {
          'routerId': router.routerId,
          'wifiName': router.wifiName ?? 'Unknown Network',
          'gatewayIp': router.gatewayIp,
          'deviceCount': router.devices.length,
          'onlineDevices': router.devices.where((d) => d.isOnline).length,
          'offlineDevices': router.devices.where((d) => !d.isOnline).length,
          'lastScanTime': router.lastScanTime.toIso8601String(),
          'isCurrent': router.routerId == currentRouterId,
        }).toList(),
      };
    } catch (e) {
      log('Error getting router summary: $e');
      return {
        'totalRouters': 0,
        'currentRouter': null,
        'routers': [],
      };
    }
  }

  /// Delete specific router data (if user wants to remove a specific network)
  Future<void> deleteRouterData(String routerId) async {
    try {
      log('🗑️ Attempting to delete router data for: $routerId');
      
      final allData = await _getAllRouterData();
      log('📊 Current router count before deletion: ${allData.length}');
      
      if (allData.containsKey(routerId)) {
        allData.remove(routerId);
        await _saveAllRouterData(allData);
        
        log('✅ Router data removed from storage');
        
        // If we deleted the current router, clear current router ID
        final currentRouterId = await getCurrentRouterId();
        if (currentRouterId == routerId) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_currentRouterKey);
          log('🔄 Cleared current router ID since it was deleted');
        }
        
        log('✅ Successfully deleted router data for: $routerId');
        log('📊 Remaining router count: ${allData.length}');
      } else {
        log('⚠️ Router $routerId not found in storage');
        throw Exception('Router data not found');
      }
    } catch (e) {
      log('❌ Error deleting router data: $e');
      rethrow;
    }
  }

  /// Get last scan time for current router
  Future<DateTime?> getLastScanTime() async {
    try {
      final routerData = await getCurrentRouterData();
      return routerData?.lastScanTime;
    } catch (e) {
      log('Error getting last scan time: $e');
      return null;
    }
  }

  /// Check if device was seen recently (within specified hours)
  bool wasSeenRecently(StoredDevice device, {int hoursThreshold = 24}) {
    final threshold = DateTime.now().subtract(Duration(hours: hoursThreshold));
    return device.lastSeen.isAfter(threshold);
  }

  /// Get recently offline devices (offline but seen within threshold)
  Future<List<StoredDevice>> getRecentlyOfflineDevices({
    int hoursThreshold = 24,
  }) async {
    try {
      final offlineDevices = await getOfflineDevices();
      return offlineDevices
          .where(
            (device) => wasSeenRecently(device, hoursThreshold: hoursThreshold),
          )
          .toList();
    } catch (e) {
      log('Error getting recently offline devices: $e');
      return [];
    }
  }
}
