import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'home_dashboard_provider.dart';
import 'home_widget_models.dart';

/// DS §7-3: "Edit Home (all) Full-screen reorder list, pin toggles
/// (max 3), hidden section below divider; Save sticky. Reset-to-
/// default tertiary." PRD §4: "Edit Home mode (long-press any widget
/// or via ⋮) allows reorder, hide, pin (max 3 pinned)."
class EditHomeScreen extends ConsumerWidget {
  const EditHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(homeDashboardProvider);
    final notifier = ref.read(homeDashboardProvider.notifier);
    final visible = computeHomeWidgets(ref);
    final hidden = computeHiddenHomeWidgets(ref);
    final unpinnedVisible = visible.where((w) => !w.isPinned).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Home')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Pinned (drag to reorder, max $maxPinnedHomeWidgets)',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.pinned.isEmpty)
            Text(
              'No widgets pinned yet.',
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            )
          else
            ReorderableListView(
              key: const ValueKey('pinnedReorderList'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorderItem: notifier.reorderPinned,
              children: [
                for (final id in state.pinned)
                  _EditRow(
                    key: ValueKey('pinnedRow_${id.name}'),
                    id: id,
                    isPinned: true,
                    isHidden: false,
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Widgets',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final w in unpinnedVisible)
            _EditRow(
              key: ValueKey('visibleRow_${w.id.name}'),
              id: w.id,
              isPinned: false,
              isHidden: false,
            ),
          if (hidden.isNotEmpty) ...[
            const Divider(height: AppSpacing.xxl),
            Text(
              'Hidden',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final w in hidden)
              _EditRow(
                key: ValueKey('hiddenRow_${w.id.name}'),
                id: w.id,
                isPinned: false,
                isHidden: true,
              ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          AppButton(
            key: const ValueKey('resetHomeDefaultButton'),
            variant: AppButtonVariant.tertiary,
            label: 'Reset to default',
            onPressed: notifier.resetToDefault,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppButton(
            key: const ValueKey('saveEditHomeButton'),
            variant: AppButtonVariant.primary,
            label: 'Save',
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}

class _EditRow extends ConsumerWidget {
  final HomeWidgetId id;
  final bool isPinned;
  final bool isHidden;

  const _EditRow({
    super.key,
    required this.id,
    required this.isPinned,
    required this.isHidden,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(homeDashboardProvider);
    final notifier = ref.read(homeDashboardProvider.notifier);
    final pinDisabled =
        !isPinned && state.pinned.length >= maxPinnedHomeWidgets;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (isPinned)
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.sm),
              child: Icon(Icons.drag_handle),
            ),
          Expanded(
            child: Text(
              homeWidgetTitles[id]!,
              style: AppTypography.body.copyWith(color: colors.textPrimary),
            ),
          ),
          IconButton(
            key: ValueKey('editPinToggle_${id.name}'),
            icon: Icon(
              isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: isPinned ? colors.primary : colors.textTertiary,
            ),
            onPressed: pinDisabled ? null : () => notifier.togglePin(id),
          ),
          IconButton(
            key: ValueKey('editHideToggle_${id.name}'),
            icon: Icon(
              isHidden
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: () => notifier.toggleHide(id),
          ),
        ],
      ),
    );
  }
}
