import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'personal_bests_provider.dart';
import 'record_models.dart';

/// DS §11.15/PRD §14: "Personal Bests: dedicated shelf; PB detection
/// announces in post-match summary." The shelf here also surfaces the
/// announcement log genuinely produced by the scoring_provider.dart
/// wire, not a static list.
class PersonalBestsScreen extends ConsumerWidget {
  const PersonalBestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(personalBestsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Personal Bests')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          for (final category in personalBestCategories)
            Container(
              key: ValueKey('pbCard_${category.name}'),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      recordCategoryLabels[category]!,
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    state.bests.containsKey(category)
                        ? '${state.bests[category]}'
                        : 'Not set yet',
                    style: AppTypography.stat.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Announcements',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (state.announcements.isEmpty)
            Text(
              'No PBs announced yet -- play a verified match to set one.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else
            for (final announcement in state.announcements.reversed)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs / 2,
                ),
                child: Text(announcement),
              ),
        ],
      ),
    );
  }
}
