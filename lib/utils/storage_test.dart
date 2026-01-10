import 'dart:developer';

import 'package:ip_tools/models/network_model/network_info_model.dart';
import 'package:ip_tools/models/network_model/scanned_device.dart';
import 'package:ip_tools/service/device_storage_service/device_storage_service.dart';

/// Simple test utility to verify device storage functionality
class StorageTest {
  static final _storageService = DeviceStorageService();

  /// Test basic storage operations
  static Future<void> testBasicOperations() async {
    log('🧪 Testing Device Storage Service...');

    try {
      // Test 1: Create mock network info
      const networkInfo = NetworkInfoModel(
        wifiName: 'TestWiFi',
        gateway: '192.168.1.1',
        wifiIP: '192.168.1.100',
        subnet: '255.255.255.0',
      );

      // Test 2: Create mock devices
      final devices = [
        const ScannedDevice(ip: '192.168.1.1', name: 'Router', isGateway: true),
        const ScannedDevice(ip: '192.168.1.100', name: 'iPhone', isSelf: true),
        const ScannedDevice(ip: '192.168.1.101', name: 'MacBook'),
      ];

      // Test 3: Save initial data
      await _storageService.saveDeviceData(networkInfo, devices);
      log('✅ Saved initial device data');

      // Test 4: Get device stats
      final stats = await _storageService.getDeviceStats();
      log('📊 Device stats: $stats');

      // Test 5: Simulate second scan with one device missing
      final secondScanDevices = [
        const ScannedDevice(ip: '192.168.1.1', name: 'Router', isGateway: true),
        const ScannedDevice(ip: '192.168.1.100', name: 'iPhone', isSelf: true),
        // MacBook is missing (offline)
      ];

      await _storageService.saveDeviceData(networkInfo, secondScanDevices);
      log('✅ Saved second scan data (MacBook offline)');

      // Test 6: Check offline devices
      final offlineDevices = await _storageService.getOfflineDevices();
      log('📱 Offline devices: ${offlineDevices.length}');
      for (final device in offlineDevices) {
        log('   - ${device.ip}: ${device.name ?? 'Unknown'} (offline)');
      }

      // Test 7: Check online devices
      final onlineDevices = await _storageService.getOnlineDevices();
      log('🟢 Online devices: ${onlineDevices.length}');
      for (final device in onlineDevices) {
        log('   - ${device.ip}: ${device.name ?? 'Unknown'} (online)');
      }

      // Test 8: Test router change
      const newNetworkInfo = NetworkInfoModel(
        wifiName: 'NewWiFi',
        gateway: '192.168.0.1',
        wifiIP: '192.168.0.100',
        subnet: '255.255.255.0',
      );

      final hasChanged = await _storageService.hasRouterChanged(newNetworkInfo);
      log('🔄 Router changed: $hasChanged');

      // Test 9: Test multi-router storage
      final allRouters = await _storageService.getAllRouterNetworks();
      log('🏠 Total stored routers: ${allRouters.length}');
      for (final router in allRouters) {
        log('   - ${router.wifiName}: ${router.devices.length} devices');
      }

      // Test 10: Test router deletion
      if (allRouters.isNotEmpty) {
        final routerToDelete = allRouters.first.routerId;
        log('🗑️ Testing deletion of router: $routerToDelete');
        await _storageService.deleteRouterData(routerToDelete);

        final remainingRouters = await _storageService.getAllRouterNetworks();
        log('✅ Remaining routers after deletion: ${remainingRouters.length}');
      }

      log('✅ All tests completed successfully!');
    } catch (e) {
      log('❌ Test failed: $e');
    }
  }

  /// Clear all test data
  static Future<void> clearTestData() async {
    await _storageService.clearAllData();
    log('🧹 Cleared all test data');
  }
}
