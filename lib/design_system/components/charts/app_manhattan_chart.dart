import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';

/// DS §3.3: "Manhattan: bar width = (plot/overs)−2 gap, wicket dots 6 on
/// top." One of the 23 individual chart visualizations E13-01 plugs into
/// the shared [AppChartShell] (E0-08 built the shell; this is the plot).
/// Generic over `(int runs, int wickets)` per over so it has no
/// dependency on any feature module's domain models.
class AppManhattanChart extends StatelessWidget {
  final List<(int runs, int wickets)> perOver;

  const AppManhattanChart({super.key, required this.perOver});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return CustomPaint(
      painter: _ManhattanPainter(perOver: perOver, colors: colors),
      size: Size.infinite,
    );
  }
}

class _ManhattanPainter extends CustomPainter {
  final List<(int runs, int wickets)> perOver;
  final AppColors colors;

  const _ManhattanPainter({required this.perOver, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (perOver.isEmpty) return;
    const gap = 2.0;
    final overs = perOver.length;
    final slot = size.width / overs;
    final barWidth = (slot - gap).clamp(1.0, slot);
    final maxRuns = perOver
        .map((e) => e.$1)
        .fold(1, (a, b) => a > b ? a : b)
        .toDouble();

    final barPaint = Paint()..color = colors.primary;
    final dotPaint = Paint()..color = colors.error;

    for (var i = 0; i < overs; i++) {
      final (runs, wickets) = perOver[i];
      final barHeight = size.height * 0.75 * (runs / maxRuns);
      final left = i * slot + (slot - barWidth) / 2;
      canvas.drawRect(
        Rect.fromLTWH(left, size.height - barHeight, barWidth, barHeight),
        barPaint,
      );
      for (var w = 0; w < wickets; w++) {
        canvas.drawCircle(
          Offset(left + barWidth / 2, size.height - barHeight - 6 - w * 12),
          3,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ManhattanPainter oldDelegate) =>
      oldDelegate.perOver != perOver || oldDelegate.colors != colors;
}
