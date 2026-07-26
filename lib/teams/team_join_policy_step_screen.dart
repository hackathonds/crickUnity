import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_form_step_progress.dart';
import '../design_system/components/app_segmented_control.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'create_team_provider.dart';
import 'team_models.dart';
import 'team_name_step_screen.dart';

/// PRD §6.1 step 5: "Join policy (Open / Request / Invite-only)."
class TeamJoinPolicyStepScreen extends ConsumerWidget {
  final VoidCallback onContinue;

  const TeamJoinPolicyStepScreen({super.key, required this.onContinue});

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
              currentStep: 4,
              labels: createTeamStepLabels,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Who can join?',
              style: AppTypography.h2.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppSegmentedControl<TeamJoinPolicy>(
              key: const ValueKey('teamJoinPolicyControl'),
              options: TeamJoinPolicy.values,
              value: state.joinPolicy,
              onChanged: notifier.setJoinPolicy,
              labelBuilder: (policy) => teamJoinPolicyLabels[policy]!,
            ),
            const Spacer(),
            AppButton(
              key: const ValueKey('teamJoinPolicyContinue'),
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
