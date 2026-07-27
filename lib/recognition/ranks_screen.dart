import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../rewards/rewards_provider.dart';
import 'rank_models.dart';
import 'ranks_provider.dart';

/// PRD §18: "rank != level (rank = skill, level = journey) -- explained
/// in-product." Rendered as its own prominent explainer card, the one
/// thing this screen must not let read as interchangeable with Level.
class RanksScreen extends ConsumerWidget {
  const RanksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final profiles = ref.watch(ranksProvider).profiles;
    final notifier = ref.read(ranksProvider.notifier);
    final level = ref.watch(rewardsProvider).level;

    return Scaffold(
      appBar: AppBar(title: const Text('Ranks')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            key: const ValueKey('rankVsLevelExplainer'),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rank ≠ Level',
                  style: AppTypography.subtitle.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Rank reflects your skill percentile among peers in the '
                  'same city, format, and discipline. Level (currently '
                  '$level) reflects your total journey and never goes '
                  'down. They move independently.',
                  style: AppTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final profile in profiles)
            Container(
              key: ValueKey('rankCard_${profile.discipline.name}'),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${rankDisciplineLabels[profile.discipline]} · '
                    '${profile.cityLabel} · ${profile.formatLabel}',
                    style: AppTypography.label.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      AppTagChip(
                        label: rankBandLabels[profile.currentBand()]!,
                        variant: AppTagChipVariant.verified,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${profile.percentile}th percentile',
                        style: AppTypography.caption.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  if (profile.isDecayed())
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        'Decayed from inactivity -- historical peak: '
                        '${rankBandLabels[profile.historicalPeakBand]}',
                        style: AppTypography.caption.copyWith(
                          color: colors.warning,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        'Historical peak: '
                        '${rankBandLabels[profile.historicalPeakBand]}',
                        style: AppTypography.caption.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      AppButton(
                        key: ValueKey(
                          'simulateInactivityButton_${profile.discipline.name}',
                        ),
                        variant: AppButtonVariant.tertiary,
                        label: 'Simulate 60d inactive (debug)',
                        onPressed: () =>
                            notifier.simulateInactivity(profile.discipline),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppButton(
                        key: ValueKey(
                          'recordActivityButton_${profile.discipline.name}',
                        ),
                        variant: AppButtonVariant.tertiary,
                        label: 'Record activity (debug)',
                        onPressed: () =>
                            notifier.recordActivity(profile.discipline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
