import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_typography.dart';

class AppPieSlice {
  final String label;
  final double value;
  final Color color;

  const AppPieSlice({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// DS §3.3 names Manhattan/Worm/Wagon wheel/Radar explicitly but not a
/// pie chart; PRD §5.7 ("dismissal-type pie") still needs one, so this
/// follows the shared donut-style convention already used for expense
/// category breakdowns elsewhere (a simplified ring, not a full
/// illustrative pie) rather than inventing a new visual language.
class AppPieChart extends StatelessWidget {
  final List<AppPieSlice> slices;

  const AppPieChart({super.key, required this.slices});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return CustomPaint(
      painter: _PiePainter(slices: slices, colors: colors),
      size: Size.infinite,
    );
  }
}

class _PiePainter extends CustomPainter {
  final List<AppPieSlice> slices;
  final AppColors colors;

  const _PiePainter({required this.slices, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold(0.0, (a, s) => a + s.value);
    if (total <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;

    var startAngle = -math.pi / 2;
    for (final slice in slices) {
      final sweep = 2 * math.pi * (slice.value / total);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        true,
        Paint()..color = slice.color,
      );
      startAngle += sweep;
    }

    canvas.drawCircle(center, radius * 0.55, Paint()..color = colors.surface);

    final label = TextPainter(
      text: TextSpan(
        text: total.toStringAsFixed(0),
        style: AppTypography.stat.copyWith(color: colors.textPrimary),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(
      canvas,
      Offset(center.dx - label.width / 2, center.dy - label.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) =>
      oldDelegate.slices != slices || oldDelegate.colors != colors;
}
