import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ip_tools/service/network_connectivity_service/network_connectivity_service.dart';

const MethodChannel _wifiSettingsChannel = MethodChannel(
  'ip_tools/wifi_settings',
);

class WiFiConnectionScreen extends StatefulWidget {
  final VoidCallback onWiFiConnected;

  const WiFiConnectionScreen({super.key, required this.onWiFiConnected});

  @override
  State<WiFiConnectionScreen> createState() => _WiFiConnectionScreenState();
}

class _WiFiConnectionScreenState extends State<WiFiConnectionScreen> {
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isCheckingConnection = false;
  StreamSubscription<bool>? _wifiStatusSubscription;
  Timer? _wifiConnectionTimer;
  bool _hasNotifiedForCurrentConnection = false;

  @override
  void initState() {
    super.initState();
    _startListeningForWiFi();
  }

  void _startListeningForWiFi() {
    _wifiStatusSubscription = _connectivityService.wifiStatusStream().listen(
      _handleWiFiStatus,
    );
  }

  void _handleWiFiStatus(bool isConnected) {
    if (!isConnected) {
      _resetConnectionNotification();
      return;
    }

    if (!mounted ||
        _hasNotifiedForCurrentConnection ||
        _wifiConnectionTimer != null) {
      return;
    }

    // Small delay to ensure connection is stable. Keep the timer so repeated
    // stream events cannot queue multiple callbacks.
    _wifiConnectionTimer = Timer(const Duration(milliseconds: 500), () {
      _wifiConnectionTimer = null;
      _notifyWiFiConnected();
    });
  }

  void _resetConnectionNotification() {
    _wifiConnectionTimer?.cancel();
    _wifiConnectionTimer = null;
    _hasNotifiedForCurrentConnection = false;
  }

  void _notifyWiFiConnected() {
    if (!mounted || _hasNotifiedForCurrentConnection) {
      return;
    }

    _hasNotifiedForCurrentConnection = true;
    widget.onWiFiConnected();
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isCheckingConnection = true;
    });

    try {
      final isConnected = await _connectivityService.isWifiConnected();
      if (isConnected) {
        _wifiConnectionTimer?.cancel();
        _wifiConnectionTimer = null;
        _notifyWiFiConnected();
      } else {
        _resetConnectionNotification();
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'No Wi-Fi connection found. Connect to Wi-Fi and try again.',
                ),
              ),
            );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingConnection = false;
        });
      }
    }
  }

  Future<void> _openWiFiSettings() async {
    String? settingsDestination;
    try {
      settingsDestination = await _wifiSettingsChannel.invokeMethod<String>(
        'openWifiSettings',
      );
    } on MissingPluginException {
      // Keep the instructions available on unsupported platforms and in tests.
    } on PlatformException {
      // The dialog still provides a manual path if the settings activity fails.
    }

    if (!mounted) {
      return;
    }

    // The settings screen is the primary flow. Only show the manual
    // instructions when the platform cannot open settings (or when running
    // on a platform without this bridge).
    if (settingsDestination == 'wifi_settings' ||
        settingsDestination == 'app_settings') {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) => _buildWiFiInstructionsDialog(
        settingsDestination: settingsDestination,
      ),
    );
  }

  Widget _buildWiFiInstructionsDialog({String? settingsDestination}) {
    final isIosFallback =
        settingsDestination?.startsWith('app_settings') ?? false;

    return Dialog(
      backgroundColor: Colors.white,
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.wifi_rounded,
                        color: Color(0xFF0075FF),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connect to WiFi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Step-by-step instructions',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Semantics(
                      button: true,
                      label: 'Close instructions',
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Close instructions',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        icon: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF3F4F6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF6B7280),
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                'To use IP Tools, please connect to a WiFi network:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),

              const SizedBox(height: 16),

              if (isIosFallback) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFC2410C),
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'On iOS, IP Tools uses the app Settings page as a safe fallback because direct Wi-Fi navigation is not reliably supported. Use the back control in Settings, open Wi-Fi, connect, then return to IP Tools.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF7C2D12),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Instruction Steps
              _buildInstructionStep(
                '1',
                'Open your device Settings',
                Icons.settings_outlined,
              ),
              _buildInstructionStep(
                '2',
                'Navigate to WiFi or Network settings',
                Icons.wifi_rounded,
              ),
              _buildInstructionStep(
                '3',
                'Select and connect to a WiFi network',
                Icons.wifi_lock_rounded,
              ),
              _buildInstructionStep(
                '4',
                'Return to IP Tools - it will detect the connection automatically',
                Icons.check_circle_outline_rounded,
              ),

              const SizedBox(height: 16),

              // Info Container
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF0075FF).withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF0075FF),
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Network scanning requires an active WiFi connection to discover devices on your local network.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4B5563),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Got it button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0075FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(top: 1),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Color(0xFF0075FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(icon, color: const Color(0xFF0075FF), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _wifiConnectionTimer?.cancel();
    _wifiStatusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Light off-white background
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Semantics(
                        button: true,
                        label: 'Back',
                        child: IconButton(
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                          tooltip: 'Back',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                          icon: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF3F4F6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Color(0xFF1F2937),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    'Network Scanner',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    // Main Icon Container
                    Container(
                      width: 200,
                      height: 240,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF0075FF,
                            ).withValues(alpha: 0.05),
                            blurRadius: 40,
                            offset: const Offset(0, 10),
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.wifi_off_rounded,
                                color: Color(0xFF0075FF),
                                size: 50,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // 3 small dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE5E7EB),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF0075FF,
                                  ).withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE5E7EB),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Headings
                    const Text(
                      'WiFi Connection Required',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'To scan your network and discover nearby devices, please connect your device to a local WiFi network.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Action Buttons
                    Column(
                      children: [
                        // Primary Check Connection Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isCheckingConnection
                                ? null
                                : _checkConnection,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0075FF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: _isCheckingConnection
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.refresh, size: 20),
                                      SizedBox(width: 10),
                                      Text(
                                        'Check Connection',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Secondary How to Connect Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _openWiFiSettings,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFFF3F4F6,
                              ), // Using F3F4F6 as grey matching the image
                              foregroundColor: const Color(0xFF1F2937),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: const Text(
                              'How to Connect',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
