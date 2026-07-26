import 'package:flutter/material.dart';

import '../components/app_scoreboard.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// QA tool for E0-08 (sub-task 11/12): [AppScoreboard] -- odometer roll,
/// wicket flash, and TV mode.
class ScoreboardScreen extends StatefulWidget {
  const ScoreboardScreen({super.key});

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  int _runs = 142;
  int _wickets = 3;
  bool _tvMode = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm,
        top: AppSpacing.xxl,
      ),
      child: Text(
        text,
        style: AppTypography.label.copyWith(color: colors.textTertiary),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Scoreboard (QA)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label('Live scoreboard'),
            AppScoreboard(
              teamAShortName: 'TTN',
              teamBShortName: 'STR',
              runs: _runs,
              wickets: _wickets,
              overs: '14.2',
              contextStrip: 'CRR 9.9 · Need 47 off 34',
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _runs += 4),
                  child: const Text('+4 runs'),
                ),
                TextButton(
                  onPressed: () => setState(() => _wickets += 1),
                  child: const Text('Wicket!'),
                ),
                TextButton(
                  onPressed: () => setState(() => _tvMode = !_tvMode),
                  child: Text(_tvMode ? 'Exit TV mode' : 'TV mode'),
                ),
              ],
            ),
            if (_tvMode) ...[
              label('TV mode — scaled ×3, dark high-contrast, auto-cycling'),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: AppScoreboard(
                  teamAShortName: 'TTN',
                  teamBShortName: 'STR',
                  runs: _runs,
                  wickets: _wickets,
                  overs: '14.2',
                  contextStrip: 'CRR 9.9 · Need 47 off 34',
                  tvMode: true,
                  tvCyclingStrips: const [
                    'Sharma 3/28 (4 ov)',
                    'Kumar 34* (22b) · Rao 12* (10b)',
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
