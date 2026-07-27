import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'marketplace_models.dart';
import 'marketplace_provider.dart';
import 'rewards_provider.dart';

const Map<RedeemFailureReason, String> _redeemFailureMessages = {
  RedeemFailureReason.levelLocked: 'Reach the required level to unlock this.',
  RedeemFailureReason.outOfStock: 'Out of stock -- check back later.',
  RedeemFailureReason.insufficientCoins: 'Not enough coins yet.',
  RedeemFailureReason.capReached:
      'Monthly redemption limit reached for this item.',
};

/// DS §7-53's "Listing (terms accordion, [Redeem] with level-lock
/// state)." PRD §18: "level-gated items visibly locked | out-of-stock,
/// expired-voucher states" -- all 3 render as an inline reason under a
/// disabled [Redeem], not a silent failure.
class ListingDetailScreen extends ConsumerWidget {
  final String listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final listing = listingById(listingId);
    final rewards = ref.watch(rewardsProvider);
    final marketplace = ref.watch(marketplaceProvider);
    final notifier = ref.read(marketplaceProvider.notifier);

    final locked = rewards.level < listing.levelRequirement;
    final stock = marketplace.stockFor(listing);
    final canAfford = rewards.coinBalance >= listing.coinPrice;

    RedeemFailureReason? blockedReason;
    if (locked) {
      blockedReason = RedeemFailureReason.levelLocked;
    } else if (stock <= 0) {
      blockedReason = RedeemFailureReason.outOfStock;
    } else if (!canAfford) {
      blockedReason = RedeemFailureReason.insufficientCoins;
    }

    return Scaffold(
      appBar: AppBar(title: Text(listing.title)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${listing.coinPrice} coins',
              key: const ValueKey('listingPriceText'),
              style: AppTypography.h1.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$stock in stock'
              '${locked ? " -- unlocks at Level ${listing.levelRequirement}" : ""}',
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.lg),
            ExpansionTile(
              key: const ValueKey('listingTermsAccordion'),
              title: Text(
                'Terms',
                style: AppTypography.label.copyWith(color: colors.textTertiary),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.terms,
                        style: AppTypography.body.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        listing.expiryNote,
                        style: AppTypography.caption.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (blockedReason != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  _redeemFailureMessages[blockedReason]!,
                  key: const ValueKey('listingBlockedReasonText'),
                  style: AppTypography.caption.copyWith(color: colors.error),
                ),
              ),
            AppButton(
              key: const ValueKey('redeemListingButton'),
              variant: AppButtonVariant.primary,
              label: 'Redeem',
              fullWidth: true,
              onPressed: blockedReason != null
                  ? null
                  : () {
                      final reason = notifier.redeem(
                        listing,
                        viewerLevel: rewards.level,
                      );
                      final message = reason == null
                          ? 'Redeemed -- voucher added to My Rewards'
                          : _redeemFailureMessages[reason]!;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(message)));
                      if (reason == null) Navigator.of(context).pop();
                    },
            ),
          ],
        ),
      ),
    );
  }
}
