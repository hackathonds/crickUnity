import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../teams/team_chemistry_models.dart' show mockTeamChemistry;
import 'team_captain_analytics_data.dart';

final teamCaptainMatchesProvider = Provider<List<TeamMatchRecord>>((ref) {
  return mockTeamSeason(DateTime.now());
});

/// E3-12's canonical chemistry figure, shared with Season Summary.
final chemistryTrendPercentProvider = Provider<int>((ref) {
  return mockTeamChemistry().trendPercent;
});
