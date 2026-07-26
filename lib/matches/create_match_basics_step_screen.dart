import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_form_step_progress.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'create_match_provider.dart';
import 'match_models.dart';

const List<String> createMatchStepLabels = [
  'Basics',
  'Opponent',
  'Ground & time',
  'Review',
];

/// DS §7 screen 24, step 1: "Basics(format presets grid, smart
/// defaults)."
class CreateMatchBasicsStepScreen extends ConsumerWidget {
  final VoidCallback onContinue;

  const CreateMatchBasicsStepScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(createMatchProvider);
    final notifier = ref.read(createMatchProvider.notifier);
    final draft = state.draft;

    return Scaffold(
      appBar: AppBar(title: const Text('Start a match')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppFormStepProgress(
              stepCount: createMatchStepLabels.length,
              currentStep: 0,
              labels: createMatchStepLabels,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Expanded(
              child: ListView(
                children: [
                  Text(
                    'Match type',
                    style: AppTypography.label.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      for (final type in MatchType.values)
                        ChoiceChip(
                          key: ValueKey('matchTypeChip_${type.name}'),
                          label: Text(matchTypeLabels[type]!),
                          selected: draft.matchType == type,
                          onSelected: (_) => notifier.setMatchType(type),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Format',
                    style: AppTypography.label.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final preset in matchFormatPresets)
                        ChoiceChip(
                          key: ValueKey('formatPresetChip_${preset.label}'),
                          label: Text(preset.label),
                          selected: draft.format.label == preset.label,
                          onSelected: (_) => notifier.setFormat(preset),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Ball type',
                    style: AppTypography.label.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      for (final type in BallType.values)
                        ChoiceChip(
                          key: ValueKey('ballTypeChip_${type.name}'),
                          label: Text(ballTypeLabels[type]!),
                          selected: draft.ballType == type,
                          onSelected: (_) => notifier.setBallType(type),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Sub-rules',
                    style: AppTypography.label.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Rebowl on no-ball',
                          style: AppTypography.body.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Switch(
                        key: const ValueKey('noBallRebowlSwitch'),
                        value: draft.subRules.noBallRebowl,
                        onChanged: (value) => notifier.setSubRules(
                          draft.subRules.copyWith(noBallRebowl: value),
                        ),
                      ),
                    ],
                  ),
                  _StepperRow(
                    label: 'Runs per no-ball',
                    value: draft.subRules.noBallRuns,
                    onChanged: (value) => notifier.setSubRules(
                      draft.subRules.copyWith(noBallRuns: value),
                    ),
                  ),
                  _StepperRow(
                    label: 'Runs per wide',
                    value: draft.subRules.wideRuns,
                    onChanged: (value) => notifier.setSubRules(
                      draft.subRules.copyWith(wideRuns: value),
                    ),
                  ),
                ],
              ),
            ),
            AppButton(
              key: const ValueKey('basicsContinueButton'),
              variant: AppButtonVariant.primary,
              label: 'Continue',
              fullWidth: true,
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _StepperRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
        ),
        IconButton(
          key: ValueKey('${label}Decrement'),
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
        ),
        Text(
          '$value',
          style: AppTypography.stat.copyWith(color: colors.textPrimary),
        ),
        IconButton(
          key: ValueKey('${label}Increment'),
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => onChanged(value + 1),
        ),
      ],
    );
  }
}
