import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'marketplace_screen.dart';
import 'missions_board_screen.dart';
import 'my_rewards_screen.dart';
import 'rewards_models.dart';
import 'rewards_provider.dart';

/// DS §7-53 "Wallet & Coins": "balance hero + expiring strip warning ->
/// earn/redeem 2-up -> history list (source glyphs) -> Marketplace grid
/// -> Listing (terms accordion, [Redeem] with level-lock state) -> My
/// Rewards (voucher cards, copy-code, redeem-by countdown)." This
/// screen is the "balance hero + expiring strip + earn/redeem + history"
/// anatomy; Marketplace/Listing/My Rewards are their own pushed screens
/// (marketplace_screen.dart/listing_detail_screen.dart/
/// my_rewards_screen.dart), same "distinct nav item" split PRD §2.1
/// gives Wallet & Coins vs. Rewards (rewards_summary_screen.dart, E6-01).
///
/// PRD §18 UX matrix: "16. Wallet & Coins ... zero-state explainer." No
/// backend balance-fetch exists (all local state), so only
/// Default/Empty/Success are genuine triggers here, same precedent as
/// achievements_wall_screen.dart (E2-05) -- Loading/Error/Offline/
/// Permission-denied aren't fabricated.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final rewards = ref.watch(rewardsProvider);

    if (rewards.coinBalance == 0 && rewards.log.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Wallet & Coins')),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppEmptyState(
            key: const ValueKey('walletEmptyState'),
            message:
                'No coins yet -- play a verified match or complete a '
                'mission to start earning.',
            primaryLabel: 'View missions',
            onPrimary: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MissionsBoardScreen()),
            ),
          ),
        ),
      );
    }

    // PRD §13.1: "expiry warnings at 30/7 days" -- the 7-day window is
    // the more urgent subset; only step down to the 30-day warning when
    // nothing expires within 7.
    final expiring7 = coinsExpiringWithin(rewards.coinBatches, 7);
    final expiring30 = coinsExpiringWithin(rewards.coinBatches, 30);

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet & Coins')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            '${rewards.coinBalance}',
            key: const ValueKey('walletBalanceHero'),
            style: AppTypography.display.copyWith(color: colors.textPrimary),
          ),
          Text(
            'coins',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
          if (expiring7 > 0 || expiring30 > 0) ...[
            const SizedBox(height: AppSpacing.md),
            AppTagChip(
              key: const ValueKey('coinsExpiringChip'),
              label: expiring7 > 0
                  ? '$expiring7 coins expire in 7d'
                  : '$expiring30 coins expire in 30d',
              variant: AppTagChipVariant.warning,
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  key: const ValueKey('walletEarnButton'),
                  variant: AppButtonVariant.secondary,
                  label: 'Earn',
                  fullWidth: true,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MissionsBoardScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  key: const ValueKey('walletRedeemButton'),
                  variant: AppButtonVariant.primary,
                  label: 'Redeem',
                  fullWidth: true,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MarketplaceScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            key: const ValueKey('viewMyRewardsButton'),
            variant: AppButtonVariant.tertiary,
            label: 'My Rewards',
            fullWidth: true,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MyRewardsScreen())),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'History',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (rewards.log.isEmpty)
            Text(
              'Nothing yet.',
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
        ],
      ),
    );
  }
}
