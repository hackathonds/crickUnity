import 'package:flutter/material.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';

/// E16-09 pairs "Wearable glances" with "TV Scoreboard mode" (DS §3.11,
/// implemented in `tv_scoreboard_screen.dart`), but "Wearable glances" is
/// never described anywhere in either frozen source document: no watch-
/// face mockup, no data fields, no companion-app platform named, not even
/// a passing mention (checked PRD and DS in full for "wearable"/"watch"/
/// "glance"). Per this project's rule to never invent behavior for a
/// genuinely absent detail, this screen is an explicit gap notice rather
/// than a guessed watch-face UI -- same "no PRD/DS grounding" treatment
/// E16-07 gave its own Help/feature-request board.
class WearableGlancesScreen extends StatelessWidget {
  const WearableGlancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Wearable glances')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Container(
          key: const ValueKey('wearableGlancesGapNotice'),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            'Wearable glances has no design or behavior spec in the PRD or '
            'Design Spec -- no watch face, data fields, or platform are '
            'named anywhere. Flagging as an open question rather than '
            'guessing: which wearable platform(s), and what should the '
            'glance actually show?',
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
        ),
      ),
    );
  }
}
