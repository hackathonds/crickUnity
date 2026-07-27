import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'player_analytics_data.dart';

/// The mock career dataset (player_analytics_data.dart's own doc comment
/// explains why it's synthetic -- no persisted cross-match history store
/// exists in the app yet). Exposed as a provider, not a bare function
/// call, so any future screen needing the same player's career data
/// reads the same source rather than re-generating its own copy.
final playerAnalyticsMatchesProvider = Provider<List<MatchPerformance>>((ref) {
  return mockCareerMatches(DateTime.now());
});
