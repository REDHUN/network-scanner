import 'package:flutter/material.dart';
import 'package:netra/view/devices_screen/devices_screen.dart';
import 'package:netra/view/homescreen/homescreen.dart';
import 'package:netra/view/settings_screen/settings_screen.dart';
import 'package:netra/viewmodels/scanner_viewmodel/scanner_viewmodel.dart';
import 'package:provider/provider.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [Homescreen(), const DevicesScreen(), const SettingsScreen()];
  }

  @override
  Widget build(BuildContext context) {
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
