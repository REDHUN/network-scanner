import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:ip_tools/models/network_model/network_info_model.dart';
import 'package:network_info_plus/network_info_plus.dart';

class NetworkService {
  final NetworkInfo _networkInfo = NetworkInfo();

  Future<NetworkInfoModel> getNetworkInfo() async {
    String? wifiName;
    String? wifiIP;
    String? subnet;
    String? gateway;
    String? bssid;
    String? ipv6;
    String? broadcast;

    try {
      wifiName = await _networkInfo.getWifiName();
    } catch (_) {}

    try {
      wifiIP = await _networkInfo.getWifiIP();
    } catch (_) {}

    try {
      subnet = await _networkInfo.getWifiSubmask();
    } catch (_) {}

    try {
      gateway = await _networkInfo.getWifiGatewayIP();
    } catch (_) {}

    try {
      bssid = await _networkInfo.getWifiBSSID();
    } catch (_) {}

    try {
      ipv6 = await _networkInfo.getWifiIPv6();
    } catch (_) {}

    try {
      broadcast = await _networkInfo.getWifiBroadcast();
    } catch (_) {}

    // Clean up quotes from SSID if returned e.g. "AndroidWifi" -> AndroidWifi
    if (wifiName != null &&
        wifiName.startsWith('"') &&
        wifiName.endsWith('"') &&
        wifiName.length > 1) {
      wifiName = wifiName.substring(1, wifiName.length - 1);
    }

    // Public IP, ISP, Geolocation & ASN info
    final publicData = await _fetchPublicNetworkData();

    return NetworkInfoModel(
      wifiName: wifiName,
      wifiIP: wifiIP,
      subnet: subnet,
      gateway: gateway,
      bssid: bssid,
      ipv6: ipv6,
      broadcast: broadcast,
      wifiState: 'Online',
      connectionType: 'WIFI',
      localhost: '127.0.0.1',
      publicIp: publicData?['publicIp'] as String?,
      isp: publicData?['isp'] as String?,
      organization: publicData?['organization'] as String?,
      asn: publicData?['asn'] as String?,
      timezone: publicData?['timezone'] as String?,
      city: publicData?['city'] as String?,
      region: publicData?['region'] as String?,
      country: publicData?['country'] as String?,
      latitude: publicData?['latitude'] is num
          ? (publicData!['latitude'] as num).toDouble()
          : null,
      longitude: publicData?['longitude'] is num
          ? (publicData!['longitude'] as num).toDouble()
          : null,
    );
  }

  Future<Map<String, dynamic>?> _fetchPublicNetworkData() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'http://ip-api.com/json/?fields=status,message,country,regionName,city,lat,lon,timezone,isp,org,as,query',
            ),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          return {
            'publicIp': data['query']?.toString(),
            'isp': data['isp']?.toString(),
            'organization': data['org']?.toString(),
            'asn': data['as']?.toString(),
            'timezone': data['timezone']?.toString(),
            'city': data['city']?.toString(),
            'region': data['regionName']?.toString(),
            'country': data['country']?.toString(),
            'latitude': data['lat'],
            'longitude': data['lon'],
          };
        }
      }
    } catch (e) {
      developer.log('Error fetching ip-api: $e', name: 'NetworkService');
    }

    // Fallback: ipapi.co
    try {
      final response = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'publicIp': data['ip']?.toString(),
          'isp': data['org']?.toString(),
          'organization': data['org']?.toString(),
          'asn': data['asn']?.toString(),
          'timezone': data['timezone']?.toString(),
          'city': data['city']?.toString(),
          'region': data['region']?.toString(),
          'country': data['country_name']?.toString(),
          'latitude': data['latitude'],
          'longitude': data['longitude'],
        };
      }
    } catch (e) {
      developer.log(
        'Error in fallback public IP fetch: $e',
        name: 'NetworkService',
      );
    }

    return null;
  }

  Future<String?> getLocalIp() => _networkInfo.getWifiIP();
}
