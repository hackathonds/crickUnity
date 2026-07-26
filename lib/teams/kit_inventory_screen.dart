import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_avatar.dart';
import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'kit_inventory_models.dart';
import 'kit_inventory_provider.dart';

/// DS §7 screen 21 (Kit Inventory): "Kit rows show custody avatar +
/// [Hand over] flow (both confirm)."
class KitInventoryScreen extends ConsumerWidget {
  final String viewerName;

  const KitInventoryScreen({super.key, required this.viewerName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(kitInventoryProvider);
    final notifier = ref.read(kitInventoryProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Kit inventory')),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: state.items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final item = state.items[index];
          final isCustodian = item.custodianName == viewerName;
          final isPendingRecipient = item.pendingRecipient == viewerName;

          return Container(
            key: ValueKey('kitItem_${item.id}'),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                AppAvatar(size: AppAvatarSize.xs, name: item.custodianName),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: AppTypography.body.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        'Held by ${item.custodianName}',
                        style: AppTypography.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      if (item.pendingRecipient != null)
                        Text(
                          'Awaiting ${item.pendingRecipient}\'s confirmation',
                          style: AppTypography.caption.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isPendingRecipient)
                  AppButton(
                    key: ValueKey('confirmHandoverButton_${item.id}'),
                    variant: AppButtonVariant.primary,
                    label: 'Confirm receipt',
                    onPressed: () =>
                        notifier.confirmHandover(item.id, viewerName),
                  )
                else if (isCustodian && item.pendingRecipient == null)
                  AppButton(
                    key: ValueKey('handOverButton_${item.id}'),
                    variant: AppButtonVariant.secondary,
                    label: 'Hand over',
                    onPressed: () => _showRecipientPicker(
                      context: context,
                      notifier: notifier,
                      item: item,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showRecipientPicker({
    required BuildContext context,
    required KitInventoryNotifier notifier,
    required KitItem item,
  }) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Hand over ${item.name}',
      contentBuilder: (context) => _RecipientPickerContent(
        candidates: mockKitTeamMemberNames()
            .where((name) => name != item.custodianName)
            .toList(),
        onSelect: (toName) {
          notifier.initiateHandover(item.id, item.custodianName, toName);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _RecipientPickerContent extends StatelessWidget {
  final List<String> candidates;
  final ValueChanged<String> onSelect;

  const _RecipientPickerContent({
    required this.candidates,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final name in candidates)
            _RecipientRow(
              key: ValueKey('handoverRecipient_$name'),
              name: name,
              onTap: () => onSelect(name),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _RecipientRow extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _RecipientRow({super.key, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            AppAvatar(size: AppAvatarSize.xs, name: name),
            const SizedBox(width: AppSpacing.md),
            Text(
              name,
              style: AppTypography.body.copyWith(color: colors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
