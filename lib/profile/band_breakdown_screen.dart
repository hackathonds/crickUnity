import 'package:flutter/material.dart';

import '../design_system/components/app_band_chip.dart';
import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'trust_sportsmanship_models.dart';

/// DS §11.5: "Self breakdown screen (from Profile → band tap): factor
/// rows with personal trend sparklines + 'how to improve' plain-language
/// rows; 90-day decay-forgiveness explainer; appeal link where
/// applicable. Never visible on public profile beyond band."
///
/// PRD §5.15: the 90-day decay-forgiveness explainer only applies to
/// Trust; only Sportsmanship is "Appealable (§17)" -- [cleanDaysCount]
/// and [appealable] are therefore each independently gated, rather than
/// one screen assuming both always apply. The §17 dispute-review flow
/// itself is a separate future epic -- appealing here just explains
/// where that flow lives rather than half-wiring a real submission.
class BandBreakdownScreen extends StatelessWidget {
  final BandKind kind;
  final String bandLabel;
  final bool isUnderReview;
  final List<BandFactor> factors;
  final int? cleanDaysCount;
  final bool appealable;

  const BandBreakdownScreen({
    super.key,
    required this.kind,
    required this.bandLabel,
    required this.factors,
    this.isUnderReview = false,
    this.cleanDaysCount,
    this.appealable = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final title = kind == BandKind.trust
        ? 'Trust score'
        : 'Sportsmanship score';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppBandChip(
            key: const ValueKey('bandBreakdownChip'),
            kind: kind,
            label: bandLabel,
            isUnderReview: isUnderReview,
          ),
          if (cleanDaysCount != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Drops decay-forgiven over 90 clean days -- '
              '$cleanDaysCount of 90 so far.',
              key: const ValueKey('bandDecayExplainer'),
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          for (final factor in factors)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _FactorRow(factor: factor),
            ),
          if (appealable) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const ValueKey('bandAppealButton'),
              variant: AppButtonVariant.secondary,
              label: 'Appeal this score',
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Appeals go through dispute review -- that flow isn\'t '
                    'built yet.',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  final BandFactor factor;

  const _FactorRow({required this.factor});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                factor.label,
                style: AppTypography.subtitle.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                factor.howToImprove,
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        _Sparkline(
          key: ValueKey('sparkline_${factor.label}'),
          trend: factor.trend,
          color: colors.textSecondary,
        ),
      ],
    );
  }
}

/// A minimal trend line -- shape only, no axis/numeric labels, since this
/// screen never renders a raw score (backlog AC).
class _Sparkline extends StatelessWidget {
  final List<double> trend;
  final Color color;

  const _Sparkline({super.key, required this.trend, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 24,
      child: CustomPaint(
        painter: _SparklinePainter(trend: trend, color: color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> trend;
  final Color color;

  const _SparklinePainter({required this.trend, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (trend.length < 2) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (var i = 0; i < trend.length; i++) {
      final x = size.width * i / (trend.length - 1);
      final y = size.height * (1 - trend[i].clamp(0, 1));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.trend != trend || oldDelegate.color != color;
}
