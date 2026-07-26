import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_form_step_progress.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'create_team_provider.dart';

const List<String> createTeamStepLabels = [
  'Name',
  'Logo',
  'Location',
  'Format',
  'Access',
  'Colors',
];

/// PRD §6.1 step 1: "Name (unique within city; suggestions if taken)."
/// Also the entry point that surfaces §6.1's own "team limit 5 owned per
/// user" validation rule (a different, smaller cap than E3-03's later
/// "player can be in max 10 teams" AC) -- checked here first since every
/// later step is moot if the cap is already hit.
class TeamNameStepScreen extends ConsumerStatefulWidget {
  final VoidCallback onContinue;

  const TeamNameStepScreen({super.key, required this.onContinue});

  @override
  ConsumerState<TeamNameStepScreen> createState() => _TeamNameStepScreenState();
}

class _TeamNameStepScreenState extends ConsumerState<TeamNameStepScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Eagerly initialized here (not a lazy `late final =` field) --
    // otherwise a build path that never references `_controller` (the
    // team-limit-reached banner branch below) leaves it uninitialized
    // until `dispose()` first touches it, which then tries to call
    // `ref.read` on an already-disposed element and crashes.
    _controller = TextEditingController(
      text: ref.read(createTeamProvider).name,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
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
              currentStep: 0,
              labels: createTeamStepLabels,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              "What's your team called?",
              style: AppTypography.h2.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (!state.canCreateAnotherTeam)
              Container(
                key: const ValueKey('teamLimitReachedBanner'),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  border: Border.all(color: colors.error),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "You already own $maxOwnedTeams teams -- that's the "
                  'limit. Contact support to raise it.',
                  style: AppTypography.body.copyWith(color: colors.error),
                ),
              )
            else ...[
              AppTextField(
                key: const ValueKey('teamNameField'),
                label: 'Team name',
                controller: _controller,
                helperText: state.nameTaken
                    ? 'That name is already taken in ${state.city}'
                    : 'At least 3 characters',
                validator: (_) => state.nameTaken
                    ? 'That name is already taken in ${state.city}'
                    : null,
                onChanged: notifier.setName,
              ),
              if (state.nameTaken) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  key: const ValueKey('teamNameSuggestions'),
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final suggestion in state.nameSuggestions)
                      AppChipActionButton(
                        label: suggestion,
                        onPressed: () {
                          _controller.text = suggestion;
                          notifier.setName(suggestion);
                        },
                      ),
                  ],
                ),
              ],
            ],
            const Spacer(),
            AppButton(
              key: const ValueKey('teamNameContinue'),
              variant: AppButtonVariant.primary,
              label: 'Continue',
              fullWidth: true,
              onPressed: state.canContinueFromName && state.canCreateAnotherTeam
                  ? widget.onContinue
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
