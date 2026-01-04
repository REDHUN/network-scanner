import 'package:flutter/material.dart';
import 'package:netra/view/main_navigation/main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _networkController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _networkAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _networkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _networkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _networkController, curve: Curves.easeInOut),
    );

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    // Start fade and scale animations
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _scaleController.forward();

    // Start pulse animation (repeating)
    await Future.delayed(const Duration(milliseconds: 800));
    _pulseController.repeat(reverse: true);

    // Start network animation
    await Future.delayed(const Duration(milliseconds: 500));
    _networkController.forward();

    // Navigate to main screen after total delay
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainNavigation(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _networkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF2C2C2E), const Color(0xFF1C1C1E)]
                : [const Color(0xFFD4A574), const Color(0xFFB8956A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Main Logo Section
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
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFFD4A574)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: isDark ? 0.3 : 0.1,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.network_check,
                                    size: 60,
                                    color: isDark
                                        ? const Color(0xFF2C2C2E)
                                        : const Color(0xFFD4A574),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // App Name
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          'Netra',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -1.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Network Scanner',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 60),

              // Network Animation with enhanced effects
              AnimatedBuilder(
                animation: _networkAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _networkAnimation,
                    child: Column(
                      children: [
                        _buildNetworkAnimation(),
                        const SizedBox(height: 20),
                        // Network status text
                        Text(
                          'Scanning Network...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.7),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const Spacer(flex: 2),

              // Loading Indicator
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Initializing Network Scanner...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.8),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkAnimation() {
    return Container(
      width: 200,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Central Router
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(Icons.router, color: Colors.white, size: 20),
          ),

          // Animated Network Nodes
          ...List.generate(4, (index) {
            final radius = 60.0;
            final x = radius * (index.isEven ? 1 : -1) * 0.7;
            final y = radius * (index < 2 ? -1 : 1) * 0.5;

            return AnimatedBuilder(
              animation: _networkController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    x * _networkAnimation.value,
                    y * _networkAnimation.value,
                  ),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.devices,
                      color: const Color(0xFFD4A574),
                      size: 12,
                    ),
                  ),
                );
              },
            );
          }),

          // Animated Connection Lines
          AnimatedBuilder(
            animation: _networkController,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(200, 80),
                painter: NetworkConnectionPainter(
                  progress: _networkAnimation.value,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class NetworkConnectionPainter extends CustomPainter {
  final double progress;
  final Color color;

  NetworkConnectionPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = 60.0;

    // Draw connection lines from center to nodes
    for (int i = 0; i < 4; i++) {
      final x = radius * (i.isEven ? 1 : -1) * 0.7 * progress;
      final y = radius * (i < 2 ? -1 : 1) * 0.5 * progress;
      final nodePosition = Offset(center.dx + x, center.dy + y);

      canvas.drawLine(center, nodePosition, paint);
    }
  }

  @override
  bool shouldRepaint(NetworkConnectionPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
