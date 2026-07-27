import 'custom_stats_explorer_models.dart';
import 'player_analytics_data.dart' show MatchPerformance;

/// PRD §14's "minimum-activity qualifications stop one-match wonders
/// topping averages" grounds the qualification stepper's purpose; the
/// exact per-row threshold and "small-sample" wording are this story's
/// own reasonable reading, flagged in custom_stats_explorer_models.dart.
List<StatsExplorerRow> runQuery(
  List<MatchPerformance> matches,
  StatsDiscipline discipline,
  StatsQueryFilters filters,
) {
  final rows = <StatsExplorerRow>[];
  for (final match in matches) {
    switch (discipline) {
      case StatsDiscipline.batting:
        final balls = match.facedBalls.where((fb) {
          if (!fb.delivery.isLegal) return false;
          if (filters.phase != null && fb.phase != filters.phase) return false;
          if (filters.bowlerType != null &&
              fb.bowlerType != filters.bowlerType) {
            return false;
          }
          return true;
        }).toList();
        if (balls.isEmpty) continue;
        final runs = balls.fold(0, (a, b) => a + b.delivery.battingRuns);
        rows.add(
          StatsExplorerRow(
            matchLabel: match.label,
            date: match.date,
            primaryValue: runs,
            secondaryValue: 100 * runs / balls.length,
            sampleSize: balls.length,
          ),
        );
      case StatsDiscipline.bowling:
        final balls = match.bowledBalls.where((bb) {
          if (!bb.delivery.isLegal) return false;
          if (filters.phase != null && bb.phase != filters.phase) return false;
          if (filters.battingStyle != null &&
              bb.strikerStyle != filters.battingStyle) {
            return false;
          }
          return true;
        }).toList();
        if (balls.isEmpty) continue;
        final runsConceded = balls.fold(0, (a, b) => a + b.delivery.runs);
        final wickets = balls.where((b) => b.delivery.isWicket).length;
        rows.add(
          StatsExplorerRow(
            matchLabel: match.label,
            date: match.date,
            primaryValue: wickets,
            secondaryValue: 6 * runsConceded / balls.length,
            sampleSize: balls.length,
          ),
        );
      case StatsDiscipline.fielding:
        final contributions = match.catches + match.runOuts + match.stumpings;
        if (contributions == 0) continue;
        rows.add(
          StatsExplorerRow(
            matchLabel: match.label,
            date: match.date,
            primaryValue: contributions,
            secondaryValue: contributions.toDouble(),
            sampleSize: 1,
          ),
        );
    }
  }

  final qualified = rows
      .where((r) => r.sampleSize >= filters.minSample)
      .toList();
  qualified.sort((a, b) => b.date.compareTo(a.date));
  return qualified;
}

int totalSampleSize(List<StatsExplorerRow> rows) =>
    rows.fold(0, (a, r) => a + r.sampleSize);

/// No PRD/DS threshold exists for "small sample" -- flagged judgment
/// call: fewer than 3 qualifying innings/overs is the same minimum this
/// session already uses elsewhere (season_summary_models.dart's
/// seasonSummaryMinMatches).
const int smallSampleThreshold = 3;
