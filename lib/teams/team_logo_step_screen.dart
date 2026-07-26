import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_form_step_progress.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'create_team_provider.dart';
import 'team_name_step_screen.dart';

String _initialsFor(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final initials = words.take(2).map((w) => w[0].toUpperCase()).join();
  return initials.isEmpty ? '?' : initials;
}

/// PRD §6.1 step 2: "Logo (upload/generated monogram)." No image-picker
/// package exists in this codebase (same gap as onboarding's Photo step,
/// E1-03) -- only the generated-monogram half of this step is real.
class TeamLogoStepScreen extends ConsumerWidget {
  final VoidCallback onContinue;

  const TeamLogoStepScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(createTeamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create a team')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppFormStepProgress(
              stepCount: createTeamStepLabels.length,
              currentStep: 1,
              labels: createTeamStepLabels,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Your team logo',
              style: AppTypography.h2.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Custom logo upload isn\'t available yet -- here\'s a '
              'generated monogram for now. You can add a real logo once '
              'photo uploads land.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Center(
              child: Container(
                key: const ValueKey('teamLogoMonogram'),
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: state.primaryColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _initialsFor(state.name.isEmpty ? 'Team' : state.name),
                  style: TextStyle(
                    fontFamily: AppTypography.displayFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 32,
                    color:
                        ThemeData.estimateBrightnessForColor(
                              state.primaryColor,
                            ) ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ),
            ),
            const Spacer(),
            AppButton(
              key: const ValueKey('teamLogoContinue'),
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
