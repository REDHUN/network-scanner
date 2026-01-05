import 'package:flutter/material.dart';

class AppIcon extends StatelessWidget {
  final double size;
  final bool showStatusIndicator;
  final Color? backgroundColor;
  final Color? primaryColor;

  const AppIcon({
    super.key,
    this.size = 120,
    this.showStatusIndicator = true,
    this.backgroundColor,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? const Color(0xFF2C2C2E);
    final accentColor = primaryColor ?? const Color(0xFFD4A574);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size * 0.233), // 28/120 ratio
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: size * 0.167, // 20/120 ratio
            offset: Offset(0, size * 0.067), // 8/120 ratio
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background gradient overlay
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.233),
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [
                  accentColor.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Network topology with interconnected nodes
          CustomPaint(
            size: Size(size, size),
            painter: NetworkTopologyPainter(
              accentColor: accentColor,
              size: size,
            ),
          ),

          // Status indicator
          if (showStatusIndicator)
            Positioned(
              top: size * 0.15, // 18/120 ratio
              right: size * 0.15,
              child: Container(
                width: size * 0.083, // 10/120 ratio
                height: size * 0.083,
                decoration: BoxDecoration(
                  color: const Color(0xFF30A46C),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: bgColor,
                    width: size * 0.017, // 2/120 ratio
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class NetworkTopologyPainter extends CustomPainter {
  final Color accentColor;
  final double size;

  NetworkTopologyPainter({required this.accentColor, required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final radius = size * 0.35; // Main network radius

    // Paint for connections
    final connectionPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.4)
      ..strokeWidth =
          size *
          0.015 // 1.8/120 ratio
      ..style = PaintingStyle.stroke;

    // Paint for nodes
    final nodePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final nodeStrokePaint = Paint()
      ..color = accentColor
      ..strokeWidth = size * 0.01
      ..style = PaintingStyle.stroke;

    // Define network node positions (12 nodes in a complex topology)
    final List<Offset> networkNodes = [
      // Top layer (3 nodes)
      Offset(center.dx, center.dy - radius * 0.9), // Top center
      Offset(center.dx - radius * 0.7, center.dy - radius * 0.6), // Top left
      Offset(center.dx + radius * 0.7, center.dy - radius * 0.6), // Top right
      // Middle layer (4 nodes)
      Offset(center.dx - radius * 0.9, center.dy), // Middle left
      Offset(center.dx - radius * 0.3, center.dy), // Middle left-center
      Offset(center.dx + radius * 0.3, center.dy), // Middle right-center
      Offset(center.dx + radius * 0.9, center.dy), // Middle right
      // Bottom layer (3 nodes)
      Offset(center.dx - radius * 0.7, center.dy + radius * 0.6), // Bottom left
      Offset(
        center.dx + radius * 0.7,
        center.dy + radius * 0.6,
      ), // Bottom right
      Offset(center.dx, center.dy + radius * 0.9), // Bottom center
      // Inner nodes (2 nodes)
      Offset(center.dx - radius * 0.2, center.dy - radius * 0.3), // Inner left
      Offset(center.dx + radius * 0.2, center.dy + radius * 0.3), // Inner right
    ];

    // Draw complex network connections
    final List<List<int>> connections = [
      // Top layer connections
      [0, 1], [0, 2], [1, 2],
      // Top to middle connections
      [0, 4], [0, 5], [1, 3], [1, 4], [2, 5], [2, 6],
      // Middle layer connections
      [3, 4], [4, 5], [5, 6],
      // Middle to bottom connections
      [3, 7], [4, 7], [5, 8], [6, 8], [4, 9], [5, 9],
      // Bottom layer connections
      [7, 8], [7, 9], [8, 9],
      // Inner node connections
      [10, 4], [10, 5], [11, 4], [11, 5],
      [10, 1], [11, 8],
      // Cross connections for complexity
      [1, 6], [2, 3], [0, 9], [3, 8],
      // Additional mesh connections
      [10, 11], [0, 6], [3, 9],
    ];

    // Draw all connections
    for (final connection in connections) {
      final start = networkNodes[connection[0]];
      final end = networkNodes[connection[1]];
      canvas.drawLine(start, end, connectionPaint);
    }

    // Draw network nodes
    for (int i = 0; i < networkNodes.length; i++) {
      final nodeSize = i < 10
          ? size * 0.04
          : size * 0.035; // Slightly smaller inner nodes

      // Draw node circle
      canvas.drawCircle(networkNodes[i], nodeSize, nodePaint);

      // Draw node border for better definition
      canvas.drawCircle(networkNodes[i], nodeSize, nodeStrokePaint);
    }

    // Draw central devices (computers/devices in the network)
    _drawCentralDevices(canvas, center, size);
  }

  void _drawCentralDevices(Canvas canvas, Offset center, double size) {
    final devicePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.012;

    final deviceFillPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Draw three devices in the center representing networked computers
    final deviceSize = size * 0.08;
    final deviceSpacing = size * 0.12;

    // Top device
    final topDevice = Rect.fromCenter(
      center: Offset(center.dx, center.dy - deviceSpacing * 0.6),
      width: deviceSize,
      height: deviceSize * 0.7,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(topDevice, Radius.circular(size * 0.01)),
      deviceFillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(topDevice, Radius.circular(size * 0.01)),
      devicePaint,
    );

    // Bottom left device
    final leftDevice = Rect.fromCenter(
      center: Offset(
        center.dx - deviceSpacing * 0.5,
        center.dy + deviceSpacing * 0.4,
      ),
      width: deviceSize,
      height: deviceSize * 0.7,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(leftDevice, Radius.circular(size * 0.01)),
      deviceFillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(leftDevice, Radius.circular(size * 0.01)),
      devicePaint,
    );

    // Bottom right device
    final rightDevice = Rect.fromCenter(
      center: Offset(
        center.dx + deviceSpacing * 0.5,
        center.dy + deviceSpacing * 0.4,
      ),
      width: deviceSize,
      height: deviceSize * 0.7,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rightDevice, Radius.circular(size * 0.01)),
      deviceFillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rightDevice, Radius.circular(size * 0.01)),
      devicePaint,
    );

    // Draw connection lines from devices to network
    final deviceConnectionPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.3)
      ..strokeWidth = size * 0.008
      ..style = PaintingStyle.stroke;

    // Connect devices to nearby network nodes
    canvas.drawLine(
      Offset(topDevice.center.dx, topDevice.top),
      Offset(center.dx, center.dy - size * 0.2),
      deviceConnectionPaint,
    );

    canvas.drawLine(
      Offset(leftDevice.center.dx, leftDevice.top),
      Offset(center.dx - size * 0.1, center.dy),
      deviceConnectionPaint,
    );

    canvas.drawLine(
      Offset(rightDevice.center.dx, rightDevice.top),
      Offset(center.dx + size * 0.1, center.dy),
      deviceConnectionPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
