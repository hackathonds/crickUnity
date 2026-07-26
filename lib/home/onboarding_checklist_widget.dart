import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_coin_chip.dart';
import '../design_system/icons/app_icon.dart';
import '../design_system/icons/app_icon_id.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_radius.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../onboarding/profile_wizard_provider.dart';
import 'onboarding_checklist_provider.dart';

/// DS §7 screen 1 (Home): "new user shows Onboarding-Checklist widget
/// replacing stack until 2 items done." PRD §4: each item grants coins.
///
/// The coin float is [AppCoinChip]'s existing earn animation (DS §5 item
/// 7, built in E0-08) reused here rather than a second coin-animation
/// implementation -- it auto-plays whenever its `balance` increases.
class OnboardingChecklistWidget extends ConsumerWidget {
  const OnboardingChecklistWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(onboardingChecklistProvider);

    // "Complete profile" is the one item wired to something real (E1-03's
    // profileWizardProvider) rather than a debug toggle. Deferred to a
    // post-frame callback rather than called synchronously here, since
    // mutating a provider mid-build throws; completeItem is idempotent so
    // rescheduling this on every rebuild is harmless.
    final profileComplete =
        ref.watch(profileWizardProvider.select((s) => s.completeness)) >= 1.0;
    if (profileComplete &&
        !state.completed.contains(ChecklistItem.completeProfile)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(onboardingChecklistProvider.notifier)
            .completeItem(ChecklistItem.completeProfile);
      });
    }

    if (!state.shouldShow) return const SizedBox.shrink();

    return Container(
      key: const ValueKey('onboardingChecklistWidget'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: AppRadius.mdRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Get started',
                style: AppTypography.title.copyWith(color: colors.textPrimary),
              ),
              AppCoinChip(
                key: const ValueKey('onboardingChecklistCoinChip'),
                balance: state.coinsEarned,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final item in ChecklistItem.values)
            _ChecklistRow(item: item, done: state.completed.contains(item)),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final ChecklistItem item;
  final bool done;

  const _ChecklistRow({required this.item, required this.done});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          if (done)
            AppIcon(
              id: AppIconId.verifiedCheck,
              semanticLabel: 'Done',
              color: colors.primary,
              size: 20,
            )
          else
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.border, width: 1.5),
              ),
            ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              checklistItemLabels[item]!,
              style: AppTypography.body.copyWith(
                color: done ? colors.textTertiary : colors.textPrimary,
                decoration: done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Text(
            '+${checklistItemCoins[item]}',
            style: AppTypography.caption.copyWith(color: colors.coin),
          ),
        ],
      ),
    );
  }
}
