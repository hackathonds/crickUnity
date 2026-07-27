import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_typography.dart';

class AppScatterPoint {
  final double x;
  final double y;
  final String label;

  const AppScatterPoint({
    required this.x,
    required this.y,
    required this.label,
  });
}

/// DS §3.3 names Manhattan/Worm/Wagon wheel/Radar explicitly but not a
/// scatter plot; PRD §5.7 ("SR vs Avg scatter per bowling type faced")
/// still needs one, so this follows the same general shell conventions
/// (colors.primary dots, caption-styled axis labels) as the other E13-01
/// primitives rather than inventing a new visual language.
class AppScatterChart extends StatelessWidget {
  final List<AppScatterPoint> points;
  final double maxX;
  final double maxY;
  final String xAxisLabel;
  final String yAxisLabel;

  const AppScatterChart({
    super.key,
    required this.points,
    required this.maxX,
    required this.maxY,
    required this.xAxisLabel,
    required this.yAxisLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return CustomPaint(
      painter: _ScatterPainter(
        points: points,
        maxX: maxX,
        maxY: maxY,
        xAxisLabel: xAxisLabel,
        yAxisLabel: yAxisLabel,
        colors: colors,
      ),
      size: Size.infinite,
    );
  }
}

class _ScatterPainter extends CustomPainter {
  final List<AppScatterPoint> points;
  final double maxX;
  final double maxY;
  final String xAxisLabel;
  final String yAxisLabel;
  final AppColors colors;

  const _ScatterPainter({
    required this.points,
    required this.maxX,
    required this.maxY,
    required this.xAxisLabel,
    required this.yAxisLabel,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const padding = 24.0;
    final plotWidth = size.width - padding;
    final plotHeight = size.height - padding;

    canvas.drawLine(
      Offset(padding, 0),
      Offset(padding, plotHeight),
      Paint()
        ..color = colors.divider
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(padding, plotHeight),
      Offset(size.width, plotHeight),
      Paint()
        ..color = colors.divider
        ..strokeWidth = 1,
    );

    for (final point in points) {
      final dx = padding + plotWidth * (point.x / maxX).clamp(0.0, 1.0);
      final dy = plotHeight * (1 - (point.y / maxY).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(dx, dy), 6, Paint()..color = colors.primary);

      final labelPainter = TextPainter(
        text: TextSpan(
          text: point.label,
          style: AppTypography.caption.copyWith(color: colors.textSecondary),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(canvas, Offset(dx + 8, dy - 8));
    }

    final xLabelPainter = TextPainter(
      text: TextSpan(
        text: xAxisLabel,
        style: AppTypography.caption.copyWith(color: colors.textTertiary),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    xLabelPainter.paint(
      canvas,
      Offset(padding + (plotWidth - xLabelPainter.width) / 2, plotHeight + 4),
    );

    canvas.save();
    canvas.translate(0, plotHeight / 2 + 20);
    canvas.rotate(-1.5708);
    final yLabelPainter = TextPainter(
      text: TextSpan(
        text: yAxisLabel,
        style: AppTypography.caption.copyWith(color: colors.textTertiary),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    yLabelPainter.paint(canvas, Offset(-yLabelPainter.width / 2, 0));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScatterPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.colors != colors;
}
