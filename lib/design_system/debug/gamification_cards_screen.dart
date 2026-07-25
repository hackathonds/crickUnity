import 'package:flutter/material.dart';

import '../components/app_progress_card.dart';
import '../components/app_reward_card.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// QA tool for E0-08 (sub-task 4/12): [AppRewardCard], [AppProgressCard].
class GamificationCardsScreen extends StatelessWidget {
  const GamificationCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm,
        top: AppSpacing.xxl,
      ),
      child: Text(
        text,
        style: AppTypography.label.copyWith(color: colors.textTertiary),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Gamification cards (QA)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label('Reward Cards — scratch/spin/chest, unclaimed, stacked'),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                AppRewardCard(
                  type: AppRewardType.scratch,
                  unclaimed: true,
                  onTap: () {},
                ),
                AppRewardCard(type: AppRewardType.spin, count: 3, onTap: () {}),
                AppRewardCard(type: AppRewardType.chest, onTap: () {}),
              ],
            ),
            label('Progress Card — ring variant, >=80% pulses once'),
            const AppProgressCard(
              title: 'Century Chase',
              rewardLabel: '+50 XP',
              variant: AppProgressCardVariant.ring,
              progress: 0.85,
              progressCaption: '85/100 runs · 9 days left',
            ),
            const SizedBox(height: AppSpacing.md),
            label('Progress Card — bar variant (target text matters)'),
            const AppProgressCard(
              title: 'Weekly Wickets',
              rewardLabel: '+30 XP',
              variant: AppProgressCardVariant.bar,
              progress: 0.4,
              progressCaption: '4/10 wickets · 3 days left',
            ),
            const SizedBox(height: AppSpacing.md),
            label('Progress Card — failed (desaturated, never shames)'),
            const AppProgressCard(
              title: 'Century Chase',
              rewardLabel: '+50 XP',
              variant: AppProgressCardVariant.ring,
              progress: 0.3,
              progressCaption: '30/100 runs',
              failed: true,
              failedCopy: 'Ends 30 Jun — try next month',
            ),
          ],
        ),
      ),
    );
  }
}
