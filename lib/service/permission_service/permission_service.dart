import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestWifiPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }
}
