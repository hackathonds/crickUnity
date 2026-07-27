import 'player_analytics_models.dart' show InsightItem, RecommendationItem;
import 'team_captain_analytics_models.dart';

enum MatchResult { win, loss, draw }

/// One synthetic match's team-level facts. Same flagged-mock convention
/// as player_analytics_data.dart's MatchPerformance -- no persisted
/// cross-match history store exists in the app (E4's InningsState only
/// ever holds one current innings), and no bowling-change/lineup/toss
/// history is recorded anywhere either, so this is a deterministic
/// synthetic ~12-match team season.
class TeamMatchRecord {
  final String label;
  final DateTime date;
  final String ground;
  final bool wonToss;
  final TossDecision decision;
  final MatchResult result;
  final bool battedFirst;
  final int marginRuns;
  final int marginWickets;
  final int lineupChangesFromPrevious;
  final bool hadCollapse;
  final int squadRespondedOnTime;
  final int squadTotal;
  final bool hadCaptainBowlingChange;
  final double economyBeforeChange;
  final double economyAfterChange;

  const TeamMatchRecord({
    required this.label,
    required this.date,
    required this.ground,
    required this.wonToss,
    required this.decision,
    required this.result,
    required this.battedFirst,
    this.marginRuns = 0,
    this.marginWickets = 0,
    this.lineupChangesFromPrevious = 0,
    this.hadCollapse = false,
    required this.squadRespondedOnTime,
    required this.squadTotal,
    this.hadCaptainBowlingChange = false,
    this.economyBeforeChange = 0,
    this.economyAfterChange = 0,
  });

  String get marginLabel {
    if (result == MatchResult.draw) return 'Draw';
    if (marginWickets > 0) return 'By $marginWickets wkt(s)';
    if (marginRuns < 10) return 'By <10 runs';
    if (marginRuns < 30) return 'By 10-30 runs';
    return 'By 30+ runs';
  }
}

List<TeamMatchRecord> mockTeamSeason(DateTime now) => [
  TeamMatchRecord(
    label: 'vs Titans',
    date: now.subtract(const Duration(days: 3)),
    ground: 'Green Valley Ground',
    wonToss: true,
    decision: TossDecision.bowlFirst,
    result: MatchResult.win,
    battedFirst: false,
    marginWickets: 4,
    lineupChangesFromPrevious: 0,
    squadRespondedOnTime: 10,
    squadTotal: 11,
    hadCaptainBowlingChange: true,
    economyBeforeChange: 9.2,
    economyAfterChange: 6.4,
  ),
  TeamMatchRecord(
    label: 'vs Riverside Warriors',
    date: now.subtract(const Duration(days: 10)),
    ground: 'Riverside Turf',
    wonToss: false,
    decision: TossDecision.batFirst,
    result: MatchResult.win,
    battedFirst: true,
    marginRuns: 42,
    lineupChangesFromPrevious: 1,
    squadRespondedOnTime: 11,
    squadTotal: 11,
  ),
  TeamMatchRecord(
    label: 'vs City Titans',
    date: now.subtract(const Duration(days: 18)),
    ground: 'Green Valley Ground',
    wonToss: true,
    decision: TossDecision.batFirst,
    result: MatchResult.loss,
    battedFirst: true,
    marginRuns: 18,
    lineupChangesFromPrevious: 3,
    hadCollapse: true,
    squadRespondedOnTime: 7,
    squadTotal: 11,
  ),
  TeamMatchRecord(
    label: 'vs Strikers CC',
    date: now.subtract(const Duration(days: 26)),
    ground: 'Central Oval',
    wonToss: true,
    decision: TossDecision.bowlFirst,
    result: MatchResult.win,
    battedFirst: false,
    marginWickets: 6,
    lineupChangesFromPrevious: 0,
    squadRespondedOnTime: 11,
    squadTotal: 11,
    hadCaptainBowlingChange: true,
    economyBeforeChange: 8.0,
    economyAfterChange: 5.5,
  ),
  TeamMatchRecord(
    label: 'vs Riverside Warriors',
    date: now.subtract(const Duration(days: 34)),
    ground: 'Riverside Turf',
    wonToss: false,
    decision: TossDecision.bowlFirst,
    result: MatchResult.loss,
    battedFirst: false,
    marginRuns: 55,
    lineupChangesFromPrevious: 2,
    squadRespondedOnTime: 8,
    squadTotal: 11,
  ),
  TeamMatchRecord(
    label: 'vs Titans',
    date: now.subtract(const Duration(days: 45)),
    ground: 'Green Valley Ground',
    wonToss: true,
    decision: TossDecision.batFirst,
    result: MatchResult.draw,
    battedFirst: true,
    lineupChangesFromPrevious: 1,
    squadRespondedOnTime: 9,
    squadTotal: 11,
  ),
  TeamMatchRecord(
    label: 'vs City Titans',
    date: now.subtract(const Duration(days: 58)),
    ground: 'Central Oval',
    wonToss: false,
    decision: TossDecision.bowlFirst,
    result: MatchResult.win,
    battedFirst: false,
    marginWickets: 3,
    lineupChangesFromPrevious: 0,
    squadRespondedOnTime: 11,
    squadTotal: 11,
    hadCaptainBowlingChange: true,
    economyBeforeChange: 7.6,
    economyAfterChange: 7.1,
  ),
  TeamMatchRecord(
    label: 'vs Strikers CC',
    date: now.subtract(const Duration(days: 72)),
    ground: 'Central Oval',
    wonToss: true,
    decision: TossDecision.batFirst,
    result: MatchResult.loss,
    battedFirst: true,
    marginRuns: 8,
    lineupChangesFromPrevious: 4,
    hadCollapse: true,
    squadRespondedOnTime: 6,
    squadTotal: 11,
  ),
  TeamMatchRecord(
    label: 'vs Riverside Warriors',
    date: now.subtract(const Duration(days: 88)),
    ground: 'Riverside Turf',
    wonToss: true,
    decision: TossDecision.bowlFirst,
    result: MatchResult.win,
    battedFirst: false,
    marginWickets: 5,
    lineupChangesFromPrevious: 1,
    squadRespondedOnTime: 10,
    squadTotal: 11,
    hadCaptainBowlingChange: true,
    economyBeforeChange: 9.8,
    economyAfterChange: 6.9,
  ),
  TeamMatchRecord(
    label: 'vs Titans',
    date: now.subtract(const Duration(days: 110)),
    ground: 'Green Valley Ground',
    wonToss: false,
    decision: TossDecision.batFirst,
    result: MatchResult.win,
    battedFirst: true,
    marginRuns: 61,
    lineupChangesFromPrevious: 0,
    squadRespondedOnTime: 11,
    squadTotal: 11,
  ),
  TeamMatchRecord(
    label: 'vs City Titans',
    date: now.subtract(const Duration(days: 125)),
    ground: 'Central Oval',
    wonToss: true,
    decision: TossDecision.batFirst,
    result: MatchResult.win,
    battedFirst: true,
    marginRuns: 15,
    lineupChangesFromPrevious: 2,
    squadRespondedOnTime: 9,
    squadTotal: 11,
  ),
  TeamMatchRecord(
    label: 'vs Strikers CC',
    date: now.subtract(const Duration(days: 140)),
    ground: 'Central Oval',
    wonToss: false,
    decision: TossDecision.bowlFirst,
    result: MatchResult.loss,
    battedFirst: false,
    marginRuns: 24,
    lineupChangesFromPrevious: 3,
    squadRespondedOnTime: 7,
    squadTotal: 11,
  ),
];

String _clusterLabel(int changes) {
  if (changes == 0) return 'Same XI';
  if (changes <= 2) return '1-2 changes';
  return '3+ changes';
}

CaptainAnalyticsSnapshot computeCaptainSnapshot(List<TeamMatchRecord> matches) {
  final tossOutcomes = <TossDecision, TossOutcomeStat>{};
  for (final m in matches.where((m) => m.wonToss)) {
    final prior = tossOutcomes[m.decision] ?? const TossOutcomeStat();
    tossOutcomes[m.decision] = TossOutcomeStat(
      wins: prior.wins + (m.result == MatchResult.win ? 1 : 0),
      total: prior.total + 1,
    );
  }

  final changes = matches.where((m) => m.hadCaptainBowlingChange).toList();
  final bowlingChangeImpact = changes.isEmpty
      ? null
      : BowlingChangeImpact(
          avgEconomyBefore:
              changes.fold(0.0, (a, m) => a + m.economyBeforeChange) /
              changes.length,
          avgEconomyAfter:
              changes.fold(0.0, (a, m) => a + m.economyAfterChange) /
              changes.length,
        );

  final unchangedCount = matches
      .where((m) => m.lineupChangesFromPrevious == 0)
      .length;
  final selectionStability = SelectionStability(
    percentUnchanged: matches.isEmpty
        ? 0
        : 100 * unchangedCount / matches.length,
  );

  final clusters = <String, LineupClusterStat>{};
  for (final m in matches) {
    final label = _clusterLabel(m.lineupChangesFromPrevious);
    final prior = clusters[label] ?? LineupClusterStat(label: label);
    clusters[label] = LineupClusterStat(
      label: label,
      wins: prior.wins + (m.result == MatchResult.win ? 1 : 0),
      total: prior.total + 1,
    );
  }

  final availabilityHealth = AvailabilityResponseHealth(
    respondedOnTime: matches.fold(0, (a, m) => a + m.squadRespondedOnTime),
    totalAsked: matches.fold(0, (a, m) => a + m.squadTotal),
  );

  final insights = <InsightItem>[];
  final recommendations = <RecommendationItem>[];

  final chase = tossOutcomes[TossDecision.bowlFirst];
  final batFirst = tossOutcomes[TossDecision.batFirst];
  if (chase != null && chase.total >= 2) {
    insights.add(
      InsightItem(
        'Teams you chase against: ${chase.winPercent.toStringAsFixed(0)}% wins '
        '(${chase.wins}/${chase.total} tosses won bowling first).',
      ),
    );
    if (batFirst == null || chase.winPercent > batFirst.winPercent) {
      recommendations.add(
        RecommendationItem(
          'Teams you chase against: ${chase.winPercent.toStringAsFixed(0)}% '
          'wins -- consider bowling first.',
        ),
      );
    }
  }
  if (bowlingChangeImpact != null && bowlingChangeImpact.delta > 0) {
    insights.add(
      InsightItem(
        'Your bowling changes cut economy by '
        '${bowlingChangeImpact.delta.toStringAsFixed(1)} runs/over on average.',
      ),
    );
  }
  final bestCluster = clusters.values.isEmpty
      ? null
      : clusters.values.reduce((a, b) => a.winPercent > b.winPercent ? a : b);
  if (bestCluster != null && bestCluster.total >= 2) {
    recommendations.add(
      RecommendationItem(
        '"${bestCluster.label}" lineups win '
        '${bestCluster.winPercent.toStringAsFixed(0)}% -- favor squad continuity.',
      ),
    );
  }

  return CaptainAnalyticsSnapshot(
    tossOutcomes: tossOutcomes,
    bowlingChangeImpact: bowlingChangeImpact,
    selectionStability: selectionStability,
    lineupClusters: clusters.values.toList(),
    availabilityHealth: availabilityHealth,
    insights: insights,
    recommendations: recommendations,
  );
}

TeamAnalyticsSnapshot computeTeamSnapshot(
  List<TeamMatchRecord> matches,
  int chemistryTrendPercent,
) {
  final wins = matches.where((m) => m.result == MatchResult.win).length;
  final losses = matches.where((m) => m.result == MatchResult.loss).length;
  final draws = matches.where((m) => m.result == MatchResult.draw).length;

  double winPercentFor(bool battedFirst) {
    final subset = matches.where((m) => m.battedFirst == battedFirst).toList();
    if (subset.isEmpty) return 0;
    final w = subset.where((m) => m.result == MatchResult.win).length;
    return 100 * w / subset.length;
  }

  final buckets = <String, int>{};
  for (final m in matches) {
    buckets[m.marginLabel] = (buckets[m.marginLabel] ?? 0) + 1;
  }
  final marginDistribution = [
    for (final entry in buckets.entries)
      MarginBucketStat(label: entry.key, count: entry.value),
  ];

  final collapseCount = matches.where((m) => m.hadCollapse).length;
  final collapseFrequency = CollapseFrequency(
    matchesWithCollapse: collapseCount,
    totalMatches: matches.length,
  );

  final grounds = <String, GroundRecordStat>{};
  for (final m in matches) {
    final prior = grounds[m.ground] ?? GroundRecordStat(groundName: m.ground);
    grounds[m.ground] = GroundRecordStat(
      groundName: m.ground,
      wins: prior.wins + (m.result == MatchResult.win ? 1 : 0),
      losses: prior.losses + (m.result == MatchResult.loss ? 1 : 0),
      draws: prior.draws + (m.result == MatchResult.draw ? 1 : 0),
    );
  }

  final insights = <InsightItem>[];
  final recommendations = <RecommendationItem>[];

  final battingFirstPct = winPercentFor(true);
  final chasingPct = winPercentFor(false);
  insights.add(
    InsightItem(
      'Win % batting first: ${battingFirstPct.toStringAsFixed(0)}%, '
      'chasing: ${chasingPct.toStringAsFixed(0)}%.',
    ),
  );
  if (collapseFrequency.percent >= 25) {
    recommendations.add(
      RecommendationItem(
        'Collapses in ${collapseFrequency.percent.toStringAsFixed(0)}% of '
        'matches -- work middle-order partnership drills.',
      ),
    );
  }
  final bestGround = grounds.values.isEmpty
      ? null
      : grounds.values.reduce(
          (a, b) =>
              a.wins / (a.played == 0 ? 1 : a.played) >
                  b.wins / (b.played == 0 ? 1 : b.played)
              ? a
              : b,
        );
  if (bestGround != null && bestGround.played >= 2) {
    insights.add(
      InsightItem(
        'Best ground record: ${bestGround.groundName} '
        '(${bestGround.wins}W-${bestGround.losses}L-${bestGround.draws}D).',
      ),
    );
  }

  return TeamAnalyticsSnapshot(
    wins: wins,
    losses: losses,
    draws: draws,
    winPercentBattingFirst: battingFirstPct,
    winPercentChasing: chasingPct,
    topRunScorer: 'Rohan Verma',
    topWicketTaker: 'Priya Nair',
    marginDistribution: marginDistribution,
    collapseFrequency: collapseFrequency,
    groundRecords: grounds.values.toList(),
    chemistryTrendPercent: chemistryTrendPercent,
    insights: insights,
    recommendations: recommendations,
  );
}
