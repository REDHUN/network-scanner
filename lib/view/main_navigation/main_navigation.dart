import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ip_tools/service/network_connectivity_service/network_connectivity_service.dart';
import 'package:ip_tools/service/permission_manager/permission_manager.dart';
import 'package:ip_tools/view/devices_screen/devices_screen.dart';
import 'package:ip_tools/view/homescreen/homescreen.dart';
import 'package:ip_tools/view/router_history_screen/router_history_screen.dart';
import 'package:ip_tools/view/wifi_connection_screen/wifi_connection_screen.dart';
import 'package:ip_tools/viewmodels/network_viewmodel/network_viewmodel.dart';
import 'package:ip_tools/viewmodels/scanner_viewmodel/scanner_viewmodel.dart';
import 'package:provider/provider.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation>
    with WidgetsBindingObserver {
  final ConnectivityService _connectivityService = ConnectivityService();
  int _currentIndex = 0;
  bool _isWiFiConnected = true;
  StreamSubscription<bool>? _wifiSubscription;
  bool _autoStartScanOnDevicesScreen = false;

  List<Widget> get _screens => [
    const Homescreen(),
    DevicesScreen(autoStartScan: _autoStartScanOnDevicesScreen),
    const RouterHistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _startWiFiMonitoring();

    // Initialize network information globally when the app loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final networkVM = Provider.of<NetworkViewModel>(context, listen: false);
      final scannerVM = Provider.of<NetworkScannerProvider>(
        context,
        listen: false,
      );

      networkVM.loadNetworkInfo().then((_) async {
        if (networkVM.networkInfo != null) {
          await scannerVM.initializeWithNetworkInfo(networkVM.networkInfo!);
          if (scannerVM.hasRouterChanged && mounted) {
            _showNewNetworkPrompt();
          }
        }
      });
      networkVM.startNetworkMonitoring();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app resumes from background (e.g., returning from settings)
    if (state == AppLifecycleState.resumed) {
      final networkVM = Provider.of<NetworkViewModel>(context, listen: false);
      // Small delay to ensure system has updated permissions/settings
      Future.delayed(const Duration(milliseconds: 500), () {
        networkVM.loadNetworkInfo();
      });
    }
  }

  void _showNewNetworkPrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEDFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_find,
                    color: Color(0xFF656CEB),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'New Network Detected',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'You have connected to a new WiFi network. Would you like to scan it now to discover connected devices?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Later',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          final hasPermission =
                              await PermissionManager.checkLocationPermissionForFeature(
                                context,
                                featureName: 'Network Scanning',
                              );

                          if (hasPermission && mounted) {
                            // Go to devices screen index to trigger an auto scan
                            setState(() {
                              _autoStartScanOnDevicesScreen = true;
                            });
                            switchTab(1); // 1 is Devices tab

                            // Reset flag after a short delay so manual navigation later doesn't auto-scan
                            Future.delayed(
                              const Duration(milliseconds: 500),
                              () {
                                if (mounted) {
                                  _autoStartScanOnDevicesScreen = false;
                                }
                              },
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF656CEB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Scan Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startWiFiMonitoring() {
    _wifiSubscription = _connectivityService.wifiStatusStream().listen((
      isConnected,
    ) {
      if (mounted) {
        setState(() {
          _isWiFiConnected = isConnected;
        });
      }
    });
  }

  void switchTab(int index) {
    if (mounted) {
      if (index == 0) {
        final scannerVM = context.read<NetworkScannerProvider>();
        if (scannerVM.state == ScanState.done) {
          scannerVM.resetScan();
        }
      }
      setState(() => _currentIndex = index);
    }
  }

  void _onWiFiReconnected() {
    setState(() {
      _isWiFiConnected = true;
    });

    // Show a brief reconnection message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'WiFi reconnected - Welcome back!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2C2C2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        elevation: 8,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _wifiSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show WiFi connection screen if disconnected
    if (!_isWiFiConnected) {
      return WiFiConnectionScreen(onWiFiConnected: _onWiFiReconnected);
    }

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (mounted) {
              // Reset scan state when navigating to home (index 0)
              if (index == 0) {
                final scannerVM = context.read<NetworkScannerProvider>();
                if (scannerVM.state == ScanState.done) {
                  scannerVM.resetScan();
                }
              }
              setState(() => _currentIndex = index);
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: const Color(0xFF656CEB),
          unselectedItemColor: const Color(0xFF9CA3AF),
          selectedLabelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.dashboard),
              ),
              label: 'DASHBOARD',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.devices_other),
              ),
              label: 'DEVICES',
            ),
            // BottomNavigationBarItem(
            //   icon: Padding(
            //     padding: EdgeInsets.only(bottom: 4),
            //     child: Icon(Icons.settings),
            //   ),
            //   label: 'SETTINGS',
            // ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.history),
              ),
              label: 'HISTORY',
            ),
          ],
        ),
      ),
    );
  }
}
