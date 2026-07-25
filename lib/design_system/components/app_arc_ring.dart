import 'dart:math' as math;

import 'package:flutter/material.dart';

/// DS §2.1 "The Arc" — the brand's one recurring geometric signature: a
/// ¾-arc progress ring, gap centered at canvas angle 45° (bottom-right).
/// Extracted from `AppAvatar`'s level ring (E0-07) on its second caller
/// (Progress Card) rather than duplicated — a dumb, stateless painter;
/// any animation (pulses, fill-sweeps) is orchestration layered on top by
/// each specific caller.
class AppArcRing extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color trackColor;
  final Color fillColor;

  const AppArcRing({
    super.key,
    required this.progress,
    required this.size,
    required this.trackColor,
    required this.fillColor,
    this.strokeWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ArcRingPainter(
          progress: progress,
          strokeWidth: strokeWidth,
          trackColor: trackColor,
          fillColor: fillColor,
        ),
      ),
    );
  }
}

class _ArcRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color fillColor;

  _ArcRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.fillColor,
  });

  static const double _sweepStart = math.pi / 2;
  static const double _totalSweep = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _sweepStart, _totalSweep, false, track);

    if (progress > 0) {
      final fill = Paint()
        ..color = fillColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        rect,
        _sweepStart,
        _totalSweep * progress.clamp(0.0, 1.0),
        false,
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArcRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.fillColor != fillColor;
  }
}
