import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// One-time check
  Future<bool> isWifiConnected() async {
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.wifi);
  }

  /// Live Wi-Fi connection stream
  Stream<bool> wifiStatusStream() {
    return _connectivity.onConnectivityChanged.map(
          (results) => results.contains(ConnectivityResult.wifi),
    );
  }
}
