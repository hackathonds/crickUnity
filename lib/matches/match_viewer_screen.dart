import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../offline/is_online_provider.dart';
import 'scoring_provider.dart';

/// PRD §7.7 offline UX: "viewers see 'Score paused -- scorer offline'
/// freshness stamp." A deliberately minimal read-only spectator screen
/// just to carry that one stamp -- the full Live Match View (DS §7
/// screen 28: Commentary/Scorecard/Charts/Gallery tabs, auto-scroll,
/// fan prediction chip) is E4-11's separate, much larger scope.
class MatchViewerScreen extends ConsumerWidget {
  const MatchViewerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(inningsProvider);
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Match')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.battingTeamName,
              style: AppTypography.subtitle.copyWith(
                color: colors.textSecondary,
              ),
            ),
            Text(
              '${state.totalRuns}/${state.wicketsLost} '
              '(${state.completedOvers}.${state.legalBallsThisOver} ov)',
              style: AppTypography.scoreboard.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (!isOnline)
              Container(
                key: const ValueKey('scorePausedStamp'),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.disabledBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Score paused -- scorer offline',
                  style: AppTypography.body.copyWith(color: colors.disabledFg),
                ),
              )
            else
              Text(
                key: const ValueKey('liveStamp'),
                'Live',
                style: AppTypography.caption.copyWith(color: colors.live),
              ),
          ],
        ),
      ),
    );
  }
}
