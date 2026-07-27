import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'family_manager_screen.dart';
import 'premium_provider.dart';

const List<String> _proFeatures = [
  'Advanced analytics',
  'Unlimited highlight reels',
  'Profile themes',
  'Priority gig-board placement (scorers/umpires)',
  '1.25x coin multiplier (capped)',
];

/// DS §11.14: "Pro & Family: paywall screen (feature table honest:
/// integrity note prominent), plan cards, Family = manage-members
/// screen; manage/cancel states plain." PRD §13.6's integrity rule
/// ("Pro never affects rankings, Trust, or verification") is rendered
/// as its own bordered banner, not buried in the feature list -- the
/// one thing this screen must not let read as negotiable.
class ProPaywallScreen extends ConsumerWidget {
  const ProPaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final premium = ref.watch(premiumProvider);
    final notifier = ref.read(premiumProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('CricUnity Pro')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            key: const ValueKey('proIntegrityNoteBanner'),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.verified, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_outlined, color: colors.verified),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Pro never affects rankings, Trust, or verification -- '
                    'competitive integrity is unbuyable.',
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            "What's included",
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final feature in _proFeatures)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
              child: Row(
                children: [
                  Icon(Icons.check, size: 18, color: colors.success),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    feature,
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xxl),
          if (premium.plan == PremiumPlan.none) ...[
            _PlanCard(
              key: const ValueKey('proPlanCard'),
              title: 'Pro',
              priceLabel: '₹99/month',
              colors: colors,
              onSubscribe: () => notifier.subscribe(PremiumPlan.pro),
            ),
            const SizedBox(height: AppSpacing.sm),
            _PlanCard(
              key: const ValueKey('familyPlanCard'),
              title: 'Family',
              priceLabel: '₹249/month -- 4 member slots',
              colors: colors,
              onSubscribe: () => notifier.subscribe(PremiumPlan.family),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    premium.plan == PremiumPlan.family
                        ? 'Family plan active'
                        : 'Pro plan active',
                    key: const ValueKey('activePlanText'),
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (premium.plan == PremiumPlan.family)
                    AppButton(
                      key: const ValueKey('manageFamilyButton'),
                      variant: AppButtonVariant.secondary,
                      label: 'Manage family members',
                      fullWidth: true,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FamilyManagerScreen(),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    key: const ValueKey('cancelPlanButton'),
                    variant: AppButtonVariant.tertiary,
                    label: 'Cancel plan',
                    fullWidth: true,
                    onPressed: notifier.cancel,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String priceLabel;
  final AppColors colors;
  final VoidCallback onSubscribe;

  const _PlanCard({
    super.key,
    required this.title,
    required this.priceLabel,
    required this.colors,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
                Text(
                  priceLabel,
                  style: AppTypography.caption.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          AppButton(
            variant: AppButtonVariant.primary,
            label: 'Subscribe',
            onPressed: onSubscribe,
          ),
        ],
      ),
    );
  }
}
