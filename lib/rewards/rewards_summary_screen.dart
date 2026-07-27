import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_avatar.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_coin_chip.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'level_up_ceremony_overlay.dart';
import 'rewards_models.dart';
import 'rewards_provider.dart';

/// E6-01 "engine surfaces" -- a minimal reachable surface for the coin/
/// XP mechanics themselves (balance, level, earning log, ceremony
/// queue). The full polished Wallet & Coins screen (DS §7-53: expiring
/// strip, marketplace, redemption) is E6-05's separate, much larger
/// scope.
class RewardsSummaryScreen extends ConsumerWidget {
  final String viewerName;

  const RewardsSummaryScreen({super.key, required this.viewerName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final rewards = ref.watch(rewardsProvider);
    final notifier = ref.read(rewardsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: AppCoinChip(
              key: const ValueKey('rewardsCoinChip'),
              balance: rewards.coinBalance,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              AppAvatar(
                size: AppAvatarSize.lg,
                name: viewerName,
                levelProgress: levelProgress(rewards.xpTotal),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level ${rewards.level}',
                    key: const ValueKey('rewardsLevelText'),
                    style: AppTypography.h2.copyWith(color: colors.textPrimary),
                  ),
                  Text(
                    '${xpIntoCurrentLevel(rewards.xpTotal)} / '
                    '${xpNeededForNextLevel(rewards.xpTotal)} XP to next level',
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Earning log',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (rewards.log.isEmpty)
            Text(
              'Nothing earned yet.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else
            for (final entry in rewards.log.reversed)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs / 2,
                ),
                child: Text(
                  entry,
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
          if (rewards.ceremonyQueue.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              key: const ValueKey('showNextCeremonyButton'),
              variant: AppButtonVariant.primary,
              label:
                  'Show next ceremony (${rewards.ceremonyQueue.length} queued)',
              fullWidth: true,
              onPressed: () {
                final next = notifier.dequeueNextCeremony();
                if (next != null) {
                  showCeremony(context, next);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
