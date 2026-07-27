import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'expenses_provider.dart';

/// DS §11.13 Recently Deleted (⊕ Expenses ⋮): "30-day list, rows show
/// deleted-by + countdown, [Restore] per row; restore re-notifies
/// participants." Older-than-30-days entries simply drop off this
/// list -- a real permanent-purge action isn't built (flagged, no
/// storage-reclamation concern exists in this in-memory mock anyway).
class RecentlyDeletedScreen extends ConsumerWidget {
  const RecentlyDeletedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final expenses = ref.watch(expensesProvider).expenses;
    final notifier = ref.read(expensesProvider.notifier);
    final now = DateTime.now();

    final deleted = [
      for (final e in expenses)
        if (e.isDeleted && now.difference(e.deletedAt!).inDays < 30) e,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Recently deleted')),
      body: deleted.isEmpty
          ? Center(
              child: Text(
                key: const ValueKey('recentlyDeletedEmptyState'),
                'Nothing deleted in the last 30 days.',
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                for (final e in deleted)
                  Container(
                    key: ValueKey('recentlyDeletedRow_${e.id}'),
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.title,
                                style: AppTypography.body.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                              Text(
                                'Deleted by ${e.deletedByName} -- '
                                '${30 - now.difference(e.deletedAt!).inDays}d left',
                                style: AppTypography.caption.copyWith(
                                  color: colors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppButton(
                          key: ValueKey('restoreButton_${e.id}'),
                          variant: AppButtonVariant.secondary,
                          label: 'Restore',
                          onPressed: () => notifier.restoreExpense(e.id),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
