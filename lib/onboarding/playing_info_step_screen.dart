import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'profile_completeness_meter.dart';
import 'profile_wizard_provider.dart';

const Map<PrimaryRole, String> _primaryRoleLabels = {
  PrimaryRole.batter: 'Batter',
  PrimaryRole.bowler: 'Bowler',
  PrimaryRole.allRounder: 'All-rounder',
  PrimaryRole.wicketKeeper: 'Wicket-keeper',
};

const Map<BattingStyle, String> _battingStyleLabels = {
  BattingStyle.rhb: 'Right-hand bat',
  BattingStyle.lhb: 'Left-hand bat',
};

/// DS §11.3 Profile wizard, step 3: "playing info chips." Reuses
/// [AppChipActionButton] (already built, E0-07) rather than a new
/// selectable-chip primitive -- same reasoning as the Segmented control's
/// >4-option fallback.
class PlayingInfoStepScreen extends ConsumerWidget {
  final VoidCallback onContinue;

  const PlayingInfoStepScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(profileWizardProvider);
    final notifier = ref.read(profileWizardProvider.notifier);

    Widget sectionLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTypography.label.copyWith(color: colors.textTertiary),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Set up your profile')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ProfileCompletenessMeter(),
            const SizedBox(height: AppSpacing.xxl),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How do you play?',
                      style: AppTypography.h2.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    sectionLabel('Primary role'),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final role in PrimaryRole.values)
                          AppChipActionButton(
                            key: ValueKey('playingInfoRole_${role.name}'),
                            label: _primaryRoleLabels[role]!,
                            selected: state.primaryRole == role,
                            onPressed: () => notifier.setPrimaryRole(
                              state.primaryRole == role ? null : role,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    sectionLabel('Batting style'),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final style in BattingStyle.values)
                          AppChipActionButton(
                            key: ValueKey(
                              'playingInfoBattingStyle_${style.name}',
                            ),
                            label: _battingStyleLabels[style]!,
                            selected: state.battingStyle == style,
                            onPressed: () => notifier.setBattingStyle(
                              state.battingStyle == style ? null : style,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              key: const ValueKey('playingInfoContinue'),
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
