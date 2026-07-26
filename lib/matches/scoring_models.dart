import 'match_models.dart' show ExtraSubRules;

/// PRD §7.7 (Live Scoring / Scorer Console) / DS §7 screen 27. This is
/// sub-task 1/4 of E4-04's XL split ("pad / extras / bowler-select /
/// strike-swap" per the backlog): the core ball-by-ball engine, run
/// buttons, wicket + dismissal sheet, and undo. Sub-task 2/4 (extras)
/// is layered in below. Still deliberately excluded:
/// - next-bowler rotation/enforcement -- sub-task 3 (the same bowler
///   keeps bowling indefinitely here)
/// - strike rotation on odd runs/over-end -- sub-task 4 (the striker
///   never changes here except when a new batter replaces a dismissed
///   one)
/// No Selection Board (E3-08) integration exists between match
/// creation and an actual XI, so the batting order is a mock lineup.
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
/// runs actually run/hit off a no-ball are. [isLegal] says whether this
/// ball counts toward the 6-ball over -- wides never count; no-balls
/// count only if the match's sub-rules turn rebowl off.
class Delivery {
  final int runs;
  final int battingRuns;
  final bool isWicket;
  final DismissalType? dismissalType;
  final String? fielderName;
  final String? newBatterName;
  final ExtraType? extraType;
  final bool isLegal;

  const Delivery({
    required this.runs,
    int? battingRuns,
    this.isWicket = false,
    this.dismissalType,
    this.fielderName,
    this.newBatterName,
    this.extraType,
    this.isLegal = true,
  }) : battingRuns = battingRuns ?? runs;

  /// PRD §7.7 / AC: "Given format says no-ball = 1 run + rebowl, Then
  /// extras honor the match's sub-rules from E4-01."
  factory Delivery.extra({
    required ExtraType type,
    required int additionalRuns,
    required ExtraSubRules subRules,
  }) {
    switch (type) {
      case ExtraType.wide:
        return Delivery(
          runs: subRules.wideRuns + additionalRuns,
          battingRuns: 0,
          extraType: type,
          isLegal: false,
        );
      case ExtraType.noBall:
        return Delivery(
          runs: subRules.noBallRuns + additionalRuns,
          battingRuns: additionalRuns,
          extraType: type,
          isLegal: !subRules.noBallRebowl,
        );
      case ExtraType.bye:
      case ExtraType.legBye:
        return Delivery(
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
  final List<Delivery> deliveries;
  final String strikerName;
  final String nonStrikerName;
  final String currentBowlerName;
  final ExtraSubRules subRules;

  const InningsState({
    required this.battingTeamName,
    required this.bowlingTeamName,
    required this.battingOrder,
    required this.strikerName,
    required this.nonStrikerName,
    required this.currentBowlerName,
    this.deliveries = const [],
    this.subRules = const ExtraSubRules(),
  });

  int get totalRuns => deliveries.fold(0, (sum, d) => sum + d.runs);
  int get wicketsLost => deliveries.where((d) => d.isWicket).length;
  int get _legalDeliveryCount => deliveries.where((d) => d.isLegal).length;
  int get legalBallsThisOver => _legalDeliveryCount % 6;
  int get completedOvers => _legalDeliveryCount ~/ 6;

  Map<String, BatterInnings> get batters {
    final result = <String, BatterInnings>{};
    var striker = strikerName;
    for (final d in deliveries) {
      final current = result[striker] ?? BatterInnings(name: striker);
      result[striker] = current.copyWith(
        runs: current.runs + d.battingRuns,
        balls: current.balls + (d.isLegal ? 1 : 0),
      );
      if (d.isWicket) {
        result[striker] = result[striker]!.copyWith(
          isOut: true,
          dismissalType: d.dismissalType,
        );
        if (d.newBatterName != null) {
          striker = d.newBatterName!;
        }
      }
    }
    return result;
  }

  BowlerInnings get currentBowlerInnings {
    var bowler = BowlerInnings(name: currentBowlerName);
    for (final d in deliveries) {
      bowler = bowler.copyWith(
        ballsBowled: bowler.ballsBowled + (d.isLegal ? 1 : 0),
        runsConceded: bowler.runsConceded + d.runs,
        wickets: bowler.wickets + (d.isWicket ? 1 : 0),
      );
    }
    return bowler;
  }

  /// The batter currently on strike -- the last new-batter substitution
  /// recorded, or the innings' original striker if nobody has been
  /// dismissed yet. (Sub-task 4 will add rotation on odd runs/over-end;
  /// until then this is the only thing that ever changes strike.)
  String get currentStriker {
    for (final d in deliveries.reversed) {
      if (d.isWicket && d.newBatterName != null) return d.newBatterName!;
    }
    return strikerName;
  }

  InningsState copyWith({List<Delivery>? deliveries}) {
    return InningsState(
      battingTeamName: battingTeamName,
      bowlingTeamName: bowlingTeamName,
      battingOrder: battingOrder,
      strikerName: strikerName,
      nonStrikerName: nonStrikerName,
      currentBowlerName: currentBowlerName,
      subRules: subRules,
      deliveries: deliveries ?? this.deliveries,
    );
  }
}
