import 'dart:async';
import 'dart:developer';

import 'package:geolocator/geolocator.dart';
import 'package:ip_tools/service/permission_preferences_service/permission_preferences_service.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  final _preferencesService = PermissionPreferencesService();

  // Stream controllers for real-time updates
  final _locationStatusController =
      StreamController<LocationStatus>.broadcast();
  final _permissionStatusController =
      StreamController<PermissionStatus>.broadcast();

  Timer? _statusCheckTimer;
  LocationStatus? _lastLocationStatus;
  PermissionStatus? _lastPermissionStatus;

  // Streams for real-time updates
  Stream<LocationStatus> get locationStatusStream =>
      _locationStatusController.stream;
  Stream<PermissionStatus> get permissionStatusStream =>
      _permissionStatusController.stream;

  PermissionService() {
    _startRealTimeMonitoring();
  }

  /// Start real-time monitoring of location and permission status
  void _startRealTimeMonitoring() {
    // Check status every 2 seconds for real-time updates
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      await _checkAndNotifyStatusChanges();
    });
  }

  /// Check for status changes and notify listeners
  Future<void> _checkAndNotifyStatusChanges() async {
    try {
      // Check location status
      final currentLocationStatus = await getLocationStatus();
      if (currentLocationStatus != _lastLocationStatus) {
        _lastLocationStatus = currentLocationStatus;
        _locationStatusController.add(currentLocationStatus);
        log('Location status changed to: $currentLocationStatus');
      }

      // Check permission status
      final currentPermissionStatus = await Permission.locationWhenInUse.status;
      if (currentPermissionStatus != _lastPermissionStatus) {
        _lastPermissionStatus = currentPermissionStatus;
        _permissionStatusController.add(currentPermissionStatus);
        log('Permission status changed to: $currentPermissionStatus');
      }
    } catch (e) {
      log('Error checking status changes: $e');
    }
  }

  /// Stop real-time monitoring
  void dispose() {
    _statusCheckTimer?.cancel();
    _locationStatusController.close();
    _permissionStatusController.close();
  }

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

  /// Check if location services are enabled on the device
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      log('Error checking location service status: $e');
      return false;
    }
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      log('Error opening location settings: $e');
      return false;
    }
  }

  /// Check both location permission and location services
  Future<LocationStatus> getLocationStatus() async {
    try {
      final isServiceEnabled = await isLocationServiceEnabled();
      final isPermissionGranted = await isLocationPermissionGranted();

      if (!isServiceEnabled) {
        return LocationStatus.serviceDisabled;
      } else if (!isPermissionGranted) {
        return LocationStatus.permissionDenied;
      } else {
        return LocationStatus.available;
      }
    } catch (e) {
      log('Error getting location status: $e');
      return LocationStatus.error;
    }
  }
}

enum LocationStatus { available, permissionDenied, serviceDisabled, error }
