import 'dart:async';

import 'package:ip_tools/core/baseviewmodel/base_viewmodel.dart';
import 'package:ip_tools/models/network_model/network_info_model.dart';
import 'package:ip_tools/service/network_connectivity_service/network_connectivity_service.dart';
import 'package:ip_tools/service/network_service/network_service.dart';
import 'package:ip_tools/service/permission_service/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';

class NetworkViewModel extends BaseViewModel {
  final NetworkService _networkService;
  final PermissionService _permissionService;
  final ConnectivityService _connectivityService;

  NetworkInfoModel? networkInfo;
  bool isNetworkActive = false;
  LocationStatus? locationStatus;

  StreamSubscription<bool>? _wifiSubscription;
  StreamSubscription<LocationStatus>? _locationStatusSubscription;
  StreamSubscription<PermissionStatus>? _permissionStatusSubscription;
  bool _wasPreviouslyConnected = false;

  NetworkViewModel(
    this._networkService,
    this._permissionService,
    this._connectivityService,
  ) {
    _setupRealTimeListeners();
  }

  /// Setup real-time listeners for location and permission changes
  void _setupRealTimeListeners() {
    // Listen to location status changes
    _locationStatusSubscription = _permissionService.locationStatusStream
        .listen((status) {
          locationStatus = status;
          notifyListeners();

          // Auto-refresh network info when location becomes available
          if (status == LocationStatus.available) {
            loadNetworkInfo();
          }
        });

    // Listen to permission status changes
    _permissionStatusSubscription = _permissionService.permissionStatusStream
        .listen((status) {
          // Auto-refresh when permission is granted
          if (status == PermissionStatus.granted) {
            loadNetworkInfo();
          }
        });
  }

  /// Initial load
  Future<void> loadNetworkInfo() async {
    try {
      setLoading();

      final isWifi = await _connectivityService.isWifiConnected();

      if (!isWifi) {
        isNetworkActive = false;
        setError('Wi-Fi not connected');
        return;
      }

      // Check location status first
      locationStatus = await _permissionService.getLocationStatus();

      if (locationStatus != LocationStatus.available) {
        isNetworkActive = false;
        setSuccess(); // Set success so UI can show proper message
        return;
      }

      networkInfo = await _networkService.getNetworkInfo();

      final ip = networkInfo?.wifiIP;
      isNetworkActive = ip != null && ip.isNotEmpty && ip != '0.0.0.0';

      setSuccess();
    } catch (e) {
      setError(e.toString());
    }
  }

  /// Request location permission
  Future<void> requestLocationPermission() async {
    final granted = await _permissionService.requestWifiPermission();
    if (granted) {
      await loadNetworkInfo();
    }
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    await _permissionService.openLocationSettings();
    // Refresh after user potentially enables location
    await Future.delayed(const Duration(milliseconds: 500));
    await loadNetworkInfo();
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    await _permissionService.openSettings();
    // Refresh after user potentially grants permission
    await Future.delayed(const Duration(milliseconds: 500));
    await loadNetworkInfo();
  }

  /// Force refresh network information
  Future<void> forceRefresh() async {
    await loadNetworkInfo();
  }

  /// Get display message based on location status
  String getLocationMessage() {
    switch (locationStatus) {
      case LocationStatus.serviceDisabled:
        return 'Location services are disabled';
      case LocationStatus.permissionDenied:
        return 'Location permission required';
      case LocationStatus.error:
        return 'Unable to access location';
      case LocationStatus.available:
      case null:
        return 'Loading...';
    }
  }

  /// Get WiFi name or appropriate message
  String getWifiDisplayName() {
    if (locationStatus != LocationStatus.available) {
      return getLocationMessage();
    }
    return networkInfo?.wifiName ?? 'Loading...';
  }

  void startNetworkMonitoring() {
    _wifiSubscription ??= _connectivityService.wifiStatusStream().listen((
      isConnected,
    ) async {
      if (isConnected && !_wasPreviouslyConnected) {
        //  Auto-refresh on reconnect
        await loadNetworkInfo();
      }

      _wasPreviouslyConnected = isConnected;
      isNetworkActive = isConnected;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _wifiSubscription?.cancel();
    _locationStatusSubscription?.cancel();
    _permissionStatusSubscription?.cancel();
    _permissionService.dispose();
    super.dispose();
  }
}
