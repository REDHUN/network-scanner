import 'dart:developer';

import 'package:ip_tools/service/permission_preferences_service/permission_preferences_service.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  final _preferencesService = PermissionPreferencesService();

  /// Request WiFi/Location permission with preference tracking
  Future<bool> requestWifiPermission() async {
    try {
      // Check current permission status
      final status = await Permission.locationWhenInUse.status;

      if (status.isGranted) {
        // Permission already granted, reset denied count
        await _preferencesService.resetLocationPermissionDeniedCount();
        return true;
      }

      // Mark that we've asked for permission
      await _preferencesService.setLocationPermissionAsked();

      // Request permission
      final newStatus = await Permission.locationWhenInUse.request();

      if (newStatus.isGranted) {
        // Permission granted, reset denied count
        await _preferencesService.resetLocationPermissionDeniedCount();
        log('Location permission granted');
        return true;
      } else {
        // Permission denied, increment count
        await _preferencesService.incrementLocationPermissionDeniedCount();
        log('Location permission denied');
        return false;
      }
    } catch (e) {
      log('Error requesting WiFi permission: $e');
      return false;
    }
  }

  /// Check if location permission is granted
  Future<bool> isLocationPermissionGranted() async {
    try {
      final status = await Permission.locationWhenInUse.status;
      return status.isGranted;
    } catch (e) {
      log('Error checking location permission: $e');
      return false;
    }
  }

  /// Check if location permission is permanently denied
  Future<bool> isLocationPermissionPermanentlyDenied() async {
    try {
      final status = await Permission.locationWhenInUse.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      log('Error checking permanently denied status: $e');
      return false;
    }
  }

  /// Get location permission status string
  Future<String> getLocationPermissionStatusString() async {
    try {
      final status = await Permission.locationWhenInUse.status;
      switch (status) {
        case PermissionStatus.granted:
          return 'Granted';
        case PermissionStatus.denied:
          return 'Denied';
        case PermissionStatus.permanentlyDenied:
          return 'Permanently Denied';
        case PermissionStatus.restricted:
          return 'Restricted';
        case PermissionStatus.limited:
          return 'Limited';
        case PermissionStatus.provisional:
          return 'Provisional';
      }
    } catch (e) {
      log('Error getting permission status string: $e');
      return 'Error';
    }
  }

  /// Open app settings for permission management
  Future<bool> openSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      log('Error opening app settings: $e');
      return false;
    }
  }
}
