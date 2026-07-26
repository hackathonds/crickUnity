import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_form_step_progress.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'create_team_provider.dart';
import 'team_name_step_screen.dart';

/// PRD §6.1 step 3: "City & home ground (optional link)." No Ground
/// module/data exists yet (a later epic), so home ground is a free-text
/// field rather than a real linked-entity picker.
class TeamCityGroundStepScreen extends ConsumerStatefulWidget {
  final VoidCallback onContinue;

  const TeamCityGroundStepScreen({super.key, required this.onContinue});

  @override
  ConsumerState<TeamCityGroundStepScreen> createState() =>
      _TeamCityGroundStepScreenState();
}

class _TeamCityGroundStepScreenState
    extends ConsumerState<TeamCityGroundStepScreen> {
  late final TextEditingController _cityController;
  late final TextEditingController _groundController;

  @override
  void initState() {
    super.initState();
    // Eagerly initialized (not lazy `late final =` fields) -- see
    // team_name_step_screen.dart's identical fix for why a lazy
    // initializer that reads `ref` is unsafe here.
    final state = ref.read(createTeamProvider);
    _cityController = TextEditingController(text: state.city);
    _groundController = TextEditingController(text: state.homeGround);
  }

  @override
  void dispose() {
    _cityController.dispose();
    _groundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              currentStep: 2,
              labels: createTeamStepLabels,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Where do you play?',
              style: AppTypography.h2.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppTextField(
              key: const ValueKey('teamCityField'),
              label: 'City',
              controller: _cityController,
              onChanged: notifier.setCity,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const ValueKey('teamGroundField'),
              label: 'Home ground (optional)',
              controller: _groundController,
              onChanged: notifier.setHomeGround,
            ),
            const Spacer(),
            AppButton(
              key: const ValueKey('teamCityGroundContinue'),
              variant: AppButtonVariant.primary,
              label: 'Continue',
              fullWidth: true,
              onPressed: state.city.trim().isNotEmpty
                  ? widget.onContinue
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
