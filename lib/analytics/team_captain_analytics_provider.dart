import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../teams/season_summary_models.dart' show mockSeasonSummary;
import 'team_captain_analytics_data.dart';

final teamCaptainMatchesProvider = Provider<List<TeamMatchRecord>>((ref) {
  return mockTeamSeason(DateTime.now());
});

/// Reuses the real (if mock) chemistry figure from season_summary_models.dart
/// (E6-19's Season Wrap) rather than inventing a second one here.
final chemistryTrendPercentProvider = Provider<int>((ref) {
  return mockSeasonSummary().chemistryTrendPercent;
});
