import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A Material 3-style wavy track for the active network scan.
/// The wave animates independently of the measured (or estimated) scan value.
class WavyScanProgressIndicator extends StatefulWidget {
  const WavyScanProgressIndicator({super.key, required this.value});

  final double value;

  @override
  State<WavyScanProgressIndicator> createState() =>
      _WavyScanProgressIndicatorState();
}

class _WavyScanProgressIndicatorState extends State<WavyScanProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _wave.stop();
    } else if (!_wave.isAnimating) {
      _wave.repeat();
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.value.clamp(0.0, 1.0);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Scan progress',
      value: '${(progress * 100).round()}%',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: progress),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, displayedValue, _) => SizedBox(
          height: 18,
          width: double.infinity,
          child: CustomPaint(
            painter: _WavyProgressPainter(
              value: displayedValue,
              wave: _wave,
              activeColor: scheme.primary,
              trackColor: scheme.onPrimaryContainer.withValues(alpha: 0.15),
            ),
          ),
        ),
      ),
    );
  }
}

class _WavyProgressPainter extends CustomPainter {
  _WavyProgressPainter({
    required this.value,
    required this.wave,
    required this.activeColor,
    required this.trackColor,
  }) : super(repaint: wave);

  final double value;
  final Animation<double> wave;
  final Color activeColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final width = math.max(0.0, size.width - 8);
    final centerY = size.height / 2;
    final startX = 4.0;
    final track = Paint()
      ..color = trackColor
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(startX, centerY),
      Offset(startX + width, centerY),
      track,
    );

    final end = width * value.clamp(0.0, 1.0);
    if (end <= 0) return;
    final path = Path();
    for (var x = 0.0; x <= end; x += 2) {
      final y =
          centerY + math.sin(x * math.pi / 16 - wave.value * 2 * math.pi) * 2.5;
      if (x == 0) {
        path.moveTo(startX, y);
      } else {
        path.lineTo(startX + x, y);
      }
    }
    path.lineTo(
      startX + end,
      centerY + math.sin(end * math.pi / 16 - wave.value * 2 * math.pi) * 2.5,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _WavyProgressPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.activeColor != activeColor ||
      oldDelegate.trackColor != trackColor;
}
