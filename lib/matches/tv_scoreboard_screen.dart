import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_scoreboard.dart';
import '../design_system/tokens/app_colors.dart';
import 'scoring_provider.dart';

/// DS §3.11: "TV Scoreboard mode: same component scaled ×3, dark
/// high-contrast, auto-cycling bowler/batter strips every 8s." The
/// [AppScoreboard] widget already implements the `tvMode` scale/cycling
/// (built with E0-08) -- this screen is E16-09's missing piece: a real,
/// reachable full-screen entry point (from Live Match View) feeding it
/// live match state, meant for propping a phone up pitch-side or casting
/// to a TV during a match.
class TvScoreboardScreen extends ConsumerWidget {
  const TvScoreboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inningsProvider);

    final striker = state.batters[state.strikerName];
    final nonStriker = state.batters[state.nonStrikerName];
    final bowler = state.bowlers[state.currentBowlerName];

    final battersStrip =
        '${state.strikerName}* ${striker?.runs ?? 0} '
        '(${striker?.balls ?? 0}) · '
        '${state.nonStrikerName} ${nonStriker?.runs ?? 0} '
        '(${nonStriker?.balls ?? 0})';
    final bowlerStrip =
        '${state.currentBowlerName} '
        '${bowler?.completedOvers ?? 0}.${bowler?.ballsThisOver ?? 0}-'
        '${bowler?.runsConceded ?? 0}-${bowler?.wickets ?? 0}';

    return Scaffold(
      backgroundColor: AppColors.theme4.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: AppScoreboard(
                key: const ValueKey('tvScoreboard'),
                teamAShortName: _shortTeamName(state.battingTeamName),
                teamBShortName: _shortTeamName(state.bowlingTeamName),
                runs: state.totalRuns,
                wickets: state.wicketsLost,
                overs: '${state.completedOvers}.${state.legalBallsThisOver}',
                contextStrip: battersStrip,
                tvMode: true,
                tvCyclingStrips: [battersStrip, bowlerStrip],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                key: const ValueKey('exitTvModeButton'),
                icon: Icon(Icons.close, color: AppColors.theme4.textPrimary),
                tooltip: 'Exit TV mode',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// [AppScoreboard]'s teams row is a "short name" slot (DS §3.11: "crest 24
/// + short name 13") -- no team-abbreviation model exists yet, so this
/// derives simple initials from the full team name as a stand-in (e.g.
/// "Riverside Strikers" -> "RS").
String _shortTeamName(String fullName) {
  final words = fullName.split(' ').where((w) => w.isNotEmpty);
  final initials = words.map((w) => w[0].toUpperCase()).join();
  return initials.isEmpty ? fullName : initials;
}
