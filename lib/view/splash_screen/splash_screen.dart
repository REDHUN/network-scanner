import 'package:flutter/material.dart';
import 'package:ip_tools/service/network_connectivity_service/network_connectivity_service.dart';
import 'package:ip_tools/service/permission_manager/permission_manager.dart';
import 'package:ip_tools/view/app_wrapper/app_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000), // Speed up fade
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800), // Speed up scale
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Start animations and checks
    _startAnimationsAndChecks();
  }

  Future<void> _startAnimationsAndChecks() async {
    // Start fade and scale animations
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _scaleController.forward();

    // Perform checks and wait for at least the splash duration
    bool isWiFiConnected = false;
    bool shouldShowPermissionScreen = false;

    // Run the initialization logic and the minimum splash duration concurrently
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 1800)),
      () async {
        try {
          // Check WiFi (with a 5 second timeout)
          isWiFiConnected = await _connectivityService
              .isWifiConnected()
              .timeout(
                const Duration(seconds: 5),
                onTimeout: () => true, // Default to true if timeout
              );

          // If WiFi is connected, check permissions
          if (isWiFiConnected) {
            shouldShowPermissionScreen =
                await PermissionManager.shouldShowLocationPermissionScreen();
          }
        } catch (e) {
          // On error, default to true for WiFi to allow proceeding
          isWiFiConnected = true;
          shouldShowPermissionScreen = false;
        }
      }(),
    ]);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => AppWrapper(
            initialIsWiFiConnected: isWiFiConnected,
            initialShouldShowPermissionScreen: shouldShowPermissionScreen,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFF8F9FA), // Soft light background like the image
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const Spacer(flex: 3),

                // App Icon and Branding Section
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Column(
                              children: [
                                // Icon with rounded background
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFEEEEF8,
                                    ), // Light blueish background
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: const Color(0xFFDEDEF2),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons
                                          .account_tree_rounded, // Approximate icon
                                      size: 60,
                                      color: Color(
                                        0xFF656CEB,
                                      ), // Icon color from image
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // App Name Parts inline
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    const Text(
                                      'IP TOOLS: ',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1C1C1E),
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const Text(
                                      'Network\nScanner',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: Color(
                                          0xFF656CEB,
                                        ), // Match button/icon color
                                        letterSpacing: -0.5,
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Enhanced Tagline
                                const Text(
                                  'NETWORK INTELLIGENCE',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6B7280), // Slate gray
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                const Spacer(flex: 4),

                // Bottom Section (just version now)
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          // Version tag
                          Text(
                            'v1.0.0',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(
                                0xFF6B7280,
                              ).withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
