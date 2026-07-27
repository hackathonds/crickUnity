import '../matches/scoring_models.dart' show Delivery, DismissalType;
import '../onboarding/profile_wizard_provider.dart' show BattingStyle;
import 'player_analytics_models.dart';

/// One synthetic match's worth of this player's involvement. No
/// persisted cross-match history store exists anywhere in the app yet
/// (E4's Live Scoring / InningsState only ever holds *one current*
/// innings in memory -- nothing survives past a match) -- flagged mock
/// career dataset, same convention as every other missing-backend gap
/// this session (e.g. selection_board_models.dart's mockSelectionPool).
/// Real [Delivery] objects are reused for the ball-by-ball facts
/// (runs/wicket/legality/dismissal type) so only the dimensions the app
/// genuinely has no model for (bowler pace/spin, match phase, striker's
/// batting style when this player bowls) are carried as small parallel
/// tags rather than invented fields on a duplicate ball model.
class FacedBall {
  final Delivery delivery;
  final MatchPhase phase;
  final BowlerType bowlerType;

  const FacedBall(this.delivery, this.phase, this.bowlerType);
}

class BowledBall {
  final Delivery delivery;
  final MatchPhase phase;
  final BattingStyle strikerStyle;

  const BowledBall(this.delivery, this.phase, this.strikerStyle);
}

class MatchPerformance {
  final String label;
  final DateTime date;
  final int battingPosition;
  final List<FacedBall> facedBalls;
  final List<BowledBall> bowledBalls;
  final int catches;
  final int runOuts;
  final int stumpings;
  final bool respondedEarly;
  final double teamAvgRuns;
  final double cityAvgRuns;

  const MatchPerformance({
    required this.label,
    required this.date,
    required this.battingPosition,
    required this.facedBalls,
    required this.bowledBalls,
    this.catches = 0,
    this.runOuts = 0,
    this.stumpings = 0,
    required this.respondedEarly,
    required this.teamAvgRuns,
    required this.cityAvgRuns,
  });

  int get runsScored =>
      facedBalls.fold(0, (a, b) => a + b.delivery.battingRuns);
  bool get wasDismissed => facedBalls.any((b) => b.delivery.isWicket);
  int get wicketsTaken => bowledBalls.where((b) => b.delivery.isWicket).length;
}

Delivery _ball({
  required String bowler,
  required int runs,
  bool isWicket = false,
  DismissalType? dismissalType,
  bool isLegal = true,
}) => Delivery(
  bowlerName: bowler,
  runs: runs,
  isWicket: isWicket,
  dismissalType: dismissalType,
  isLegal: isLegal,
);

/// A fixed, deterministic mock career spanning ~10 matches over the last
/// ~5 months -- deterministic (not random) so QA screenshots are stable,
/// same convention as the E12 search fixtures.
List<MatchPerformance> mockCareerMatches(DateTime now) {
  const paceBowlers = ['Rohan Verma', 'Suresh Patel', 'Aditya Kumar'];
  const spinBowlers = ['Imran Khan', 'Kabir Singh'];

  MatchPhase phaseFor(int overIndex, int totalOvers) {
    final fraction = overIndex / totalOvers;
    if (fraction < 0.3) return MatchPhase.powerplay;
    if (fraction < 0.75) return MatchPhase.middle;
    return MatchPhase.death;
  }

  List<FacedBall> faced(
    List<(int runs, bool wicket, DismissalType? dismissal, int over)> balls,
  ) => [
    for (final (i, b) in balls.indexed)
      FacedBall(
        _ball(
          bowler: i.isEven
              ? paceBowlers[i % paceBowlers.length]
              : spinBowlers[i % spinBowlers.length],
          runs: b.$1,
          isWicket: b.$2,
          dismissalType: b.$3,
        ),
        phaseFor(b.$4, 20),
        i.isEven ? BowlerType.pace : BowlerType.spin,
      ),
  ];

  List<BowledBall> bowled(List<(int runs, bool wicket, int over)> balls) => [
    for (final (i, b) in balls.indexed)
      BowledBall(
        _ball(bowler: 'Deepak Sharma', runs: b.$1, isWicket: b.$2),
        phaseFor(b.$3, 20),
        i.isEven ? BattingStyle.rhb : BattingStyle.lhb,
      ),
  ];

  return [
    MatchPerformance(
      label: 'vs Titans',
      date: now.subtract(const Duration(days: 3)),
      battingPosition: 3,
      facedBalls: faced([
        (4, false, null, 1),
        (0, false, null, 2),
        (6, false, null, 8),
        (1, false, null, 9),
        (2, false, null, 14),
        (4, false, null, 16),
        (0, true, DismissalType.caught, 18),
      ]),
      bowledBalls: bowled([(0, false, 4), (2, false, 5), (1, true, 5)]),
      catches: 1,
      respondedEarly: true,
      teamAvgRuns: 142,
      cityAvgRuns: 130,
    ),
    MatchPerformance(
      label: 'vs Riverside Warriors',
      date: now.subtract(const Duration(days: 10)),
      battingPosition: 3,
      facedBalls: faced([
        (1, false, null, 0),
        (4, false, null, 1),
        (0, false, null, 10),
        (0, false, null, 11),
        (6, false, null, 17),
        (0, true, DismissalType.bowled, 19),
      ]),
      bowledBalls: bowled([(4, false, 3), (0, false, 3), (0, true, 4)]),
      runOuts: 1,
      respondedEarly: true,
      teamAvgRuns: 155,
      cityAvgRuns: 130,
    ),
    MatchPerformance(
      label: 'vs City Titans',
      date: now.subtract(const Duration(days: 18)),
      battingPosition: 4,
      facedBalls: faced([
        (0, false, null, 6),
        (2, false, null, 7),
        (1, false, null, 12),
        (0, true, DismissalType.lbw, 13),
      ]),
      bowledBalls: bowled([(6, false, 18), (1, false, 18)]),
      respondedEarly: false,
      teamAvgRuns: 118,
      cityAvgRuns: 130,
    ),
    MatchPerformance(
      label: 'vs Strikers CC',
      date: now.subtract(const Duration(days: 26)),
      battingPosition: 3,
      facedBalls: faced([
        (4, false, null, 1),
        (4, false, null, 2),
        (1, false, null, 9),
        (2, false, null, 10),
        (4, false, null, 16),
        (6, false, null, 17),
        (2, false, null, 19),
      ]),
      bowledBalls: bowled([(0, false, 2), (0, false, 2), (2, false, 2)]),
      catches: 2,
      respondedEarly: true,
      teamAvgRuns: 168,
      cityAvgRuns: 130,
    ),
    MatchPerformance(
      label: 'vs Riverside Warriors',
      date: now.subtract(const Duration(days: 34)),
      battingPosition: 3,
      facedBalls: faced([
        (0, false, null, 0),
        (0, false, null, 1),
        (0, false, null, 2),
        (0, true, DismissalType.caught, 3),
      ]),
      bowledBalls: bowled([(4, false, 5), (6, false, 5)]),
      respondedEarly: true,
      teamAvgRuns: 101,
      cityAvgRuns: 130,
    ),
    MatchPerformance(
      label: 'vs Titans',
      date: now.subtract(const Duration(days: 45)),
      battingPosition: 4,
      facedBalls: faced([
        (1, false, null, 5),
        (4, false, null, 6),
        (0, false, null, 13),
        (1, false, null, 14),
        (0, true, DismissalType.stumped, 15),
      ]),
      bowledBalls: bowled([(1, false, 1), (0, false, 1)]),
      stumpings: 0,
      respondedEarly: false,
      teamAvgRuns: 133,
      cityAvgRuns: 130,
    ),
    MatchPerformance(
      label: 'vs City Titans',
      date: now.subtract(const Duration(days: 58)),
      battingPosition: 3,
      facedBalls: faced([
        (6, false, null, 2),
        (2, false, null, 3),
        (0, false, null, 11),
        (4, false, null, 12),
        (1, false, null, 18),
        (0, true, DismissalType.runOut, 19),
      ]),
      bowledBalls: bowled([(2, false, 6), (0, true, 6)]),
      catches: 1,
      respondedEarly: true,
      teamAvgRuns: 149,
      cityAvgRuns: 128,
    ),
    MatchPerformance(
      label: 'vs Strikers CC',
      date: now.subtract(const Duration(days: 72)),
      battingPosition: 3,
      facedBalls: faced([
        (0, false, null, 0),
        (1, false, null, 1),
        (0, false, null, 9),
        (0, true, DismissalType.bowled, 10),
      ]),
      bowledBalls: bowled([(4, false, 17), (4, false, 17)]),
      respondedEarly: true,
      teamAvgRuns: 112,
      cityAvgRuns: 128,
    ),
    MatchPerformance(
      label: 'vs Riverside Warriors',
      date: now.subtract(const Duration(days: 88)),
      battingPosition: 5,
      facedBalls: faced([
        (2, false, null, 15),
        (4, false, null, 16),
        (6, false, null, 17),
        (1, false, null, 18),
        (0, true, DismissalType.caught, 19),
      ]),
      bowledBalls: bowled([(0, false, 0), (1, false, 0)]),
      catches: 1,
      respondedEarly: false,
      teamAvgRuns: 160,
      cityAvgRuns: 128,
    ),
    MatchPerformance(
      label: 'vs Titans',
      date: now.subtract(const Duration(days: 110)),
      battingPosition: 3,
      facedBalls: faced([
        (4, false, null, 1),
        (1, false, null, 2),
        (4, false, null, 8),
        (2, false, null, 9),
        (0, false, null, 14),
        (1, false, null, 15),
        (6, false, null, 18),
        (2, false, null, 19),
      ]),
      bowledBalls: bowled([(3, false, 4), (2, false, 4)]),
      respondedEarly: true,
      teamAvgRuns: 172,
      cityAvgRuns: 128,
    ),
  ];
}

List<MatchPerformance> matchesInScope(
  List<MatchPerformance> all,
  AnalyticsTimeFilter filter,
  DateTime now,
) {
  if (all.isEmpty) return const [];
  return switch (filter) {
    AnalyticsTimeFilter.match => [all.first],
    AnalyticsTimeFilter.month =>
      all.where((m) => now.difference(m.date).inDays <= 30).toList(),
    AnalyticsTimeFilter.season =>
      all.where((m) => now.difference(m.date).inDays <= 120).toList(),
    AnalyticsTimeFilter.career => all,
  };
}

/// PRD: "lengths proxy via outcome mix" -- no real length-tracking exists
/// (flagged in player_analytics_models.dart); this derives a length
/// bucket purely from what the ball actually conceded.
DeliveryLengthProxy _lengthProxyFor(Delivery d) {
  if (d.isWicket || d.battingRuns == 0) return DeliveryLengthProxy.good;
  if (d.battingRuns >= 4) return DeliveryLengthProxy.full;
  return DeliveryLengthProxy.short;
}

PlayerAnalyticsSnapshot computeSnapshot(List<MatchPerformance> matches) {
  final battingPhaseSplits = <MatchPhase, PhaseSplitStat>{};
  final vsBowlerType = <BowlerType, PhaseSplitStat>{};
  final dismissalCounts = <DismissalType, int>{};
  final entryPoints = <int, EntryPointStat>{};
  final bowlingPhaseEconomy = <MatchPhase, BowlingPhaseStat>{};
  final lengthsProxyMix = <DeliveryLengthProxy, int>{};
  final vsBattingStyle = <BattingStyle, VsBattingStyleStat>{};
  var catches = 0;
  var runOuts = 0;
  var stumpings = 0;
  final formIndexSeries = <FormIndexPoint>[];
  var earlyRuns = 0;
  var earlyInnings = 0;
  var lateRuns = 0;
  var lateInnings = 0;

  for (final match in matches.reversed) {
    for (final fb in match.facedBalls) {
      final d = fb.delivery;
      if (!d.isLegal) continue;
      battingPhaseSplits[fb.phase] =
          (battingPhaseSplits[fb.phase] ?? const PhaseSplitStat()) +
          PhaseSplitStat(
            runs: d.battingRuns,
            balls: 1,
            dismissals: d.isWicket ? 1 : 0,
          );
      vsBowlerType[fb.bowlerType] =
          (vsBowlerType[fb.bowlerType] ?? const PhaseSplitStat()) +
          PhaseSplitStat(
            runs: d.battingRuns,
            balls: 1,
            dismissals: d.isWicket ? 1 : 0,
          );
      if (d.isWicket && d.dismissalType != null) {
        dismissalCounts[d.dismissalType!] =
            (dismissalCounts[d.dismissalType!] ?? 0) + 1;
      }
    }

    final existing = entryPoints[match.battingPosition];
    entryPoints[match.battingPosition] = EntryPointStat(
      battingPosition: match.battingPosition,
      runs: (existing?.runs ?? 0) + match.runsScored,
      innings: (existing?.innings ?? 0) + 1,
      dismissals: (existing?.dismissals ?? 0) + (match.wasDismissed ? 1 : 0),
    );

    for (final bb in match.bowledBalls) {
      final d = bb.delivery;
      if (!d.isLegal) continue;
      bowlingPhaseEconomy[bb.phase] =
          (bowlingPhaseEconomy[bb.phase] ?? const BowlingPhaseStat()) +
          BowlingPhaseStat(
            runsConceded: d.runs,
            legalBalls: 1,
            wickets: d.isWicket ? 1 : 0,
          );
      final proxy = _lengthProxyFor(d);
      lengthsProxyMix[proxy] = (lengthsProxyMix[proxy] ?? 0) + 1;
      final prior = vsBattingStyle[bb.strikerStyle];
      vsBattingStyle[bb.strikerStyle] = VsBattingStyleStat(
        runsConceded: (prior?.runsConceded ?? 0) + d.runs,
        legalBalls: (prior?.legalBalls ?? 0) + 1,
        wickets: (prior?.wickets ?? 0) + (d.isWicket ? 1 : 0),
      );
    }

    catches += match.catches;
    runOuts += match.runOuts;
    stumpings += match.stumpings;

    // PRD: "next best actions" / form index -- PRD/DS name no formula;
    // flagged heuristic (same convention as suggestedMvp): runs plus a
    // fixed weight per wicket.
    formIndexSeries.add(
      FormIndexPoint(
        matchLabel: match.label,
        index: (match.runsScored + match.wicketsTaken * 20).toDouble(),
      ),
    );

    if (match.respondedEarly) {
      earlyRuns += match.runsScored;
      earlyInnings++;
    } else {
      lateRuns += match.runsScored;
      lateInnings++;
    }
  }

  final gamesThisWeek = matches
      .where(
        (m) => m.date.isAfter(
          matches.first.date.subtract(const Duration(days: 7)),
        ),
      )
      .length;

  final entryList = entryPoints.values.toList()
    ..sort((a, b) => a.battingPosition.compareTo(b.battingPosition));
  final dismissalList = [
    for (final entry in dismissalCounts.entries)
      DismissalPatternEntry(type: entry.key, count: entry.value),
  ]..sort((a, b) => b.count.compareTo(a.count));

  final insights = <InsightItem>[];
  final recommendations = <RecommendationItem>[];

  if (entryList.length >= 2) {
    final best = entryList.reduce((a, b) => a.average > b.average ? a : b);
    final worst = entryList.reduce((a, b) => a.average < b.average ? a : b);
    if (best.battingPosition != worst.battingPosition) {
      insights.add(
        InsightItem(
          'You average ${best.average.toStringAsFixed(0)} at #${best.battingPosition} '
          'vs ${worst.average.toStringAsFixed(0)} at #${worst.battingPosition}.',
        ),
      );
      recommendations.add(
        RecommendationItem(
          'You average ${best.average.toStringAsFixed(0)} at #${best.battingPosition} '
          'vs ${worst.average.toStringAsFixed(0)} at #${worst.battingPosition} '
          '-- discuss role with captain.',
        ),
      );
    }
  }

  final paceStat = vsBowlerType[BowlerType.pace];
  final spinStat = vsBowlerType[BowlerType.spin];
  if (paceStat != null && spinStat != null) {
    final weaker = paceStat.strikeRate < spinStat.strikeRate ? 'pace' : 'spin';
    insights.add(
      InsightItem(
        'Strike rate ${paceStat.strikeRate.toStringAsFixed(0)} vs pace, '
        '${spinStat.strikeRate.toStringAsFixed(0)} vs spin.',
      ),
    );
    recommendations.add(
      RecommendationItem('Extra $weaker-bowling practice could lift your SR.'),
    );
  }

  if (dismissalList.isNotEmpty) {
    insights.add(
      InsightItem(
        'Most common dismissal: ${dismissalList.first.label} '
        '(${dismissalList.first.count} times).',
      ),
    );
  }

  return PlayerAnalyticsSnapshot(
    battingPhaseSplits: battingPhaseSplits,
    dismissalPatterns: dismissalList,
    vsBowlerType: vsBowlerType,
    entryPointStats: entryList,
    bowlingPhaseEconomy: bowlingPhaseEconomy,
    lengthsProxyMix: lengthsProxyMix,
    vsBattingStyle: vsBattingStyle,
    fielding: FieldingContribution(
      catches: catches,
      runOuts: runOuts,
      stumpings: stumpings,
    ),
    formIndexSeries: formIndexSeries,
    fatigue: FatigueSignal(gamesThisWeek: gamesThisWeek),
    availabilityCorrelation: AvailabilityPerformanceCorrelation(
      avgRunsWhenRespondedEarly: earlyInnings == 0
          ? 0
          : earlyRuns / earlyInnings,
      avgRunsWhenRespondedLate: lateInnings == 0 ? 0 : lateRuns / lateInnings,
    ),
    insights: insights,
    recommendations: recommendations,
  );
}
