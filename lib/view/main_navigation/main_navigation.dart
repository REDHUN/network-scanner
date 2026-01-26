import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ip_tools/service/network_connectivity_service/network_connectivity_service.dart';
import 'package:ip_tools/view/devices_screen/devices_screen.dart';
import 'package:ip_tools/view/homescreen/homescreen.dart';
import 'package:ip_tools/view/settings_screen/settings_screen.dart';
import 'package:ip_tools/view/wifi_connection_screen/wifi_connection_screen.dart';
import 'package:ip_tools/viewmodels/scanner_viewmodel/scanner_viewmodel.dart';
import 'package:provider/provider.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final ConnectivityService _connectivityService = ConnectivityService();
  int _currentIndex = 0;
  bool _isWiFiConnected = true;
  StreamSubscription<bool>? _wifiSubscription;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [Homescreen(), const DevicesScreen(), const SettingsScreen()];
    _startWiFiMonitoring();
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
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
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
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.black,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          unselectedIconTheme: IconThemeData(color: Colors.black),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),

            BottomNavigationBarItem(
              icon: Icon(Icons.devices),
              label: 'Devices',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
