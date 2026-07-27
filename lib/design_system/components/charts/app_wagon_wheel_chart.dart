import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';

/// One tagged shot: [sectorIndex] 0-7 around the 8-sector wagon-wheel
/// breakdown (0 = straight down the ground, clockwise from there --
/// callers map their own sector enum to this index), [runs] the batting
/// runs off that shot.
class AppWagonShot {
  final int sectorIndex;
  final int runs;

  const AppWagonShot({required this.sectorIndex, required this.runs});
}

/// DS §3.3: "Wagon wheel: ground-shape aware, 4s in `secondary`, 6s in
/// `accent`, zone-tap filters the ball list below." Ground shape is a
/// plain circle/oval (same "simplified, not photorealistic" convention
/// as the field map elsewhere in this session) with 8 radial zone
/// wedges; wedge fill intensity reflects shot count, dots mark
/// individual shots colored by whether they were a four/six/other.
class AppWagonWheelChart extends StatelessWidget {
  final List<AppWagonShot> shots;
  final ValueChanged<int>? onZoneTap;

  const AppWagonWheelChart({super.key, required this.shots, this.onZoneTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onTapUp: onZoneTap == null
              ? null
              : (details) => onZoneTap!(_zoneAt(details.localPosition, size)),
          child: CustomPaint(
            painter: _WagonPainter(shots: shots, colors: colors),
            size: size,
          ),
        );
      },
    );
  }

  int _zoneAt(Offset local, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final vector = local - center;
    final angle =
        (math.atan2(vector.dx, -vector.dy) + 2 * math.pi) % (2 * math.pi);
    return (angle / (2 * math.pi / 8)).floor().clamp(0, 7);
  }
}

class _WagonPainter extends CustomPainter {
  final List<AppWagonShot> shots;
  final AppColors colors;

  const _WagonPainter({required this.shots, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;

    // Ground boundary -- plain oval, not photorealistic (session
    // convention, e.g. the field map's own plain oval).
    canvas.drawOval(
      Rect.fromCircle(center: center, radius: radius),
      Paint()
        ..color = colors.divider
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final counts = List.filled(8, 0);
    for (final s in shots) {
      counts[s.sectorIndex]++;
    }
    final maxCount = counts.fold(0, (a, b) => a > b ? a : b).clamp(1, 1 << 30);
    const sectorAngle = 2 * math.pi / 8;

    for (var i = 0; i < 8; i++) {
      final startAngle = i * sectorAngle - math.pi / 2 - sectorAngle / 2;
      final intensity = counts[i] / maxCount;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sectorAngle,
        true,
        Paint()
          ..color = colors.primary.withValues(alpha: 0.08 + 0.22 * intensity),
      );
    }

    for (final s in shots) {
      final angle = s.sectorIndex * sectorAngle - math.pi / 2;
      final r = radius * 0.85;
      final point = center + Offset(math.sin(angle) * r, -math.cos(angle) * r);
      final color = s.runs >= 6
          ? colors.accent
          : s.runs == 4
          ? colors.secondary
          : colors.textTertiary;
      canvas.drawCircle(point, 4, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _WagonPainter oldDelegate) =>
      oldDelegate.shots != shots || oldDelegate.colors != colors;
}
