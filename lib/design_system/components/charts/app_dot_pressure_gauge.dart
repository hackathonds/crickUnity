import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_typography.dart';

/// PRD/DS name no dot-pressure formula or gauge spec -- flagged judgment
/// call, same convention as [InningsState.dotPressureLast]'s own doc
/// comment (matches/scoring_models.dart). A semicircular arc gauge, 0 at
/// the left tip to 100 at the right, banded calm/building/high to match
/// commentary's usual read of dot-ball buildup.
class AppDotPressureGauge extends StatelessWidget {
  final double percent;

  const AppDotPressureGauge({super.key, required this.percent});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return CustomPaint(
      painter: _GaugePainter(percent: percent.clamp(0, 100), colors: colors),
      size: Size.infinite,
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percent;
  final AppColors colors;

  const _GaugePainter({required this.percent, required this.colors});

  Color get _bandColor {
    if (percent >= 60) return colors.error;
    if (percent >= 30) return colors.warning;
    return colors.success;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = math.min(size.width / 2, size.height) - 8;
    const start = math.pi;
    const sweep = math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      Paint()
        ..color = colors.divider.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep * (percent / 100),
      false,
      Paint()
        ..color = _bandColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    final label = TextPainter(
      text: TextSpan(
        text: '${percent.toStringAsFixed(0)}%',
        style: AppTypography.stat.copyWith(color: colors.textPrimary),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(
      canvas,
      Offset(center.dx - label.width / 2, center.dy - radius - label.height),
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.percent != percent || oldDelegate.colors != colors;
}
