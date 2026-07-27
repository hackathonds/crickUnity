/// PRD §19 "Captain Analytics" bullet: "toss decisions vs outcomes,
/// bowling-change impact index, selection stability, win % by lineup
/// cluster, availability-response health of squad." *Rec:* "Teams you
/// chase against: 71% wins -- consider bowling first."
/// PRD §19 "Team Analytics" bullet: "§6.17 + margin distributions,
/// collapse frequency, ground-wise record, chemistry trend."
/// Backlog cites this story (E13-03) as "PRD §19.4-19.6" -- PRD §19 has
/// no numbered subsections at all (same class of approximate citation
/// as E13-01's phantom DS §19.2 and E13-02's phantom PRD §19.3), flagged
/// rather than guessed at. The bullet content itself is real.
library;

import 'player_analytics_models.dart' show InsightItem, RecommendationItem;

enum TossDecision { batFirst, bowlFirst }

const Map<TossDecision, String> tossDecisionLabels = {
  TossDecision.batFirst: 'Bat first',
  TossDecision.bowlFirst: 'Bowl first',
};

class TossOutcomeStat {
  final int wins;
  final int total;

  const TossOutcomeStat({this.wins = 0, this.total = 0});

  double get winPercent => total == 0 ? 0 : 100 * wins / total;
}

/// PRD: "bowling-change impact index." PRD/DS name no formula -- flagged
/// judgment call (same convention as scoring_models.dart's dot-pressure/
/// win-prob heuristics): the average economy swing across every
/// captain-initiated bowling change this session's mock dataset flags.
class BowlingChangeImpact {
  final double avgEconomyBefore;
  final double avgEconomyAfter;

  const BowlingChangeImpact({
    required this.avgEconomyBefore,
    required this.avgEconomyAfter,
  });

  double get delta => avgEconomyBefore - avgEconomyAfter;
}

/// PRD: "selection stability." No spec for the exact metric -- flagged
/// as "% of the last XI unchanged from the previous match," a common,
/// legible reading of "stability."
class SelectionStability {
  final double percentUnchanged;

  const SelectionStability({required this.percentUnchanged});
}

/// PRD: "win % by lineup cluster." No clustering algorithm is specified
/// -- flagged judgment call: clusters are simply "same XI," "1-2
/// changes," "3+ changes" from the previous match, the simplest
/// legible reading of "cluster" available without inventing a real
/// similarity model.
class LineupClusterStat {
  final String label;
  final int wins;
  final int total;

  const LineupClusterStat({required this.label, this.wins = 0, this.total = 0});

  double get winPercent => total == 0 ? 0 : 100 * wins / total;
}

class AvailabilityResponseHealth {
  final int respondedOnTime;
  final int totalAsked;

  const AvailabilityResponseHealth({
    this.respondedOnTime = 0,
    this.totalAsked = 0,
  });

  double get percent =>
      totalAsked == 0 ? 0 : 100 * respondedOnTime / totalAsked;
}

class MarginBucketStat {
  final String label;
  final int count;

  const MarginBucketStat({required this.label, required this.count});
}

/// PRD: "collapse frequency." No definition given -- flagged as
/// "3+ wickets fell within a span of 3 overs," the standard commentary
/// reading of a batting collapse.
class CollapseFrequency {
  final int matchesWithCollapse;
  final int totalMatches;

  const CollapseFrequency({
    this.matchesWithCollapse = 0,
    this.totalMatches = 0,
  });

  double get percent =>
      totalMatches == 0 ? 0 : 100 * matchesWithCollapse / totalMatches;
}

class GroundRecordStat {
  final String groundName;
  final int wins;
  final int losses;
  final int draws;

  const GroundRecordStat({
    required this.groundName,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
  });

  int get played => wins + losses + draws;
}

class CaptainAnalyticsSnapshot {
  final Map<TossDecision, TossOutcomeStat> tossOutcomes;
  final BowlingChangeImpact? bowlingChangeImpact;
  final SelectionStability selectionStability;
  final List<LineupClusterStat> lineupClusters;
  final AvailabilityResponseHealth availabilityHealth;
  final List<InsightItem> insights;
  final List<RecommendationItem> recommendations;

  const CaptainAnalyticsSnapshot({
    required this.tossOutcomes,
    required this.bowlingChangeImpact,
    required this.selectionStability,
    required this.lineupClusters,
    required this.availabilityHealth,
    required this.insights,
    required this.recommendations,
  });
}

class TeamAnalyticsSnapshot {
  final int wins;
  final int losses;
  final int draws;
  final double winPercentBattingFirst;
  final double winPercentChasing;
  final String topRunScorer;
  final String topWicketTaker;
  final List<MarginBucketStat> marginDistribution;
  final CollapseFrequency collapseFrequency;
  final List<GroundRecordStat> groundRecords;
  final int chemistryTrendPercent;
  final List<InsightItem> insights;
  final List<RecommendationItem> recommendations;

  const TeamAnalyticsSnapshot({
    required this.wins,
    required this.losses,
    required this.draws,
    required this.winPercentBattingFirst,
    required this.winPercentChasing,
    required this.topRunScorer,
    required this.topWicketTaker,
    required this.marginDistribution,
    required this.collapseFrequency,
    required this.groundRecords,
    required this.chemistryTrendPercent,
    required this.insights,
    required this.recommendations,
  });
}
