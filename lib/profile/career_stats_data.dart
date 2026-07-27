import '../analytics/player_analytics_data.dart'
    show BowledBall, MatchPerformance;
import '../analytics/player_analytics_models.dart' show BowlerType;
import '../design_system/components/charts/app_pie_chart.dart' show AppPieSlice;
import '../design_system/components/charts/app_scatter_chart.dart'
    show AppScatterPoint;
import '../design_system/tokens/app_colors.dart';
import '../matches/scoring_models.dart' show WagonSector, dismissalTypeLabels;
import '../teams/team_models.dart' show TeamFormat;
import 'career_stats_models.dart';

List<MatchPerformance> _scope(
  List<MatchPerformance> matches,
  TeamFormat? format,
  StatVerifiedFilter verifiedFilter,
) {
  return matches.where((m) {
    if (format != null && m.format != format) return false;
    if (m.isPreApp) return false; // PRD: "excluded from rankings"
    return verifiedFilter == StatVerifiedFilter.verified
        ? m.verified
        : !m.verified;
  }).toList();
}

BattingCareerRow batting(List<MatchPerformance> matches) {
  var innings = 0;
  var runs = 0;
  var highScore = 0;
  var highScoreNotOut = false;
  var dismissals = 0;
  var balls = 0;
  var fifties = 0;
  var hundreds = 0;
  var fours = 0;
  var sixes = 0;
  var ducks = 0;
  var notOuts = 0;

  for (final m in matches) {
    if (m.facedBalls.isEmpty) continue;
    innings++;
    final matchRuns = m.runsScored;
    final matchBalls = m.facedBalls.where((b) => b.delivery.isLegal).length;
    final out = m.wasDismissed;
    runs += matchRuns;
    balls += matchBalls;
    if (matchRuns >= highScore) {
      highScore = matchRuns;
      highScoreNotOut = !out;
    }
    if (out) {
      dismissals++;
    } else {
      notOuts++;
    }
    if (matchRuns == 0 && out) ducks++;
    if (matchRuns >= 100) {
      hundreds++;
    } else if (matchRuns >= 50) {
      fifties++;
    }
    for (final fb in m.facedBalls) {
      if (fb.delivery.battingRuns == 4) fours++;
      if (fb.delivery.battingRuns == 6) sixes++;
    }
  }

  return BattingCareerRow(
    matches: matches.length,
    innings: innings,
    runs: runs,
    highestScore: highScore,
    highestScoreNotOut: highScoreNotOut,
    dismissals: dismissals,
    balls: balls,
    fifties: fifties,
    hundreds: hundreds,
    fours: fours,
    sixes: sixes,
    ducks: ducks,
    notOuts: notOuts,
  );
}

/// Bowled balls are already in the order they were bowled within a
/// match (player_analytics_data.dart's own doc comment) -- grouping
/// them into consecutive sixes reconstructs real overs rather than
/// fabricating a maiden count from nothing.
int _maidensIn(List<BowledBall> bowledBalls) {
  final legal = bowledBalls.where((b) => b.delivery.isLegal).toList();
  var maidens = 0;
  for (var i = 0; i + 6 <= legal.length; i += 6) {
    final over = legal.sublist(i, i + 6);
    if (over.every((b) => b.delivery.runs == 0 && !b.delivery.isWicket)) {
      maidens++;
    }
  }
  return maidens;
}

BowlingCareerRow bowling(List<MatchPerformance> matches) {
  var legalBalls = 0;
  var wickets = 0;
  var runsConceded = 0;
  var threeWicketHauls = 0;
  var fiveWicketHauls = 0;
  var dotBalls = 0;
  var maidens = 0;
  String bestFigures = '-';
  var bestWickets = -1;
  var bestRuns = 1 << 30;

  for (final m in matches) {
    if (m.bowledBalls.isEmpty) continue;
    final legal = m.bowledBalls.where((b) => b.delivery.isLegal).toList();
    final matchWickets = legal.where((b) => b.delivery.isWicket).length;
    final matchRuns = legal.fold(0, (a, b) => a + b.delivery.runs);
    legalBalls += legal.length;
    wickets += matchWickets;
    runsConceded += matchRuns;
    dotBalls += legal
        .where((b) => b.delivery.runs == 0 && !b.delivery.isWicket)
        .length;
    maidens += _maidensIn(m.bowledBalls);
    if (matchWickets >= 5) fiveWicketHauls++;
    if (matchWickets >= 3) threeWicketHauls++;
    if (matchWickets > bestWickets ||
        (matchWickets == bestWickets && matchRuns < bestRuns)) {
      bestWickets = matchWickets;
      bestRuns = matchRuns;
      bestFigures = '$matchWickets/$matchRuns';
    }
  }

  return BowlingCareerRow(
    matches: matches.where((m) => m.bowledBalls.isNotEmpty).length,
    legalBalls: legalBalls,
    wickets: wickets,
    runsConceded: runsConceded,
    bestFigures: bestFigures,
    threeWicketHauls: threeWicketHauls,
    fiveWicketHauls: fiveWicketHauls,
    dotBalls: dotBalls,
    maidens: maidens,
  );
}

FieldingCareerRow fielding(List<MatchPerformance> matches) {
  return FieldingCareerRow(
    catches: matches.fold(0, (a, m) => a + m.catches),
    runOuts: matches.fold(0, (a, m) => a + m.runOuts),
    stumpings: matches.fold(0, (a, m) => a + m.stumpings),
  );
}

CareerStatsSnapshot computeCareerStats(
  List<MatchPerformance> allMatches, {
  TeamFormat? format,
  StatVerifiedFilter verifiedFilter = StatVerifiedFilter.verified,
}) {
  final scoped = _scope(allMatches, format, verifiedFilter);
  return CareerStatsSnapshot(
    batting: batting(scoped),
    bowling: bowling(scoped),
    fielding: fielding(scoped),
  );
}

List<StatSourceEntry> battingSourceList(List<MatchPerformance> allMatches) {
  return [
    for (final m in allMatches.where((m) => m.facedBalls.isNotEmpty))
      StatSourceEntry(
        matchLabel: m.label,
        detail:
            '${m.runsScored}${m.wasDismissed ? '' : '*'} '
            '(${m.facedBalls.where((b) => b.delivery.isLegal).length}b)'
            '${m.verified ? '' : ' -- unverified'}',
        isPreApp: m.isPreApp,
      ),
  ];
}

List<StatSourceEntry> bowlingSourceList(List<MatchPerformance> allMatches) {
  return [
    for (final m in allMatches.where((m) => m.bowledBalls.isNotEmpty))
      StatSourceEntry(
        matchLabel: m.label,
        detail:
            '${m.wicketsTaken}/'
            '${m.bowledBalls.where((b) => b.delivery.isLegal).fold(0, (a, b) => a + b.delivery.runs)}'
            '${m.verified ? '' : ' -- unverified'}',
        isPreApp: m.isPreApp,
      ),
  ];
}

/// PRD §5.7: "Runs/wickets by match (last 10/season/career)."
List<(int runs, int wickets)> runsWicketsByMatch(
  List<MatchPerformance> matches,
) {
  final ordered = matches.reversed.toList();
  return [for (final m in ordered) (m.runsScored, m.wicketsTaken)];
}

/// PRD §5.7: "form curve." No PRD/DS formula named -- flagged as the
/// per-match runs trend, the most literal reading of "form."
List<double> formCurve(List<MatchPerformance> matches) {
  final ordered = matches.reversed.toList();
  return [for (final m in ordered) m.runsScored.toDouble()];
}

/// PRD §5.7: "SR vs Avg scatter per bowling type faced." One point per
/// [BowlerType] -- reuses the same aggregation E13-02 already built for
/// vs-pace/spin analytics rather than a third parallel one.
List<AppScatterPoint> srAvgScatterByBowlerType(List<MatchPerformance> matches) {
  final points = <AppScatterPoint>[];
  for (final type in BowlerType.values) {
    final balls = [
      for (final m in matches)
        for (final fb in m.facedBalls)
          if (fb.bowlerType == type && fb.delivery.isLegal) fb,
    ];
    if (balls.isEmpty) continue;
    final runs = balls.fold(0, (a, b) => a + b.delivery.battingRuns);
    final dismissals = balls.where((b) => b.delivery.isWicket).length;
    final sr = 100 * runs / balls.length;
    final avg = dismissals == 0 ? runs.toDouble() : runs / dismissals;
    points.add(
      AppScatterPoint(
        x: sr,
        y: avg,
        label: type == BowlerType.pace ? 'Pace' : 'Spin',
      ),
    );
  }
  return points;
}

/// PRD §5.7: "dismissal-type pie."
List<AppPieSlice> dismissalPie(
  List<MatchPerformance> matches,
  AppColors colors,
) {
  final counts = <String, int>{};
  for (final m in matches) {
    for (final fb in m.facedBalls) {
      final type = fb.delivery.dismissalType;
      if (type == null) continue;
      final label = dismissalTypeLabels[type]!;
      counts[label] = (counts[label] ?? 0) + 1;
    }
  }
  final palette = colors.chartCategorical;
  final entries = counts.entries.toList();
  return [
    for (final (i, entry) in entries.indexed)
      AppPieSlice(
        label: entry.key,
        value: entry.value.toDouble(),
        color: palette[i % palette.length],
      ),
  ];
}

/// PRD §5.7: "scoring-zone wagon aggregate." No wagon-sector logging
/// exists in this mock career dataset (player_analytics_data.dart's
/// MatchPerformance never captured shot direction) -- flagged
/// approximation: each boundary is assigned a sector deterministically
/// by its running index so the chart has something real (genuine
/// boundary counts) to distribute, rather than fabricating shot
/// directions outright.
Map<WagonSector, int> approximateWagonAggregate(
  List<MatchPerformance> matches,
) {
  final result = <WagonSector, int>{};
  var index = 0;
  for (final m in matches) {
    for (final fb in m.facedBalls) {
      final runs = fb.delivery.battingRuns;
      if (runs != 4 && runs != 6) continue;
      final sector = WagonSector.values[index % WagonSector.values.length];
      result[sector] = (result[sector] ?? 0) + 1;
      index++;
    }
  }
  return result;
}
