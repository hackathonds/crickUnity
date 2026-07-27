import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'award_models.dart';
import 'awards_provider.dart';

/// PRD §14: "Winners announced monthly per city/club with certificate
/// cards." Backlog: "surfaces existed, the engine didn't" -- this is
/// the engine (auto-nominee computation + winner declaration), plus a
/// minimal surface to exercise it.
class PeriodicAwardsScreen extends ConsumerWidget {
  const PeriodicAwardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(awardsProvider);
    final notifier = ref.read(awardsProvider.notifier);
    final periodLabel =
        '${_monthName(DateTime.now().month)} ${DateTime.now().year}';

    return Scaffold(
      appBar: AppBar(title: const Text('Periodic Awards')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          for (final category in AwardCategory.values)
            Container(
              key: ValueKey('awardCard_${category.name}'),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          awardCategoryLabels[category]!,
                          style: AppTypography.subtitle.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      AppTagChip(
                        label: notifier.qualifiesFor(category)
                            ? 'Nominee'
                            : 'Not yet',
                        variant: notifier.qualifiesFor(category)
                            ? AppTagChipVariant.success
                            : AppTagChipVariant.neutral,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    awardCategoryCriteria[category]!,
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppButton(
                    key: ValueKey('declareWinnerButton_${category.name}'),
                    variant: AppButtonVariant.secondary,
                    label: 'Declare winner (debug)',
                    onPressed: notifier.qualifiesFor(category)
                        ? () => notifier.declareWinner(
                            category,
                            scopeLabel: 'Delhi · Strikers CC',
                            periodLabel: periodLabel,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Certificates',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (state.pastWinners.isEmpty)
            Text(
              'No awards declared yet.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else
            for (final winner in state.pastWinners.reversed)
              Container(
                key: ValueKey(
                  'certificateCard_${winner.category.name}_${winner.certificateIssuedAt.millisecondsSinceEpoch}',
                ),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.coin.withValues(alpha: 0.1),
                  border: Border.all(color: colors.coin),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${awardCategoryLabels[winner.category]} Award',
                      style: AppTypography.subtitle.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      '${winner.winnerName} · ${winner.scopeLabel} · '
                      '${winner.periodLabel}',
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  String _monthName(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];
}
