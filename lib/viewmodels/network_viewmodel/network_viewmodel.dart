import 'dart:async';

import 'package:jaal/core/baseviewmodel/base_viewmodel.dart';
import 'package:jaal/models/network_model/network_info_model.dart';
import 'package:jaal/service/network_connectivity_service/network_connectivity_service.dart';
import 'package:jaal/service/network_service/network_service.dart';
import 'package:jaal/service/permission_service/permission_service.dart';

class NetworkViewModel extends BaseViewModel {
  final NetworkService _networkService;
  final PermissionService _permissionService;
  final ConnectivityService _connectivityService;

  NetworkInfoModel? networkInfo;
  bool isNetworkActive = false;

  StreamSubscription<bool>? _wifiSubscription;
  bool _wasPreviouslyConnected = false;

  NetworkViewModel(
    this._networkService,
    this._permissionService,
    this._connectivityService,
  );

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

      final hasPermission = await _permissionService.requestWifiPermission();

      if (!hasPermission) {
        setError('Permission denied');
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
    super.dispose();
  }
}
