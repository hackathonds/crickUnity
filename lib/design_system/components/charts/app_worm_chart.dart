import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';

/// DS §3.3: "Worm: 2px lines, chasing overlay dashed for required-rate."
/// Generic over a plain value series plus an optional dashed reference
/// line, so the same widget serves both the runs-worm (cumulative runs
/// per over, dashed required-run-rate target) and E13-01's "win-prob
/// worm" (win probability % per over, dashed 50% baseline) rather than
/// two near-duplicate painters.
class AppWormChart extends StatelessWidget {
  final List<double> values;
  final double? referenceLine;
  final double minY;
  final double maxY;

  const AppWormChart({
    super.key,
    required this.values,
    this.referenceLine,
    this.minY = 0,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return CustomPaint(
      painter: _WormPainter(
        values: values,
        referenceLine: referenceLine,
        minY: minY,
        maxY: maxY,
        lineColor: colors.primary,
        referenceColor: colors.textTertiary,
      ),
      size: Size.infinite,
    );
  }
}

class _WormPainter extends CustomPainter {
  final List<double> values;
  final double? referenceLine;
  final double minY;
  final double maxY;
  final Color lineColor;
  final Color referenceColor;

  const _WormPainter({
    required this.values,
    required this.referenceLine,
    required this.minY,
    required this.maxY,
    required this.lineColor,
    required this.referenceColor,
  });

  double _yFor(double value, double height) {
    final span = (maxY - minY).clamp(1, double.infinity);
    final fraction = ((value - minY) / span).clamp(0.0, 1.0);
    return height * (1 - fraction);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final dx = size.width / (values.length - 1);

    if (referenceLine != null) {
      final y = _yFor(referenceLine!, size.height);
      final dashPaint = Paint()
        ..color = referenceColor
        ..strokeWidth = 1;
      var x = 0.0;
      while (x < size.width) {
        canvas.drawLine(Offset(x, y), Offset(x + 6, y), dashPaint);
        x += 10;
      }
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(0, _yFor(values.first, size.height));
    for (var i = 1; i < values.length; i++) {
      path.lineTo(i * dx, _yFor(values[i], size.height));
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _WormPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.referenceLine != referenceLine;
}
