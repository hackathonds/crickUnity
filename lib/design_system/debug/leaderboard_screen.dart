import 'package:flutter/material.dart';

import '../components/app_leaderboard_row.dart';
import '../tokens/app_spacing.dart';

/// QA tool for E0-08 (sub-task 5/12): [AppLeaderboardRow] and
/// [AppLeaderboardList]'s sticky self-clone. Scroll the list past "my
/// row" (Deepak Sharma, rank 8) to see the clone dock to the bottom.
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  static final _rows = [
    const AppLeaderboardRowData(
      rank: 1,
      name: 'Arjun Rao',
      teamCaption: 'Titans',
      metric: '512',
      movement: AppLeaderboardMovement.up,
      movementValue: 1,
    ),
    const AppLeaderboardRowData(
      rank: 2,
      name: 'Simran Kaur',
      teamCaption: 'Strikers',
      metric: '498',
      movement: AppLeaderboardMovement.down,
      movementValue: 1,
    ),
    const AppLeaderboardRowData(
      rank: 3,
      name: 'Priya Nair',
      teamCaption: 'Riverside',
      metric: '470',
    ),
    for (var i = 4; i <= 7; i++)
      AppLeaderboardRowData(
        rank: i,
        name: 'Player $i',
        teamCaption: 'Team $i',
        metric: '${450 - i * 10}',
      ),
    const AppLeaderboardRowData(
      rank: 8,
      name: 'Deepak Sharma',
      teamCaption: 'Titans',
      metric: '380',
      movement: AppLeaderboardMovement.up,
      movementValue: 2,
    ),
    for (var i = 9; i <= 20; i++)
      AppLeaderboardRowData(
        rank: i,
        name: 'Player $i',
        teamCaption: 'Team $i',
        metric: '${400 - i * 8}',
      ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard (QA)')),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: AppLeaderboardList(rows: _rows, myIndex: 7),
      ),
    );
  }
}
