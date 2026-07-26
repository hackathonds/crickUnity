import 'match_models.dart' show ExtraSubRules;

/// PRD §7.7 (Live Scoring / Scorer Console) / DS §7 screen 27. E4-04's
/// XL split ("pad / extras / bowler-select / strike-swap" per the
/// backlog): all 4 sub-tasks are layered in here -- the core
/// ball-by-ball engine, run buttons, wicket + dismissal sheet, undo (1);
/// extras (2); next-bowler rotation/enforcement (3); strike rotation on
/// odd runs/over-end + manual swap (4).
/// No Selection Board (E3-08) integration exists between match
/// creation and an actual XI, so the batting/bowling lineups are mock.
enum DismissalType { bowled, caught, lbw, runOut, stumped, hitWicket }

/// PRD §7.7: "extras (Wd/Nb/B/Lb with run steppers)."
enum ExtraType { wide, noBall, bye, legBye }

const Map<ExtraType, String> extraTypeShortLabels = {
  ExtraType.wide: 'Wd',
  ExtraType.noBall: 'Nb',
  ExtraType.bye: 'B',
  ExtraType.legBye: 'Lb',
};

const Map<ExtraType, String> extraTypeLabels = {
  ExtraType.wide: 'Wide',
  ExtraType.noBall: 'No-ball',
  ExtraType.bye: 'Bye',
  ExtraType.legBye: 'Leg bye',
};

const Map<DismissalType, String> dismissalTypeLabels = {
  DismissalType.bowled: 'Bowled',
  DismissalType.caught: 'Caught',
  DismissalType.lbw: 'LBW',
  DismissalType.runOut: 'Run out',
  DismissalType.stumped: 'Stumped',
  DismissalType.hitWicket: 'Hit wicket',
};

/// One recorded ball, replayed in order to derive [InningsState] --
/// undo is just "drop the last delivery and replay," which is correct
/// by construction rather than needing hand-written reverse-diff logic.
///
/// [runs] is always the *total* added to the team score. [battingRuns]
/// is the subset of that credited to the striker personally -- real
/// cricket scoring rules: wides and byes/leg-byes are never credited to
/// the batter even though the team score moves; a no-ball's fixed
/// penalty run isn't credited to the batter either, but any further
/// runs actually run/hit off a no-ball are. [ranRuns] is the subset the
/// batters physically ran between the wickets -- what strike rotation
/// keys off -- distinct from both of the above: a wide/no-ball's fixed
/// penalty run is awarded automatically and involves no running, but
/// any additional runs off either do; byes/leg-byes are entirely run.
/// [isLegal] says whether this ball counts toward the 6-ball over --
/// wides never count; no-balls count only if the match's sub-rules turn
/// rebowl off. [isManualSwap] marks the scorer's own swap-strike
/// control -- a zero-effect marker that only flips strike, contributing
/// no runs/balls/overs to anything.
///
/// [dismissedBatterName] (E4-05, "run-out sub-fields"): every other
/// dismissal type can only ever dismiss whoever's on strike, but a
/// run-out can dismiss either end -- null defaults to the striker.
class Delivery {
  final String bowlerName;
  final int runs;
  final int battingRuns;
  final int ranRuns;
  final bool isWicket;
  final DismissalType? dismissalType;
  final String? fielderName;
  final String? dismissedBatterName;
  final String? newBatterName;
  final ExtraType? extraType;
  final bool isLegal;
  final bool isManualSwap;

  const Delivery({
    required this.bowlerName,
    required this.runs,
    int? battingRuns,
    int? ranRuns,
    this.isWicket = false,
    this.dismissalType,
    this.fielderName,
    this.dismissedBatterName,
    this.newBatterName,
    this.extraType,
    this.isLegal = true,
    this.isManualSwap = false,
  }) : battingRuns = battingRuns ?? runs,
       ranRuns = ranRuns ?? runs;

  const Delivery.manualSwap({required this.bowlerName})
    : runs = 0,
      battingRuns = 0,
      ranRuns = 0,
      isWicket = false,
      dismissalType = null,
      fielderName = null,
      dismissedBatterName = null,
      newBatterName = null,
      extraType = null,
      isLegal = false,
      isManualSwap = true;

  /// PRD §7.7 / AC: "Given format says no-ball = 1 run + rebowl, Then
  /// extras honor the match's sub-rules from E4-01."
  factory Delivery.extra({
    required String bowlerName,
    required ExtraType type,
    required int additionalRuns,
    required ExtraSubRules subRules,
  }) {
    switch (type) {
      case ExtraType.wide:
        return Delivery(
          bowlerName: bowlerName,
          runs: subRules.wideRuns + additionalRuns,
          battingRuns: 0,
          ranRuns: additionalRuns,
          extraType: type,
          isLegal: false,
        );
      case ExtraType.noBall:
        return Delivery(
          bowlerName: bowlerName,
          runs: subRules.noBallRuns + additionalRuns,
          battingRuns: additionalRuns,
          ranRuns: additionalRuns,
          extraType: type,
          isLegal: !subRules.noBallRebowl,
        );
      case ExtraType.bye:
      case ExtraType.legBye:
        return Delivery(
          bowlerName: bowlerName,
          runs: additionalRuns,
          battingRuns: 0,
          extraType: type,
          isLegal: true,
        );
    }
  }
}

class BatterInnings {
  final String name;
  final int runs;
  final int balls;
  final bool isOut;
  final DismissalType? dismissalType;

  const BatterInnings({
    required this.name,
    this.runs = 0,
    this.balls = 0,
    this.isOut = false,
    this.dismissalType,
  });

  BatterInnings copyWith({
    int? runs,
    int? balls,
    bool? isOut,
    DismissalType? dismissalType,
  }) {
    return BatterInnings(
      name: name,
      runs: runs ?? this.runs,
      balls: balls ?? this.balls,
      isOut: isOut ?? this.isOut,
      dismissalType: dismissalType ?? this.dismissalType,
    );
  }
}

class BowlerInnings {
  final String name;
  final int ballsBowled;
  final int runsConceded;
  final int wickets;

  const BowlerInnings({
    required this.name,
    this.ballsBowled = 0,
    this.runsConceded = 0,
    this.wickets = 0,
  });

  int get completedOvers => ballsBowled ~/ 6;
  int get ballsThisOver => ballsBowled % 6;

  BowlerInnings copyWith({int? ballsBowled, int? runsConceded, int? wickets}) {
    return BowlerInnings(
      name: name,
      ballsBowled: ballsBowled ?? this.ballsBowled,
      runsConceded: runsConceded ?? this.runsConceded,
      wickets: wickets ?? this.wickets,
    );
  }
}

/// Mock batting lineup for the debug demo -- no real Selection Board
/// (E3-08) hookup exists yet.
List<String> mockBattingOrder() => const [
  'Rohan Verma',
  'Kabir Singh',
  'Arjun Rao',
  'Priya Nair',
  'Ananya Iyer',
  'Farhan Ali',
  'Vikram Shah',
  'Meera Joshi',
  'Suresh Patel',
  'Kunal Mehta',
  'Aditya Kumar',
];

class InningsState {
  final String battingTeamName;
  final String bowlingTeamName;
  final List<String> battingOrder;
  final List<String> bowlingRoster;
  final List<Delivery> deliveries;
  final String strikerName;
  final String nonStrikerName;
  final String currentBowlerName;
  final int totalOversPerSide;
  final ExtraSubRules subRules;

  const InningsState({
    required this.battingTeamName,
    required this.bowlingTeamName,
    required this.battingOrder,
    required this.bowlingRoster,
    required this.strikerName,
    required this.nonStrikerName,
    required this.currentBowlerName,
    required this.totalOversPerSide,
    this.deliveries = const [],
    this.subRules = const ExtraSubRules(),
  });

  int get totalRuns => deliveries.fold(0, (sum, d) => sum + d.runs);
  int get wicketsLost => deliveries.where((d) => d.isWicket).length;
  int get _legalDeliveryCount => deliveries.where((d) => d.isLegal).length;
  int get legalBallsThisOver => _legalDeliveryCount % 6;
  int get completedOvers => _legalDeliveryCount ~/ 6;

  /// The traditional cap of one-fifth of the innings' overs (ODI 50 ->
  /// 10, T20 20 -> 4), rounded up for odd-over formats. PRD/DS give no
  /// other concrete formula, and this ratio is the one real-world rule
  /// that generalizes across formats.
  int get maxOversPerBowler => (totalOversPerSide / 5).ceil();

  Map<String, BowlerInnings> get bowlers {
    final result = <String, BowlerInnings>{};
    for (final d in deliveries) {
      final current = result[d.bowlerName] ?? BowlerInnings(name: d.bowlerName);
      result[d.bowlerName] = current.copyWith(
        ballsBowled: current.ballsBowled + (d.isLegal ? 1 : 0),
        runsConceded: current.runsConceded + d.runs,
        wickets: current.wickets + (d.isWicket ? 1 : 0),
      );
    }
    return result;
  }

  /// AC: "Given over ends, Then bowler sheet lists only legal bowlers
  /// with overs-left captions" -- excludes whoever bowled the over that
  /// just ended (no consecutive overs) and anyone who has already
  /// bowled their quota.
  List<String> get eligibleNextBowlers {
    return bowlingRoster.where((name) {
      if (name == currentBowlerName) return false;
      final overs = bowlers[name]?.completedOvers ?? 0;
      return overs < maxOversPerBowler;
    }).toList();
  }

  /// Single replay pass deriving both batters' stats and who's
  /// currently on strike -- kept as one pass (rather than separate
  /// getters re-deriving strike independently) so the two can never
  /// disagree. PRD §7.7: "auto strike-swap on odd runs & over-end."
  /// - Odd [Delivery.ranRuns] swaps strike (byes/leg-byes and any
  ///   actually-run extra runs count; the fixed wide/no-ball penalty
  ///   run never does, since nobody ran for it).
  /// - Completing a legal over always swaps strike (the bowling end
  ///   changes), regardless of the last ball's run parity.
  /// - A wicket substitutes the new batter into the dismissed batter's
  ///   crease position (same end/strike role) -- it is not itself a
  ///   swap. [Delivery.dismissedBatterName] says which end was actually
  ///   out (defaults to the striker; only a run-out can name the
  ///   non-striker instead). Partial runs completed before a run-out
  ///   aren't modeled (recordWicket always logs 0 runs), a deliberate
  ///   simplification.
  /// - [Delivery.isManualSwap] (the scorer's own swap-strike button)
  ///   always swaps, independent of runs/over-boundary.
  ({String striker, String nonStriker, Map<String, BatterInnings> stats})
  get _replay {
    var striker = strikerName;
    var nonStriker = nonStrikerName;
    final stats = <String, BatterInnings>{};
    var legalBallsInOver = 0;

    void swap() {
      final tmp = striker;
      striker = nonStriker;
      nonStriker = tmp;
    }

    for (final d in deliveries) {
      if (d.isManualSwap) {
        swap();
        continue;
      }
      final current = stats[striker] ?? BatterInnings(name: striker);
      stats[striker] = current.copyWith(
        runs: current.runs + d.battingRuns,
        balls: current.balls + (d.isLegal ? 1 : 0),
      );
      if (d.isWicket) {
        final dismissed = d.dismissedBatterName ?? striker;
        final dismissedCurrent =
            stats[dismissed] ?? BatterInnings(name: dismissed);
        stats[dismissed] = dismissedCurrent.copyWith(
          isOut: true,
          dismissalType: d.dismissalType,
        );
        if (d.newBatterName != null) {
          if (dismissed == striker) {
            striker = d.newBatterName!;
          } else {
            nonStriker = d.newBatterName!;
          }
        }
      } else if (d.ranRuns.isOdd) {
        swap();
      }
      if (d.isLegal) {
        legalBallsInOver++;
        if (legalBallsInOver == 6) {
          legalBallsInOver = 0;
          swap();
        }
      }
    }
    return (striker: striker, nonStriker: nonStriker, stats: stats);
  }

  Map<String, BatterInnings> get batters => _replay.stats;

  BowlerInnings get currentBowlerInnings =>
      bowlers[currentBowlerName] ?? BowlerInnings(name: currentBowlerName);

  String get currentStriker => _replay.striker;

  String get currentNonStriker => _replay.nonStriker;

  InningsState copyWith({
    List<Delivery>? deliveries,
    String? currentBowlerName,
  }) {
    return InningsState(
      battingTeamName: battingTeamName,
      bowlingTeamName: bowlingTeamName,
      battingOrder: battingOrder,
      bowlingRoster: bowlingRoster,
      strikerName: strikerName,
      nonStrikerName: nonStrikerName,
      currentBowlerName: currentBowlerName ?? this.currentBowlerName,
      totalOversPerSide: totalOversPerSide,
      subRules: subRules,
      deliveries: deliveries ?? this.deliveries,
    );
  }
}

/// Mock bowling-side roster for the debug demo -- no real Selection
/// Board (E3-08) hookup exists yet either.
List<String> mockBowlingRoster() => const [
  'Deepak Sharma',
  'Rahul Deshmukh',
  'Sanjay Gupta',
  'Imran Khan',
  'Vikas Nair',
];
