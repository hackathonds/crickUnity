import 'scoring_models.dart';

/// No real profile/DOB/guardian data model exists yet -- a mock
/// stand-in set, same convention as every other mock roster/lineup in
/// this module (e.g. [mockBattingOrder]), just enough to exercise the
/// PRD §7.19 minor-visibility rule.
const Set<String> mockMinorPlayers = {'Kunal Mehta', 'Aditya Kumar'};

bool isMinorPlayer(String name) => mockMinorPlayers.contains(name);

class InsightNote {
  final String text;

  const InsightNote(this.text);
}

List<MapEntry<int, List<int>>> _groupIndicesByOver(List<Delivery> deliveries) {
  final groups = <int, List<int>>{};
  var legalCount = 0;
  for (var i = 0; i < deliveries.length; i++) {
    groups.putIfAbsent(legalCount ~/ 6, () => []).add(i);
    if (deliveries[i].isLegal) legalCount++;
  }
  return groups.entries.toList();
}

/// PRD §7.19 team-level takeaways. Both example lines in the PRD text
/// are literal heuristics implemented below; when neither condition is
/// met, a calm fallback note is returned so the section is never empty.
List<InsightNote> teamInsights(InningsState state) {
  final notes = <InsightNote>[];
  final overGroups = _groupIndicesByOver(state.deliveries);

  // "Middle overs (7-14) cost you: 4 wickets for 31" -- 1-indexed overs
  // 7-14 is 0-indexed over 6..13.
  var middleWickets = 0;
  var middleRuns = 0;
  for (final group in overGroups) {
    if (group.key < 6 || group.key > 13) continue;
    for (final i in group.value) {
      middleRuns += state.deliveries[i].runs;
      if (state.deliveries[i].isWicket) middleWickets++;
    }
  }
  if (middleWickets >= 3) {
    notes.add(
      InsightNote(
        'Middle overs (7-14) cost you: $middleWickets wickets for $middleRuns',
      ),
    );
  }

  // "Bowling change at over 12 swung momentum" -- a bowler only ever
  // changes at an over boundary in this model, so comparing runs
  // conceded in the over immediately before vs. after a bowler change
  // is a faithful reading of "swung momentum."
  String? previousBowler;
  var previousRuns = 0;
  var biggestDrop = 0;
  int? biggestDropOverIndex;
  int? biggestDropBefore;
  int? biggestDropAfter;
  for (final group in overGroups) {
    if (group.value.isEmpty) continue;
    final bowler = state.deliveries[group.value.first].bowlerName;
    final runsThisOver = group.value.fold(
      0,
      (sum, i) => sum + state.deliveries[i].runs,
    );
    if (previousBowler != null && bowler != previousBowler) {
      final drop = previousRuns - runsThisOver;
      if (drop > biggestDrop) {
        biggestDrop = drop;
        biggestDropOverIndex = group.key;
        biggestDropBefore = previousRuns;
        biggestDropAfter = runsThisOver;
      }
    }
    previousBowler = bowler;
    previousRuns = runsThisOver;
  }
  if (biggestDropOverIndex != null && biggestDrop >= 6) {
    notes.add(
      InsightNote(
        'Bowling change at over ${biggestDropOverIndex + 1} swung '
        'momentum: $biggestDropBefore -> $biggestDropAfter runs an over',
      ),
    );
  }

  if (notes.isEmpty) {
    notes.add(const InsightNote('A steady innings with few big swings.'));
  }
  return notes;
}

/// PRD §7.19: "per-player notes ('First time crossing 40 vs leather')."
/// "First time" implies real historical data this app doesn't have yet
/// -- the milestone note below is a mock stand-in, flagged as such,
/// same convention as every other missing-backend mock this session.
List<InsightNote> playerInsights(InningsState state, String playerName) {
  final batting = state.batters[playerName];
  final bowling = state.bowlers[playerName];
  if (batting == null && bowling == null) {
    return const [InsightNote("Didn't feature this innings.")];
  }
  final notes = <InsightNote>[];
  if (batting != null) {
    notes.add(InsightNote('${batting.runs} runs off ${batting.balls} balls'));
    if (batting.runs >= 40) {
      notes.add(
        InsightNote(
          '${batting.runs} is a strong innings-total -- keep building on it',
        ),
      );
    }
  }
  if (bowling != null && bowling.ballsBowled > 0) {
    notes.add(
      InsightNote(
        '${bowling.completedOvers}.${bowling.ballsThisOver}-'
        '${bowling.runsConceded}-${bowling.wickets}',
      ),
    );
  }
  return notes;
}
