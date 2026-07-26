import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_avatar.dart';
import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'duty_roster_provider.dart';

/// DS §7 screen 19 (Duty Roster): "Duty slots show claimant avatar or
/// [Claim]."
class DutyRosterScreen extends ConsumerWidget {
  final String viewerName;

  const DutyRosterScreen({super.key, required this.viewerName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(dutyRosterProvider);
    final notifier = ref.read(dutyRosterProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Duty roster')),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: state.slots.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final slot = state.slots[index];
          final claimedByViewer = slot.claimantName == viewerName;
          return Container(
            key: ValueKey('dutySlot_${slot.id}'),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    slot.label,
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (slot.claimantName != null) ...[
                  AppAvatar(size: AppAvatarSize.xs, name: slot.claimantName!),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    slot.claimantName!,
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  if (claimedByViewer) ...[
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      key: ValueKey('unclaimDutyButton_${slot.id}'),
                      variant: AppButtonVariant.tertiary,
                      label: 'Unclaim',
                      onPressed: () => notifier.unclaim(slot.id),
                    ),
                  ],
                ] else
                  AppButton(
                    key: ValueKey('claimDutyButton_${slot.id}'),
                    variant: AppButtonVariant.primary,
                    label: 'Claim',
                    onPressed: () => notifier.claim(slot.id, viewerName),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
