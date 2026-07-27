import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_reward_card.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'chest_claim_overlay.dart';
import 'luck_odds_screen.dart';
import 'luck_provider.dart';
import 'lucky_draw_screen.dart';
import 'rewards_provider.dart';
import 'scratch_card_screen.dart';
import 'spin_wheel_screen.dart';

/// DS §7-56's 3 claim overlays reached from one hub, reusing the
/// existing `AppRewardCard` scratch/spin/chest tiles (E0-08) rather
/// than new art.
class LuckLayerScreen extends ConsumerWidget {
  const LuckLayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final luck = ref.watch(luckLayerProvider);
    final rewards = ref.watch(rewardsProvider);
    final spinBlocked =
        ref
            .read(luckLayerProvider.notifier)
            .spinBlockReason(viewerLevel: rewards.level) !=
        null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Luck Layer'),
        actions: [
          IconButton(
            key: const ValueKey('viewOddsButton'),
            icon: const Icon(Icons.info_outline),
            tooltip: 'Odds',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const LuckOddsScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppRewardCard(
                key: const ValueKey('scratchCardTile'),
                type: AppRewardType.scratch,
                unclaimed: luck.scratchCardsAvailable > 0,
                count: luck.scratchCardsAvailable,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ScratchCardScreen()),
                ),
              ),
              AppRewardCard(
                key: const ValueKey('spinWheelTile'),
                type: AppRewardType.spin,
                unclaimed: !spinBlocked,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SpinWheelScreen()),
                ),
              ),
              AppRewardCard(
                key: const ValueKey('chestTile'),
                type: AppRewardType.chest,
                onTap: () => showChestClaimOverlay(context, coins: 25),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppButton(
            key: const ValueKey('viewLuckyDrawButton'),
            variant: AppButtonVariant.secondary,
            label: 'Monthly Lucky Draw',
            fullWidth: true,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const LuckyDrawScreen())),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'History',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (luck.log.isEmpty)
            Text(
              'No results yet.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else
            for (final entry in luck.log.reversed)
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
        ],
      ),
    );
  }
}
