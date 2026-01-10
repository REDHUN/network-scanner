import 'package:flutter/material.dart';
import 'package:ip_tools/service/permission_manager/permission_manager.dart';
import 'package:ip_tools/view/location_permission_screen/location_permission_screen.dart';
import 'package:ip_tools/view/main_navigation/main_navigation.dart';

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _isCheckingPermissions = true;
  bool _shouldShowPermissionScreen = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final shouldShow =
          await PermissionManager.shouldShowLocationPermissionScreen();

      setState(() {
        _shouldShowPermissionScreen = shouldShow;
        _isCheckingPermissions = false;
      });
    } catch (e) {
      // On error, default to not showing permission screen
      setState(() {
        _shouldShowPermissionScreen = false;
        _isCheckingPermissions = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermissions) {
      // Show loading screen while checking permissions
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_shouldShowPermissionScreen) {
      // Show permission screen
      return LocationPermissionScreen(
        onPermissionGranted: _onPermissionGranted,
        onSkipped: _onPermissionSkipped,
      );
    }

    // Show main app
    return const MainNavigation();
  }
}
