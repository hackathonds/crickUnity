import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'marketplace_models.dart';
import 'marketplace_provider.dart';

/// DS §7-53's "My Rewards (voucher cards, copy-code, redeem-by
/// countdown)." PRD §18: "out-of-stock, expired-voucher states" --
/// expired and failed-refunded vouchers render as distinct card states,
/// not hidden from the list.
class MyRewardsScreen extends ConsumerStatefulWidget {
  const MyRewardsScreen({super.key});

  @override
  ConsumerState<MyRewardsScreen> createState() => _MyRewardsScreenState();
}

class _MyRewardsScreenState extends ConsumerState<MyRewardsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(marketplaceProvider.notifier).sweepExpiredVouchers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final marketplace = ref.watch(marketplaceProvider);
    final notifier = ref.read(marketplaceProvider.notifier);

    if (marketplace.redemptions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Rewards')),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppEmptyState(
            key: const ValueKey('myRewardsEmptyState'),
            message: 'Nothing redeemed yet -- browse the Marketplace.',
            primaryLabel: 'Browse Marketplace',
            onPrimary: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Rewards')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          for (final voucher in marketplace.redemptions.reversed)
            _VoucherCard(
              voucher: voucher,
              colors: colors,
              onSimulateFailure: () =>
                  notifier.simulateFailedFulfillment(voucher.id),
            ),
        ],
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  final VoucherRedemption voucher;
  final AppColors colors;
  final VoidCallback onSimulateFailure;

  const _VoucherCard({
    required this.voucher,
    required this.colors,
    required this.onSimulateFailure,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = voucher.redeemByDate.difference(DateTime.now()).inDays;

    return Container(
      key: ValueKey('voucherCard_${voucher.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  voucher.listing.title,
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ),
              switch (voucher.status) {
                RedemptionStatus.active => AppTagChip(
                  label: daysLeft <= 0
                      ? 'Redeem-by today'
                      : 'Redeem by $daysLeft d',
                  variant: AppTagChipVariant.success,
                ),
                RedemptionStatus.expired => AppTagChip(
                  label: 'Expired',
                  variant: AppTagChipVariant.error,
                ),
                RedemptionStatus.failedRefunded => AppTagChip(
                  label: 'Refunded',
                  variant: AppTagChipVariant.warning,
                ),
              },
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (voucher.status == RedemptionStatus.failedRefunded)
            Text(
              'Fulfillment failed -- coins refunded + 10 apology bonus.',
              style: AppTypography.caption.copyWith(
                color: colors.textSecondary,
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    voucher.code,
                    key: ValueKey('voucherCode_${voucher.id}'),
                    style: AppTypography.stat.copyWith(
                      color: voucher.status == RedemptionStatus.expired
                          ? colors.textTertiary
                          : colors.textPrimary,
                    ),
                  ),
                ),
                AppButton(
                  key: ValueKey('copyVoucherCodeButton_${voucher.id}'),
                  variant: AppButtonVariant.tertiary,
                  label: 'Copy',
                  onPressed: voucher.status == RedemptionStatus.expired
                      ? null
                      : () {
                          Clipboard.setData(ClipboardData(text: voucher.code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code copied')),
                          );
                        },
                ),
              ],
            ),
          if (voucher.status == RedemptionStatus.active) ...[
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              key: ValueKey('simulateFailedFulfillmentButton_${voucher.id}'),
              variant: AppButtonVariant.tertiary,
              label: 'Simulate failed fulfillment (debug)',
              fullWidth: true,
              onPressed: onSimulateFailure,
            ),
          ],
        ],
      ),
    );
  }
}
