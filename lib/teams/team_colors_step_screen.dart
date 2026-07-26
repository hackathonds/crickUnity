import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_form_step_progress.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'create_team_provider.dart';
import 'team_models.dart';
import 'team_name_step_screen.dart';

/// PRD §6.1 step 6 (final): "Colors." Reuses the theme's own categorical
/// chart ramp as the swatch palette -- DS gives no dedicated color-picker
/// spec, and this ramp is already guaranteed distinct/on-brand per theme.
class TeamColorsStepScreen extends ConsumerWidget {
  final ValueChanged<Team> onCreated;

  const TeamColorsStepScreen({super.key, required this.onCreated});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(createTeamProvider);
    final notifier = ref.read(createTeamProvider.notifier);
    final swatches = colors.chartCategorical;

    Widget swatchRow({
      required String rowKey,
      required String label,
      required Color selected,
      required ValueChanged<Color> onSelect,
    }) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.label.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          key: ValueKey(rowKey),
          children: [
            for (final swatch in swatches) ...[
              GestureDetector(
                onTap: () => onSelect(swatch),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: swatch,
                    shape: BoxShape.circle,
                    border: swatch == selected
                        ? Border.all(color: colors.textPrimary, width: 2)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Create a team')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppFormStepProgress(
              stepCount: createTeamStepLabels.length,
              currentStep: 5,
              labels: createTeamStepLabels,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Pick your colors',
              style: AppTypography.h2.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            swatchRow(
              rowKey: 'teamPrimaryColorRow',
              label: 'Primary',
              selected: state.primaryColor,
              onSelect: notifier.setPrimaryColor,
            ),
            const SizedBox(height: AppSpacing.lg),
            swatchRow(
              rowKey: 'teamSecondaryColorRow',
              label: 'Secondary',
              selected: state.secondaryColor,
              onSelect: notifier.setSecondaryColor,
            ),
            const Spacer(),
            AppButton(
              key: const ValueKey('teamColorsCreateButton'),
              variant: AppButtonVariant.primary,
              label: 'Create team',
              fullWidth: true,
              onPressed: state.canCreate
                  ? () {
                      final team = notifier.createTeam();
                      if (team != null) onCreated(team);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
