import 'package:jaal/models/network_model/network_info_model.dart';
import 'package:network_info_plus/network_info_plus.dart';

class NetworkService {
  final NetworkInfo _networkInfo = NetworkInfo();

  Future<NetworkInfoModel> getNetworkInfo() async {
    final wifiName = await _networkInfo.getWifiName();
    final wifiIP = await _networkInfo.getWifiIP();
    final subnet = await _networkInfo.getWifiSubmask();
    final gateway = await _networkInfo.getWifiGatewayIP();

    return NetworkInfoModel(
      wifiName: wifiName,
      wifiIP: wifiIP,
      subnet: subnet,
      gateway: gateway,
    );
  }

  Future<String?> getLocalIp() => _networkInfo.getWifiIP();
}
