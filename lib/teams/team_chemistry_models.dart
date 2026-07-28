/// PRD §6.28: "Chemistry score (team-private): composite of attendance,
/// availability response rate, settlement speed, roster stability. Trends
/// chart helps captains spot decay ('Chemistry down 12% -- 4 unsettled
/// expenses > 2 weeks')."
library;

enum ChemistryFactorKind {
  attendance,
  availabilityResponseRate,
  settlementSpeed,
  rosterStability,
}

const Map<ChemistryFactorKind, String> chemistryFactorLabels = {
  ChemistryFactorKind.attendance: 'Attendance',
  ChemistryFactorKind.availabilityResponseRate: 'Availability response',
  ChemistryFactorKind.settlementSpeed: 'Settlement speed',
  ChemistryFactorKind.rosterStability: 'Roster stability',
};

class ChemistryFactor {
  final ChemistryFactorKind kind;

  /// 0..1 -- rendered as a factor bar.
  final double value;

  const ChemistryFactor({required this.kind, required this.value});

  String get label => chemistryFactorLabels[kind]!;
}

/// PRD §6.28's composite spans four other modules (attendance from Practice
/// Sessions E3-07, availability from E3-06, settlement speed from E5-04,
/// roster stability from team join/leave logs) -- none of those write to a
/// shared store in this prototype, so the composite is computed from mock
/// factor inputs, same honest-gap convention used throughout (e.g. Season
/// Summary's milestone counters). This is now the single canonical source
/// other screens (Season Summary, E13-03 captain analytics) read from.
class TeamChemistry {
  final List<ChemistryFactor> factors;

  /// 12 weekly points, 0..1, oldest first.
  final List<double> weeklyTrend;

  final String insightText;

  const TeamChemistry({
    required this.factors,
    required this.weeklyTrend,
    required this.insightText,
  });

  double get compositeScore =>
      factors.map((f) => f.value).reduce((a, b) => a + b) / factors.length;

  /// Percent change from the trend's first to last point -- the same
  /// figure other screens display as `chemistryTrendPercent`.
  int get trendPercent {
    final first = weeklyTrend.first;
    final last = weeklyTrend.last;
    if (first == 0) return 0;
    return (((last - first) / first) * 100).round();
  }

  ChemistryFactor factor(ChemistryFactorKind kind) =>
      factors.firstWhere((f) => f.kind == kind);
}

TeamChemistry mockTeamChemistry() => const TeamChemistry(
  factors: [
    ChemistryFactor(kind: ChemistryFactorKind.attendance, value: 0.82),
    ChemistryFactor(
      kind: ChemistryFactorKind.availabilityResponseRate,
      value: 0.74,
    ),
    ChemistryFactor(kind: ChemistryFactorKind.settlementSpeed, value: 0.51),
    ChemistryFactor(kind: ChemistryFactorKind.rosterStability, value: 0.9),
  ],
  weeklyTrend: [
    0.74,
    0.75,
    0.77,
    0.79,
    0.8,
    0.81,
    0.83,
    0.82,
    0.8,
    0.77,
    0.73,
    0.65,
  ],
  insightText:
      "4 unsettled expenses > 2 weeks -- main drag on this month's score.",
);
