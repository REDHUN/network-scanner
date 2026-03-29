import 'package:flutter/material.dart';
import 'package:ip_tools/service/permission_manager/permission_manager.dart';
import 'package:ip_tools/view/location_permission_screen/location_permission_screen.dart';
import 'package:ip_tools/view/main_navigation/main_navigation.dart';
import 'package:ip_tools/view/wifi_connection_screen/wifi_connection_screen.dart';

class AppWrapper extends StatefulWidget {
  final bool initialIsWiFiConnected;
  final bool initialShouldShowPermissionScreen;

  const AppWrapper({
    super.key,
    required this.initialIsWiFiConnected,
    required this.initialShouldShowPermissionScreen,
  });

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  late bool _isWiFiConnected;
  late bool _shouldShowPermissionScreen;

  @override
  void initState() {
    super.initState();
    _isWiFiConnected = widget.initialIsWiFiConnected;
    _shouldShowPermissionScreen = widget.initialShouldShowPermissionScreen;
  }

  void _onPermissionGranted() {
    setState(() {
      _shouldShowPermissionScreen = false;
    });
  }

  void _onPermissionSkipped() {
    setState(() {
      _shouldShowPermissionScreen = false;
    });
  }

  void _onWiFiConnected() async {
    // Show loading while checking permissions after wifi connects
    setState(() {
      _isWiFiConnected = true;
    });

    // Once wifi connects, we still need to check permissions if we haven't
    try {
      final shouldShow =
          await PermissionManager.shouldShowLocationPermissionScreen();
      setState(() {
        _shouldShowPermissionScreen = shouldShow;
      });
    } catch (e) {
      setState(() {
        _shouldShowPermissionScreen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show WiFi connection screen if not connected
    if (!_isWiFiConnected) {
      return WiFiConnectionScreen(onWiFiConnected: _onWiFiConnected);
    }

    // Show location permission screen if needed
    if (_shouldShowPermissionScreen) {
      return LocationPermissionScreen(
        onPermissionGranted: _onPermissionGranted,
        onSkipped: _onPermissionSkipped,
      );
    }

    // Show main app
    return const MainNavigation();
  }
}
