import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_typography.dart';

/// DS §3.3: "Radar: max 6 axes, fill 12% opacity." Values are expected
/// pre-normalized to 0.0-1.0 by the caller (each analytics surface knows
/// its own metric's natural range -- this chart only plots what it's
/// given).
class AppRadarChart extends StatelessWidget {
  final Map<String, double> axes;

  const AppRadarChart({super.key, required this.axes})
    : assert(axes.length <= 6, 'DS §3.3: Radar allows max 6 axes');

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return CustomPaint(
      painter: _RadarPainter(axes: axes, colors: colors),
      size: Size.infinite,
    );
  }
}

class _RadarPainter extends CustomPainter {
  final Map<String, double> axes;
  final AppColors colors;

  const _RadarPainter({required this.axes, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final labels = axes.keys.toList();
    final values = axes.values.toList();
    final n = labels.length;
    if (n < 3) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 24;
    final angleStep = 2 * math.pi / n;

    final gridPaint = Paint()
      ..color = colors.divider.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke;
    for (final ring in [0.25, 0.5, 0.75, 1.0]) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final angle = i * angleStep - math.pi / 2;
        final point =
            center + Offset(math.cos(angle), math.sin(angle)) * radius * ring;
        i == 0
            ? path.moveTo(point.dx, point.dy)
            : path.lineTo(point.dx, point.dy);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    final dataPath = Path();
    for (var i = 0; i < n; i++) {
      final angle = i * angleStep - math.pi / 2;
      final value = values[i].clamp(0.0, 1.0);
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * value;
      i == 0
          ? dataPath.moveTo(point.dx, point.dy)
          : dataPath.lineTo(point.dx, point.dy);
    }
    dataPath.close();
    canvas.drawPath(
      dataPath,
      Paint()..color = colors.primary.withValues(alpha: 0.12),
    );
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = colors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    for (var i = 0; i < n; i++) {
      final angle = i * angleStep - math.pi / 2;
      final labelPoint =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius + 14);
      final painter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: AppTypography.caption.copyWith(color: colors.textTertiary),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        labelPoint - Offset(painter.width / 2, painter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.axes != axes || oldDelegate.colors != colors;
}
