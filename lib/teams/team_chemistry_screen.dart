import 'package:flutter/material.dart';

import '../design_system/components/app_arc_ring.dart';
import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/icons/app_icon.dart';
import '../design_system/icons/app_icon_id.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'team_chemistry_models.dart';

/// DS §11.6: "Chemistry card (captain, Team Stats): composite ring + 4
/// factor bars + 12-week trendline; insight row ('4 unsettled expenses
/// >2w -- main drag'); team-private lock icon in header." PRD §6.28: team
/// scoped, captain-only.
class TeamChemistryScreen extends StatelessWidget {
  final bool viewerIsCaptain;
  final TeamChemistry chemistry;

  const TeamChemistryScreen({
    super.key,
    required this.viewerIsCaptain,
    required this.chemistry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    if (!viewerIsCaptain) {
      return Scaffold(
        appBar: AppBar(title: const Text('Team chemistry')),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppEmptyState(
            key: const ValueKey('chemistryPermissionDenied'),
            message: 'Team chemistry is only visible to your team\'s Captain.',
            primaryLabel: 'Back',
            onPrimary: () => Navigator.of(context).maybePop(),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Team chemistry'),
            const SizedBox(width: AppSpacing.sm),
            AppIcon(
              key: const ValueKey('chemistryPrivateLock'),
              id: AppIconId.locked,
              semanticLabel: 'Team-private',
              color: colors.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AppArcRing(
                    key: const ValueKey('chemistryCompositeRing'),
                    progress: chemistry.compositeScore,
                    size: 140,
                    strokeWidth: 10,
                    trackColor: colors.border,
                    fillColor: colors.primary,
                  ),
                  Text(
                    '${(chemistry.compositeScore * 100).round()}%',
                    style: AppTypography.h1.copyWith(color: colors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          for (final factor in chemistry.factors)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: _FactorBar(
                key: ValueKey('chemistryFactor_${factor.kind.name}'),
                factor: factor,
              ),
            ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            '12-week trend',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          _TrendLine(
            key: const ValueKey('chemistryTrendLine'),
            points: chemistry.weeklyTrend,
            color: chemistry.trendPercent >= 0 ? colors.success : colors.error,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            key: const ValueKey('chemistryInsightRow'),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '${chemistry.trendPercent >= 0 ? "Up" : "Down"} '
              '${chemistry.trendPercent.abs()}% this month -- '
              '${chemistry.insightText}',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _FactorBar extends StatelessWidget {
  final ChemistryFactor factor;

  const _FactorBar({super.key, required this.factor});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Row(
      children: [
        Expanded(
          child: Text(
            factor.label,
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              value: factor.value,
              minHeight: 8,
              backgroundColor: colors.border,
              color: colors.primary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 40,
          child: Text(
            '${(factor.value * 100).round()}%',
            textAlign: TextAlign.right,
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
        ),
      ],
    );
  }
}

/// A minimal 12-point trend line -- shape only, matching the sparkline
/// precedent in `lib/profile/band_breakdown_screen.dart`.
class _TrendLine extends StatelessWidget {
  final List<double> points;
  final Color color;

  const _TrendLine({super.key, required this.points, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: CustomPaint(
        painter: _TrendLinePainter(points: points, color: color),
      ),
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  final List<double> points;
  final Color color;

  const _TrendLinePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * i / (points.length - 1);
      final y = size.height * (1 - points[i].clamp(0, 1));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}
