import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_form_step_progress.dart';
import '../design_system/components/app_segmented_control.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'create_match_basics_step_screen.dart';
import 'create_match_provider.dart';
import 'match_models.dart';
import 'matches_provider.dart';

/// DS §7 screen 24, step 4: "Review(expense-preset toggle, visibility,
/// availability-deadline). Review shows editable summary rows." The
/// genuinely editable items DS/backlog name (expense preset, visibility,
/// availability deadline, scorer) are live controls here; the rest of
/// the draft is shown as a read-only recap -- reopening earlier steps
/// isn't this screen's job, keeping the happy-path touch count low (DS
/// §1.5).
class CreateMatchReviewStepScreen extends ConsumerWidget {
  final String composerTeamName;
  final ValueChanged<String> onSend;

  const CreateMatchReviewStepScreen({
    super.key,
    required this.composerTeamName,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(createMatchProvider);
    final notifier = ref.read(createMatchProvider.notifier);
    final draft = state.draft;

    Widget summaryRow(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
          ),
          Text(
            value,
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Start a match')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppFormStepProgress(
              stepCount: createMatchStepLabels.length,
              currentStep: 3,
              labels: createMatchStepLabels,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Expanded(
              child: ListView(
                children: [
                  summaryRow('Match type', matchTypeLabels[draft.matchType]!),
                  summaryRow('Format', draft.format.label),
                  summaryRow('Ball type', ballTypeLabels[draft.ballType]!),
                  summaryRow(
                    'Opponent',
                    draft.isGuestTeam
                        ? '${draft.opponentTeamName} (guest)'
                        : draft.opponentTeamName,
                  ),
                  summaryRow('Ground', draft.groundName),
                  summaryRow(
                    'Date/time',
                    '${draft.dateTime.day}/${draft.dateTime.month}/'
                        '${draft.dateTime.year} '
                        '${draft.dateTime.hour.toString().padLeft(2, '0')}:'
                        '${draft.dateTime.minute.toString().padLeft(2, '0')}',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Auto-create standard expenses',
                          style: AppTypography.body.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Switch(
                        key: const ValueKey('expensePresetSwitch'),
                        value: draft.expensePresetEnabled,
                        onChanged: notifier.setExpensePresetEnabled,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Visibility',
                    style: AppTypography.label.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppSegmentedControl<MatchVisibility>(
                    key: const ValueKey('visibilitySegmentedControl'),
                    options: MatchVisibility.values,
                    value: draft.visibility,
                    onChanged: notifier.setVisibility,
                    labelBuilder: (v) => matchVisibilityLabels[v]!,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Scorer',
                    style: AppTypography.label.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      for (final assignment in ScorerAssignment.values)
                        ChoiceChip(
                          key: ValueKey('scorerChip_${assignment.name}'),
                          label: Text(scorerAssignmentLabels[assignment]!),
                          selected: draft.scorerAssignment == assignment,
                          onSelected: (_) =>
                              notifier.setScorerAssignment(assignment),
                        ),
                    ],
                  ),
                  if (draft.scorerAssignment == ScorerAssignment.member) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        for (final name in mockSquadNames())
                          ChoiceChip(
                            key: ValueKey('scorerMemberChip_$name'),
                            label: Text(name),
                            selected: draft.scorerMemberName == name,
                            onSelected: (_) =>
                                notifier.setScorerMemberName(name),
                          ),
                      ],
                    ),
                  ],
                  if (draft.scorerAssignment ==
                      ScorerAssignment.hireFromGigBoard) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Gig Board (E14-01) isn\'t built yet -- no scorer '
                      'will actually be hired.',
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Umpires (optional)',
                    style: AppTypography.label.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      for (final name in mockSquadNames())
                        FilterChip(
                          key: ValueKey('umpireChip_$name'),
                          label: Text(name),
                          selected: draft.umpireNames.contains(name),
                          onSelected: (_) => notifier.toggleUmpire(name),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Availability deadline (hours before start)',
                          style: AppTypography.body.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('availabilityDeadlineDecrement'),
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: draft.availabilityDeadlineHours > 1
                            ? () => notifier.setAvailabilityDeadlineHours(
                                draft.availabilityDeadlineHours - 1,
                              )
                            : null,
                      ),
                      Text(
                        '${draft.availabilityDeadlineHours}',
                        style: AppTypography.stat.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('availabilityDeadlineIncrement'),
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => notifier.setAvailabilityDeadlineHours(
                          draft.availabilityDeadlineHours + 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AppButton(
              key: const ValueKey('sendMatchButton'),
              variant: AppButtonVariant.primary,
              label: 'Send',
              fullWidth: true,
              onPressed: () {
                final id = ref
                    .read(matchesProvider.notifier)
                    .submitMatch(
                      draft: draft,
                      composerTeamName: composerTeamName,
                    );
                onSend(id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
