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

/// PRD §6.1 step 4: "Format focus."
class TeamFormatStepScreen extends ConsumerWidget {
  final VoidCallback onContinue;

  const TeamFormatStepScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(createTeamProvider);
    final notifier = ref.read(createTeamProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Create a team')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppFormStepProgress(
              stepCount: createTeamStepLabels.length,
              currentStep: 3,
              labels: createTeamStepLabels,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'What formats do you play?',
              style: AppTypography.h2.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Pick at least one -- you can change this anytime.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final format in TeamFormat.values)
                  AppChipActionButton(
                    key: ValueKey('teamFormatOption_${format.name}'),
                    label: teamFormatLabels[format]!,
                    selected: state.formatFocus.contains(format),
                    onPressed: () => notifier.toggleFormat(format),
                  ),
              ],
            ),
            const Spacer(),
            AppButton(
              key: const ValueKey('teamFormatContinue'),
              variant: AppButtonVariant.primary,
              label: 'Continue',
              fullWidth: true,
              onPressed: state.formatFocus.isNotEmpty ? onContinue : null,
            ),
          ],
        ),
      ),
    );
  }
}
