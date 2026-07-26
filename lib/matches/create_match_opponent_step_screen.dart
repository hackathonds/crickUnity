import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_form_step_progress.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'create_match_basics_step_screen.dart';
import 'create_match_provider.dart';

/// DS §7 screen 24, step 2: "Opponent(search/QR/recent)." No real team
/// directory or QR-scan integration exists yet -- opponent selection is
/// a plain text field, plus PRD §7.1's "vs ad-hoc 'guest team' created
/// inline" toggle.
class CreateMatchOpponentStepScreen extends ConsumerStatefulWidget {
  final VoidCallback onContinue;

  const CreateMatchOpponentStepScreen({super.key, required this.onContinue});

  @override
  ConsumerState<CreateMatchOpponentStepScreen> createState() =>
      _CreateMatchOpponentStepScreenState();
}

class _CreateMatchOpponentStepScreenState
    extends ConsumerState<CreateMatchOpponentStepScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(createMatchProvider).draft.opponentTeamName,
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
              currentStep: 1,
              labels: createMatchStepLabels,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ad-hoc guest team (not on CricUnity)',
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Switch(
                  key: const ValueKey('guestTeamSwitch'),
                  value: draft.isGuestTeam,
                  onChanged: notifier.setIsGuestTeam,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const ValueKey('opponentTeamNameField'),
              label: draft.isGuestTeam ? 'Guest team name' : 'Opponent team',
              controller: _controller,
              onChanged: notifier.setOpponentTeamName,
            ),
            const Spacer(),
            AppButton(
              key: const ValueKey('opponentContinueButton'),
              variant: AppButtonVariant.primary,
              label: 'Continue',
              fullWidth: true,
              onPressed: draft.opponentTeamName.trim().isNotEmpty
                  ? widget.onContinue
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
