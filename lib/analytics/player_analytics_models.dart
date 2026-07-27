/// PRD §19 (Analytics): "Each analytics surface: time filters (match/
/// month/season/career), compare-to (self past, team avg, city avg),
/// export share-card, and an Insights strip (plain-language findings) +
/// Recommendations strip (next best actions)." Backlog cites this as
/// "PRD §19.3," but PRD §19 has no numbered subsections at all -- an
/// approximate citation (same class of gap as E13-01's phantom DS §19.2),
/// flagged rather than guessed at. The bullet content itself
/// ("Player Analytics: batting phase-wise SR, dismissal patterns, vs
/// pace/spin, entry-point analysis; bowling phase economy, lengths proxy
/// via outcome mix, vs LHB/RHB; fielding contributions, form index,
/// fatigue signal, availability-vs-performance correlation") is real and
/// is exactly what this module computes.
library;

import '../matches/scoring_models.dart' show DismissalType, dismissalTypeLabels;
import '../onboarding/profile_wizard_provider.dart' show BattingStyle;

enum AnalyticsTimeFilter { match, month, season, career }

const Map<AnalyticsTimeFilter, String> analyticsTimeFilterLabels = {
  AnalyticsTimeFilter.match: 'Match',
  AnalyticsTimeFilter.month: 'Month',
  AnalyticsTimeFilter.season: 'Season',
  AnalyticsTimeFilter.career: 'Career',
};

enum AnalyticsCompareTo { selfPast, teamAvg, cityAvg }

const Map<AnalyticsCompareTo, String> analyticsCompareToLabels = {
  AnalyticsCompareTo.selfPast: 'Self (past)',
  AnalyticsCompareTo.teamAvg: 'Team avg',
  AnalyticsCompareTo.cityAvg: 'City avg',
};

/// Standard T20-style thirds. No fixed-overs assumption exists elsewhere
/// in the scoring model (totalOversPerSide is match-configurable), so
/// phase boundaries here are fractional (first 30% of overs = powerplay,
/// next 45% = middle, last 25% = death) rather than hardcoded over
/// numbers -- consistent with InningsState.effectiveTotalOvers already
/// being variable.
enum MatchPhase { powerplay, middle, death }

const Map<MatchPhase, String> matchPhaseLabels = {
  MatchPhase.powerplay: 'Powerplay',
  MatchPhase.middle: 'Middle',
  MatchPhase.death: 'Death',
};

/// PRD/DS name no bowler pace/spin classification anywhere in the app
/// (Player profile only ever captures [BattingStyle], not a bowling
/// discipline) -- flagged mock dimension, same convention as
/// scoring_models.dart's own dot-pressure/win-prob heuristics.
enum BowlerType { pace, spin }

const Map<BowlerType, String> bowlerTypeLabels = {
  BowlerType.pace: 'Pace',
  BowlerType.spin: 'Spin',
};

/// PRD: "lengths proxy via outcome mix" -- PRD/DS name no real pitch-map
/// length data (nothing in the scorer console captures ball length);
/// this proxy classifies a legal delivery's *length bucket* purely from
/// its scoring outcome, the same "outcome mix" the PRD line names.
enum DeliveryLengthProxy { short, good, full }

const Map<DeliveryLengthProxy, String> deliveryLengthProxyLabels = {
  DeliveryLengthProxy.short: 'Short (proxy)',
  DeliveryLengthProxy.good: 'Good length (proxy)',
  DeliveryLengthProxy.full: 'Full (proxy)',
};

class PhaseSplitStat {
  final int runs;
  final int balls;
  final int dismissals;

  const PhaseSplitStat({this.runs = 0, this.balls = 0, this.dismissals = 0});

  double get strikeRate => balls == 0 ? 0 : 100 * runs / balls;
  double get average => dismissals == 0 ? runs.toDouble() : runs / dismissals;

  PhaseSplitStat operator +(PhaseSplitStat other) => PhaseSplitStat(
    runs: runs + other.runs,
    balls: balls + other.balls,
    dismissals: dismissals + other.dismissals,
  );
}

class DismissalPatternEntry {
  final DismissalType type;
  final int count;

  const DismissalPatternEntry({required this.type, required this.count});

  String get label => dismissalTypeLabels[type]!;
}

class EntryPointStat {
  final int battingPosition;
  final int runs;
  final int innings;
  final int dismissals;

  const EntryPointStat({
    required this.battingPosition,
    this.runs = 0,
    this.innings = 0,
    this.dismissals = 0,
  });

  double get average => dismissals == 0 ? runs.toDouble() : runs / dismissals;
}

class BowlingPhaseStat {
  final int runsConceded;
  final int legalBalls;
  final int wickets;

  const BowlingPhaseStat({
    this.runsConceded = 0,
    this.legalBalls = 0,
    this.wickets = 0,
  });

  double get economy => legalBalls == 0 ? 0 : 6 * runsConceded / legalBalls;

  BowlingPhaseStat operator +(BowlingPhaseStat other) => BowlingPhaseStat(
    runsConceded: runsConceded + other.runsConceded,
    legalBalls: legalBalls + other.legalBalls,
    wickets: wickets + other.wickets,
  );
}

class VsBattingStyleStat {
  final int runsConceded;
  final int legalBalls;
  final int wickets;

  const VsBattingStyleStat({
    this.runsConceded = 0,
    this.legalBalls = 0,
    this.wickets = 0,
  });

  double get economy => legalBalls == 0 ? 0 : 6 * runsConceded / legalBalls;
}

class FieldingContribution {
  final int catches;
  final int runOuts;
  final int stumpings;

  const FieldingContribution({
    this.catches = 0,
    this.runOuts = 0,
    this.stumpings = 0,
  });

  int get total => catches + runOuts + stumpings;
}

class FormIndexPoint {
  final String matchLabel;
  final double index;

  const FormIndexPoint({required this.matchLabel, required this.index});
}

/// PRD: "fatigue signal (games/week)." No load-management model exists
/// elsewhere -- a simple count + banded, non-alarming caption (DS
/// Progress Card convention: "never shame").
class FatigueSignal {
  final int gamesThisWeek;

  const FatigueSignal({required this.gamesThisWeek});

  String get caption => switch (gamesThisWeek) {
    <= 1 => 'Light week -- plenty of recovery time.',
    2 || 3 => 'Steady week -- normal load.',
    _ => 'Busy week -- $gamesThisWeek games. Worth a rest day.',
  };
}

class AvailabilityPerformanceCorrelation {
  final double avgRunsWhenRespondedEarly;
  final double avgRunsWhenRespondedLate;

  const AvailabilityPerformanceCorrelation({
    required this.avgRunsWhenRespondedEarly,
    required this.avgRunsWhenRespondedLate,
  });
}

class InsightItem {
  final String text;

  const InsightItem(this.text);
}

class RecommendationItem {
  final String text;

  const RecommendationItem(this.text);
}

class PlayerAnalyticsSnapshot {
  final Map<MatchPhase, PhaseSplitStat> battingPhaseSplits;
  final List<DismissalPatternEntry> dismissalPatterns;
  final Map<BowlerType, PhaseSplitStat> vsBowlerType;
  final List<EntryPointStat> entryPointStats;
  final Map<MatchPhase, BowlingPhaseStat> bowlingPhaseEconomy;
  final Map<DeliveryLengthProxy, int> lengthsProxyMix;
  final Map<BattingStyle, VsBattingStyleStat> vsBattingStyle;
  final FieldingContribution fielding;
  final List<FormIndexPoint> formIndexSeries;
  final FatigueSignal fatigue;
  final AvailabilityPerformanceCorrelation availabilityCorrelation;
  final List<InsightItem> insights;
  final List<RecommendationItem> recommendations;

  const PlayerAnalyticsSnapshot({
    required this.battingPhaseSplits,
    required this.dismissalPatterns,
    required this.vsBowlerType,
    required this.entryPointStats,
    required this.bowlingPhaseEconomy,
    required this.lengthsProxyMix,
    required this.vsBattingStyle,
    required this.fielding,
    required this.formIndexSeries,
    required this.fatigue,
    required this.availabilityCorrelation,
    required this.insights,
    required this.recommendations,
  });
}
