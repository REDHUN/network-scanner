import 'package:flutter/material.dart';
import 'package:ip_tools/service/network_connectivity_service/network_connectivity_service.dart';
import 'package:ip_tools/service/permission_manager/permission_manager.dart';
import 'package:ip_tools/view/main_navigation/main_navigation.dart';
import 'package:ip_tools/view/wifi_connection_screen/wifi_connection_screen.dart';

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  final ConnectivityService _connectivityService = ConnectivityService();

  bool _isCheckingPermissions = true;
  bool _shouldShowPermissionScreen = false;
  bool _isCheckingWiFi = false;
  bool _isWiFiConnected = false;
  bool _isLocationPermissionGranted = false;
  String _loadingMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeApp();

    // Add a timeout to prevent infinite loading
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && (_isCheckingWiFi || _isCheckingPermissions)) {
        // If still loading after 10 seconds, force proceed
        setState(() {
          _isCheckingWiFi = false;
          _isCheckingPermissions = false;
          _loadingMessage = 'Connection timeout - proceeding...';
        });
      }
    });
  }

  Future<void> _initializeApp() async {
    // First check WiFi connectivity
    await _checkWiFiConnection();

    // If WiFi is connected, then check permissions
    if (_isWiFiConnected) {
      await _checkPermissions();
    } else {
      // If WiFi is not connected, we don't need to check permissions yet
      setState(() {
        _isCheckingPermissions = false;
      });
    }
  }

  Future<void> _checkWiFiConnection() async {
    setState(() {
      _isCheckingWiFi = true;
      _loadingMessage = 'Checking WiFi connection...';
    });

    try {
      // Add a timeout to the connectivity check
      final isConnected = await _connectivityService.isWifiConnected().timeout(
        const Duration(seconds: 5),
      );

      setState(() {
        _isWiFiConnected = isConnected;
        _isCheckingWiFi = false;
      });
    } catch (e) {
      // On error, assume WiFi is connected to allow app to proceed
      setState(() {
        _isWiFiConnected = true; // Default to connected on error
        _isCheckingWiFi = false;
      });
    }
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _loadingMessage = 'Checking permissions...';
    });

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

  void _onWiFiConnected() {
    setState(() {
      _isWiFiConnected = true;
      _isCheckingPermissions =
          true; // Start checking permissions when WiFi connects
    });
    // Check permissions after WiFi is connected
    _checkPermissions();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while checking WiFi or permissions
    if (_isCheckingWiFi || _isCheckingPermissions) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).scaffoldBackgroundColor,
                Theme.of(
                  context,
                ).scaffoldBackgroundColor.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.network_check,
                    color: Color(0xFFD4A574),
                    size: 40,
                  ),
                ),

                const SizedBox(height: 32),

                // Loading indicator
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4A574)),
                ),

                const SizedBox(height: 24),

                // Loading message
                Text(
                  _loadingMessage,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'IP Tools : Network Scanner',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show WiFi connection screen if not connected
    if (!_isWiFiConnected) {
      return WiFiConnectionScreen(onWiFiConnected: _onWiFiConnected);
    }

    // Show main app
    return const MainNavigation();
  }
}
