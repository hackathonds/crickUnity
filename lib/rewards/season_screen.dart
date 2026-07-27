import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'level_up_ceremony_overlay.dart';
import 'rewards_provider.dart';
import 'season_models.dart';

/// PRD §13.2: "Season rewards: end-of-season tier (Bronze->Legend by
/// season XP) with exclusive profile frames."
class SeasonScreen extends ConsumerWidget {
  const SeasonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final rewards = ref.watch(rewardsProvider);
    final notifier = ref.read(rewardsProvider.notifier);
    final tier = rewards.seasonTier;
    final next = nextSeasonTierAfter(tier);

    return Scaffold(
      appBar: AppBar(title: const Text('Season')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            seasonTierLabels[tier]!,
            key: const ValueKey('seasonTierText'),
            style: AppTypography.display.copyWith(color: colors.textPrimary),
          ),
          Text(
            '${rewards.seasonXp} season XP',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: colors.coin),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Exclusive frame: ${seasonTierFrames[tier]}',
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (next != null) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (rewards.seasonXp / thresholdFor(next)).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: colors.border,
                color: colors.coin,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Next: ${seasonTierLabels[next]} at ${thresholdFor(next)} season XP',
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          AppButton(
            key: const ValueKey('rolloverSeasonButton'),
            variant: AppButtonVariant.secondary,
            label: 'End season now (debug)',
            fullWidth: true,
            onPressed: () {
              notifier.rolloverSeason();
              final ceremony = notifier.dequeueNextCeremony();
              if (ceremony != null) showCeremony(context, ceremony);
            },
          ),
        ],
      ),
    );
  }
}
