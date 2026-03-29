import 'package:flutter/material.dart';
import 'package:ip_tools/service/network_connectivity_service/network_connectivity_service.dart';

class WiFiConnectionScreen extends StatefulWidget {
  final VoidCallback onWiFiConnected;

  const WiFiConnectionScreen({super.key, required this.onWiFiConnected});

  @override
  State<WiFiConnectionScreen> createState() => _WiFiConnectionScreenState();
}

class _WiFiConnectionScreenState extends State<WiFiConnectionScreen> {
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isCheckingConnection = false;

  @override
  void initState() {
    super.initState();
    _startListeningForWiFi();
  }

  void _startListeningForWiFi() {
    _connectivityService.wifiStatusStream().listen((isConnected) {
      if (isConnected && mounted) {
        // Small delay to ensure connection is stable
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            widget.onWiFiConnected();
          }
        });
      }
    });
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isCheckingConnection = true;
    });

    try {
      final isConnected = await _connectivityService.isWifiConnected();
      if (isConnected && mounted) {
        widget.onWiFiConnected();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingConnection = false;
        });
      }
    }
  }

  void _openWiFiSettings() {
    // This will open the device's WiFi settings
    // Note: This requires platform-specific implementation
    // For now, we'll show instructions
    showDialog(
      context: context,
      builder: (context) => _buildWiFiInstructionsDialog(),
    );
  }

  Widget _buildWiFiInstructionsDialog() {
    return Dialog(
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dialog Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2C2C2E),
                    Color(0xFF1C1C1E),
                    Color(0xFF2C2C2E),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4A574),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.wifi_outlined,
                      color: Color(0xFF2C2C2E),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Connect to WiFi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Dialog Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To use IP Tools, please connect to a WiFi network:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.headlineLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildInstructionStep(
                    '1',
                    'Open your device Settings',
                    Icons.settings,
                  ),
                  _buildInstructionStep(
                    '2',
                    'Navigate to WiFi or Network settings',
                    Icons.wifi,
                  ),
                  _buildInstructionStep(
                    '3',
                    'Select and connect to a WiFi network',
                    Icons.wifi_lock,
                  ),
                  _buildInstructionStep(
                    '4',
                    'Return to IP Tools - it will detect the connection automatically',
                    Icons.check_circle,
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4A574).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFD4A574).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFFD4A574),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Network scanning requires an active WiFi connection to discover devices on your local network.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Got it',
                          style: TextStyle(
                            color: Color(0xFFD4A574),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: const Color(0xFFD4A574), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
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
                    child: GestureDetector(
                      onTap: () {
                        // Depending on routing, might want to pop or handle differently
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
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
                              0xFF656CEB,
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
                              color: Color(0xFFEEEDFF),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.wifi_off_rounded,
                                color: Color(0xFF656CEB),
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
                                    0xFF656CEB,
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
                              backgroundColor: const Color(0xFF656CEB),
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
