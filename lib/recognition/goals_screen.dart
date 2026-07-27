import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_arc_ring.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_dropdown_field.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'goal_models.dart';
import 'goals_provider.dart';
import 'leaderboard_models.dart';

/// DS §11.15: goal cards with pace ring + on/off-track chip, reusing
/// the existing AppArcRing primitive (its Nth reuse this session) for
/// the ring rather than a new painter.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final goals = ref.watch(goalsProvider).goals;
    final notifier = ref.read(goalsProvider.notifier);

    final coachProposed = goals
        .where(
          (g) =>
              g.proposedByCoachName != null && g.status == GoalStatus.pending,
        )
        .toList();
    final active = goals.where((g) => g.status == GoalStatus.accepted).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('createGoalFab'),
        onPressed: () => _showCreateGoalSheet(context, ref),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (coachProposed.isNotEmpty) ...[
            Text(
              'Coach-proposed',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final goal in coachProposed)
              Container(
                key: ValueKey('coachGoalCard_${goal.id}'),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.primary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${goal.proposedByCoachName} proposes: '
                      '${goal.target} ${leaderboardMetricLabels[goal.metric]} '
                      'this ${goalPeriodLabels[goal.period]!.toLowerCase()}',
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        AppButton(
                          key: ValueKey('acceptCoachGoalButton_${goal.id}'),
                          variant: AppButtonVariant.primary,
                          label: 'Accept',
                          onPressed: () => notifier.acceptCoachGoal(goal.id),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        AppButton(
                          key: ValueKey('declineCoachGoalButton_${goal.id}'),
                          variant: AppButtonVariant.tertiary,
                          label: 'Decline',
                          onPressed: () => notifier.declineCoachGoal(goal.id),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.xxl),
          ],
          Text(
            'Active goals',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final goal in active)
            Container(
              key: ValueKey('goalCard_${goal.id}'),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AppArcRing(
                          progress: goal.progressFraction,
                          size: 56,
                          strokeWidth: 4,
                          trackColor: colors.border,
                          fillColor: goal.onTrack()
                              ? colors.success
                              : colors.warning,
                        ),
                        Text(
                          '${(goal.progressFraction * 100).round()}%',
                          style: AppTypography.caption.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${goal.target} ${leaderboardMetricLabels[goal.metric]} '
                          'this ${goalPeriodLabels[goal.period]}',
                          style: AppTypography.body.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            AppTagChip(
                              label: goal.onTrack() ? 'On track' : 'Off track',
                              variant: goal.onTrack()
                                  ? AppTagChipVariant.success
                                  : AppTagChipVariant.warning,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '${goal.progress}/${goal.target}',
                              style: AppTypography.caption.copyWith(
                                color: colors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                        AppButton(
                          key: ValueKey(
                            'simulateGoalProgressButton_${goal.id}',
                          ),
                          variant: AppButtonVariant.tertiary,
                          label: 'Simulate +10 (debug)',
                          onPressed: () => notifier.recordProgress(goal.id, 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showCreateGoalSheet(BuildContext context, WidgetRef ref) {
    LeaderboardMetric metric = LeaderboardMetric.runs;
    int target = 100;
    GoalPeriod period = GoalPeriod.month;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New goal', style: AppTypography.h2),
              const SizedBox(height: AppSpacing.md),
              AppDropdownField<LeaderboardMetric>(
                key: const ValueKey('goalMetricDropdown'),
                label: 'Metric',
                value: metric,
                options: LeaderboardMetric.values,
                labelBuilder: (m) => leaderboardMetricLabels[m]!,
                onChanged: (v) => setSheetState(() => metric = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text('Target: $target'),
                  IconButton(
                    key: const ValueKey('goalTargetDecrement'),
                    icon: const Icon(Icons.remove),
                    onPressed: () => setSheetState(
                      () => target = (target - 10).clamp(10, 10000),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('goalTargetIncrement'),
                    icon: const Icon(Icons.add),
                    onPressed: () => setSheetState(() => target += 10),
                  ),
                ],
              ),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final p in GoalPeriod.values)
                    ChoiceChip(
                      label: Text(goalPeriodLabels[p]!),
                      selected: period == p,
                      onSelected: (_) => setSheetState(() => period = p),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                key: const ValueKey('submitCreateGoalButton'),
                variant: AppButtonVariant.primary,
                label: 'Create goal',
                fullWidth: true,
                onPressed: () {
                  ref
                      .read(goalsProvider.notifier)
                      .createGoal(
                        metric: metric,
                        target: target,
                        period: period,
                      );
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
