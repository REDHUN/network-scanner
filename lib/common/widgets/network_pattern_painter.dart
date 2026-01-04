import 'package:flutter/material.dart';
import 'dart:math' as math;

class NetworkPatternPainter extends CustomPainter {
  final bool isDarkTheme;

  NetworkPatternPainter({this.isDarkTheme = false});

  @override
  void paint(Canvas canvas, Size size) {
    // Adjust colors based on theme
    final baseColor = isDarkTheme ? Colors.white : Colors.black;

    final paint = Paint()
      ..color = baseColor.withValues(alpha: isDarkTheme ? 0.15 : 0.08)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = baseColor.withValues(alpha: isDarkTheme ? 0.2 : 0.1)
      ..style = PaintingStyle.fill;

    // Draw network nodes (circles)
    final nodes = [
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.7, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.7),
      Offset(size.width * 0.3, size.height * 0.8),
      Offset(size.width * 0.1, size.height * 0.6),
    ];

    // Draw connections between nodes
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final distance = (nodes[i] - nodes[j]).distance;
        if (distance < size.width * 0.6) {
          canvas.drawLine(nodes[i], nodes[j], paint);
        }
      }
    }

    // Draw nodes
    for (final node in nodes) {
      canvas.drawCircle(node, 4, dotPaint);
    }

    // Draw floating geometric shapes
    final shapePaint = Paint()
      ..color = baseColor.withValues(alpha: isDarkTheme ? 0.12 : 0.06)
      ..style = PaintingStyle.fill;

    // Draw triangles
    final trianglePath = Path();
    trianglePath.moveTo(size.width * 0.9, size.height * 0.1);
    trianglePath.lineTo(size.width * 0.95, size.height * 0.2);
    trianglePath.lineTo(size.width * 0.85, size.height * 0.2);
    trianglePath.close();
    canvas.drawPath(trianglePath, shapePaint);

    // Draw hexagon
    final hexPath = Path();
    final center = Offset(size.width * 0.1, size.height * 0.2);
    final radius = 15.0;
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi * 2) / 6;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        hexPath.moveTo(x, y);
      } else {
        hexPath.lineTo(x, y);
      }
    }
    hexPath.close();
    canvas.drawPath(hexPath, shapePaint);

    // Draw wave pattern
    final wavePaint = Paint()
      ..color = baseColor.withValues(alpha: isDarkTheme ? 0.1 : 0.05)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final wavePath = Path();
    wavePath.moveTo(0, size.height * 0.5);

    for (double x = 0; x <= size.width; x += 20) {
      final y =
          size.height * 0.5 + 10 * math.sin((x / size.width) * 4 * math.pi);
      wavePath.lineTo(x, y);
    }
    canvas.drawPath(wavePath, wavePaint);

    // Add additional network-specific elements
    _drawSignalWaves(canvas, size, baseColor);
    _drawDataPackets(canvas, size, baseColor);
  }

  void _drawSignalWaves(Canvas canvas, Size size, Color baseColor) {
    final signalPaint = Paint()
      ..color = baseColor.withValues(alpha: isDarkTheme ? 0.08 : 0.04)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw concentric circles representing signal waves
    final center = Offset(size.width * 0.6, size.height * 0.4);
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, i * 20.0, signalPaint);
    }
  }

  void _drawDataPackets(Canvas canvas, Size size, Color baseColor) {
    final packetPaint = Paint()
      ..color = baseColor.withValues(alpha: isDarkTheme ? 0.1 : 0.05)
      ..style = PaintingStyle.fill;

    // Draw small rectangles representing data packets
    final packets = [
      Rect.fromLTWH(size.width * 0.4, size.height * 0.6, 8, 4),
      Rect.fromLTWH(size.width * 0.6, size.height * 0.3, 6, 3),
      Rect.fromLTWH(size.width * 0.2, size.height * 0.4, 7, 3.5),
    ];

    for (final packet in packets) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(packet, const Radius.circular(1)),
        packetPaint,
      );
    }
  }

  @override
  bool shouldRepaint(NetworkPatternPainter oldDelegate) =>
      isDarkTheme != oldDelegate.isDarkTheme;
}

class SimpleNetworkPatternPainter extends CustomPainter {
  final bool isDarkTheme;

  SimpleNetworkPatternPainter({this.isDarkTheme = false});

  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = isDarkTheme ? Colors.white : Colors.grey.shade300;

    final paint = Paint()
      ..color = baseColor.withValues(alpha: isDarkTheme ? 0.03 : 0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = baseColor.withValues(alpha: isDarkTheme ? 0.05 : 0.08)
      ..style = PaintingStyle.fill;

    // Draw simple grid pattern
    for (double x = 0; x <= size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw a few simple dots
    final dots = [
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.7, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.7),
      Offset(size.width * 0.3, size.height * 0.8),
    ];

    for (final dot in dots) {
      canvas.drawCircle(dot, 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(SimpleNetworkPatternPainter oldDelegate) =>
      isDarkTheme != oldDelegate.isDarkTheme;
}

class SettingsPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final shapePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    // Draw diagonal lines pattern
    for (double i = -size.height; i < size.width + size.height; i += 30) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }

    // Draw gear/settings icons pattern
    _drawGear(
      canvas,
      Offset(size.width * 0.15, size.height * 0.2),
      12,
      shapePaint,
    );
    _drawGear(
      canvas,
      Offset(size.width * 0.85, size.height * 0.7),
      8,
      shapePaint,
    );
    _drawGear(
      canvas,
      Offset(size.width * 0.7, size.height * 0.3),
      10,
      shapePaint,
    );

    // Draw scattered dots
    final dots = [
      Offset(size.width * 0.3, size.height * 0.6),
      Offset(size.width * 0.6, size.height * 0.8),
      Offset(size.width * 0.9, size.height * 0.4),
      Offset(size.width * 0.4, size.height * 0.1),
    ];

    for (final dot in dots) {
      canvas.drawCircle(dot, 2, dotPaint);
    }

    // Draw toggle switch shapes
    _drawToggle(
      canvas,
      Offset(size.width * 0.2, size.height * 0.8),
      shapePaint,
    );
    _drawToggle(
      canvas,
      Offset(size.width * 0.8, size.height * 0.1),
      shapePaint,
    );
  }

  void _drawGear(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const teeth = 8;
    const outerRadius = 1.0;
    const innerRadius = 0.7;

    for (int i = 0; i < teeth * 2; i++) {
      final angle = (i * math.pi) / teeth;
      final r = (i % 2 == 0) ? outerRadius : innerRadius;
      final x = center.dx + radius * r * math.cos(angle);
      final y = center.dy + radius * r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);

    // Draw center hole
    canvas.drawCircle(center, radius * 0.3, paint);
  }

  void _drawToggle(Canvas canvas, Offset center, Paint paint) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 16, height: 8),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, paint);

    // Draw toggle circle
    canvas.drawCircle(Offset(center.dx + 4, center.dy), 3, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
