/// PRD §18: "Ranks: competitive percentile bands per city+format+
/// discipline (Bronze->Silver->Gold->Platinum->Elite); soft decay for
/// 60-day inactivity (bands only, historical peaks preserved); rank !=
/// level (rank = skill, level = journey) -- explained in-product."
/// Backlog: "distinct from leaderboards, was uncovered" -- this is a
/// separate concept from recognition/leaderboard_models.dart's ranked
/// lists (leaderboards compare raw metric totals; ranks are a
/// percentile-among-peers skill band).
enum RankBand { bronze, silver, gold, platinum, elite }

const Map<RankBand, String> rankBandLabels = {
  RankBand.bronze: 'Bronze',
  RankBand.silver: 'Silver',
  RankBand.gold: 'Gold',
  RankBand.platinum: 'Platinum',
  RankBand.elite: 'Elite',
};

/// PRD names the 5 bands, not their percentile cutoffs -- a flagged
/// judgment call.
const List<(RankBand, int)> rankBandThresholds = [
  (RankBand.elite, 95),
  (RankBand.platinum, 85),
  (RankBand.gold, 65),
  (RankBand.silver, 40),
  (RankBand.bronze, 0),
];

RankBand bandForPercentile(int percentile) {
  for (final (band, threshold) in rankBandThresholds) {
    if (percentile >= threshold) return band;
  }
  return RankBand.bronze;
}

enum RankDiscipline { batting, bowling, allRounder }

const Map<RankDiscipline, String> rankDisciplineLabels = {
  RankDiscipline.batting: 'Batting',
  RankDiscipline.bowling: 'Bowling',
  RankDiscipline.allRounder: 'All-rounder',
};

const int rankDecayInactivityDays = 60;

/// This app has no separate match-format taxonomy comparable to real
/// cricket's T20/ODI/long-form split (match_models.dart's MatchFormat
/// is an overs/rules config, not a named category to rank within) --
/// [formatLabel] is a plain descriptive string rather than a second
/// structured enum, a flagged simplification.
class RankProfile {
  final RankDiscipline discipline;
  final String cityLabel;
  final String formatLabel;
  final int percentile;
  final RankBand historicalPeakBand;
  final DateTime lastActiveAt;

  const RankProfile({
    required this.discipline,
    required this.cityLabel,
    required this.formatLabel,
    required this.percentile,
    required this.historicalPeakBand,
    required this.lastActiveAt,
  });

  /// "Soft decay for 60-day inactivity (bands only, historical peaks
  /// preserved)" -- the live band steps down one tier once inactive
  /// past the window; the historical peak never moves.
  RankBand currentBand({DateTime Function() now = DateTime.now}) {
    final computed = bandForPercentile(percentile);
    final inactiveDays = now().difference(lastActiveAt).inDays;
    if (inactiveDays < rankDecayInactivityDays) return computed;
    final index = RankBand.values.indexOf(computed);
    return RankBand.values[(index - 1).clamp(0, RankBand.values.length - 1)];
  }

  bool isDecayed({DateTime Function() now = DateTime.now}) =>
      now().difference(lastActiveAt).inDays >= rankDecayInactivityDays;
}
