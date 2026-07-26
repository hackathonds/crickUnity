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

/// DS §11.7: "Wagon direction input: after any scoring shot, optional
/// ghost overlay of ground sectors fades in for 1.5s ... tap sector to
/// log." 8 sectors is the standard cricket wagon-wheel breakdown.
enum WagonSector {
  fineLeg,
  square,
  midwicket,
  longOn,
  longOff,
  cover,
  point,
  thirdMan,
}

const Map<WagonSector, String> wagonSectorLabels = {
  WagonSector.fineLeg: 'Fine leg',
  WagonSector.square: 'Square leg',
  WagonSector.midwicket: 'Midwicket',
  WagonSector.longOn: 'Long on',
  WagonSector.longOff: 'Long off',
  WagonSector.cover: 'Cover',
  WagonSector.point: 'Point',
  WagonSector.thirdMan: 'Third man',
};

/// The compact per-ball label used on both the over-beads strip and the
/// ball timeline (E4-06) -- kept as one function so the two never drift.
String deliveryLabel(Delivery delivery) {
  if (delivery.isManualSwap) return '↔';
  if (delivery.isWicket) return 'W';
  final type = delivery.extraType;
  if (type == null) return '${delivery.runs}';
  return delivery.runs > 0
      ? '${extraTypeShortLabels[type]}${delivery.runs}'
      : extraTypeShortLabels[type]!;
}

/// PRD §7.8: "Auto-generated text per ball ('FOUR! Priya drives through
/// covers')." A plain template generator -- scorer quick-edit/custom
/// notes aren't modeled (no rich-commentary-editing UI exists yet).
String commentaryFor(Delivery delivery, {required String strikerName}) {
  if (delivery.isManualSwap) return 'Batters cross ends.';
  if (delivery.isWicket) {
    return "OUT! $strikerName's innings ends -- "
        '${dismissalTypeLabels[delivery.dismissalType]}.';
  }
  final type = delivery.extraType;
  if (type != null) {
    final label = extraTypeLabels[type]!;
    return delivery.runs > 0
        ? '$label, ${delivery.runs} run${delivery.runs == 1 ? '' : 's'}.'
        : '$label.';
  }
  return switch (delivery.runs) {
    0 => '$strikerName defends -- dot ball.',
    4 => 'FOUR! $strikerName finds the gap.',
    6 => 'SIX! $strikerName clears the ropes.',
    _ =>
      '$strikerName takes ${delivery.runs} '
          'run${delivery.runs == 1 ? '' : 's'}.',
  };
}

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
///
/// [isCorrected] (E4-06): the audit marker a ball carries once its
/// recorded runs have been corrected after the fact, whether that
/// correction was free (within the last-2-overs window) or required
/// both captains' acknowledgment (older).
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
  final bool isCorrected;
  final WagonSector? wagonSector;

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
    this.isCorrected = false,
    this.wagonSector,
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
      isManualSwap = true,
      isCorrected = false,
      wagonSector = null;

  /// AC: "corrected balls carry an audit marker in ball timeline" --
  /// only the runs (and, transitively, battingRuns/ranRuns for a plain
  /// scoring ball) are correctable; changing a ball's wicket/extra
  /// nature after the fact isn't in scope here.
  Delivery correctedTo(int newRuns) {
    final ranDelta = newRuns - runs;
    return Delivery(
      bowlerName: bowlerName,
      runs: newRuns,
      battingRuns: isWicket || extraType != null ? battingRuns : newRuns,
      ranRuns: ranRuns + ranDelta,
      isWicket: isWicket,
      dismissalType: dismissalType,
      fielderName: fielderName,
      dismissedBatterName: dismissedBatterName,
      newBatterName: newBatterName,
      extraType: extraType,
      isLegal: isLegal,
      isManualSwap: isManualSwap,
      isCorrected: true,
      wagonSector: wagonSector,
    );
  }

  /// DS §11.7: "tap sector to log" -- logged after the fact, once the
  /// scorer taps a sector on the transient ghost overlay.
  Delivery withWagonSector(WagonSector sector) {
    return Delivery(
      bowlerName: bowlerName,
      runs: runs,
      battingRuns: battingRuns,
      ranRuns: ranRuns,
      isWicket: isWicket,
      dismissalType: dismissalType,
      fielderName: fielderName,
      dismissedBatterName: dismissedBatterName,
      newBatterName: newBatterName,
      extraType: extraType,
      isLegal: isLegal,
      isManualSwap: isManualSwap,
      isCorrected: isCorrected,
      wagonSector: sector,
    );
  }

  /// DS §11.7: "after any scoring shot" -- a genuine shot off the bat
  /// that scored runs (not a wicket ball, not an extra).
  bool get isEligibleForWagonInput =>
      !isWicket && extraType == null && battingRuns > 0;

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

/// PRD §2.6 (Scorer): "edit balls within the correction window (last 2
/// overs freely; older balls require both captains' acknowledgment)."
/// A pending correction for a ball outside that free window -- it only
/// takes effect once both [composerCaptainAcked] and
/// [opponentCaptainAcked] are true.
class CorrectionRequest {
  final int deliveryIndex;
  final int proposedRuns;
  final String reason;
  final bool composerCaptainAcked;
  final bool opponentCaptainAcked;

  const CorrectionRequest({
    required this.deliveryIndex,
    required this.proposedRuns,
    required this.reason,
    this.composerCaptainAcked = false,
    this.opponentCaptainAcked = false,
  });

  bool get isFullyAcked => composerCaptainAcked && opponentCaptainAcked;

  CorrectionRequest copyWith({
    bool? composerCaptainAcked,
    bool? opponentCaptainAcked,
  }) {
    return CorrectionRequest(
      deliveryIndex: deliveryIndex,
      proposedRuns: proposedRuns,
      reason: reason,
      composerCaptainAcked: composerCaptainAcked ?? this.composerCaptainAcked,
      opponentCaptainAcked: opponentCaptainAcked ?? this.opponentCaptainAcked,
    );
  }
}

class BatterInnings {
  final String name;
  final int runs;
  final int balls;
  final bool isOut;
  final DismissalType? dismissalType;
  final String? dismissingBowlerName;
  final String? dismissingFielderName;

  const BatterInnings({
    required this.name,
    this.runs = 0,
    this.balls = 0,
    this.isOut = false,
    this.dismissalType,
    this.dismissingBowlerName,
    this.dismissingFielderName,
  });

  /// DS §7 screen 29: "batting table: dismissal text 13 wraps."
  String get dismissalText {
    if (!isOut) return 'not out';
    switch (dismissalType!) {
      case DismissalType.bowled:
        return 'b $dismissingBowlerName';
      case DismissalType.caught:
        return 'c $dismissingFielderName b $dismissingBowlerName';
      case DismissalType.lbw:
        return 'lbw b $dismissingBowlerName';
      case DismissalType.runOut:
        return 'run out ($dismissingFielderName)';
      case DismissalType.stumped:
        return 'st $dismissingFielderName b $dismissingBowlerName';
      case DismissalType.hitWicket:
        return 'hit wicket b $dismissingBowlerName';
    }
  }

  BatterInnings copyWith({
    int? runs,
    int? balls,
    bool? isOut,
    DismissalType? dismissalType,
    String? dismissingBowlerName,
    String? dismissingFielderName,
  }) {
    return BatterInnings(
      name: name,
      runs: runs ?? this.runs,
      balls: balls ?? this.balls,
      isOut: isOut ?? this.isOut,
      dismissalType: dismissalType ?? this.dismissalType,
      dismissingBowlerName: dismissingBowlerName ?? this.dismissingBowlerName,
      dismissingFielderName:
          dismissingFielderName ?? this.dismissingFielderName,
    );
  }
}

/// DS §7 screen 29: "FoW ladder."
class FallOfWicket {
  final int wicketNumber;
  final int teamRunsAtFall;
  final String batterName;
  final int oversAtFall;
  final int ballsIntoOverAtFall;

  const FallOfWicket({
    required this.wicketNumber,
    required this.teamRunsAtFall,
    required this.batterName,
    required this.oversAtFall,
    required this.ballsIntoOverAtFall,
  });
}

/// PRD §7.14: "both captains + scorer confirm." Distinguishes the three
/// confirming parties without conflating with [TeamMemberRole] (this is
/// specifically about who signs off on a single match's scorecard).
enum ConfirmerRole { composerCaptain, opponentCaptain, scorer }

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
  final List<CorrectionRequest> pendingCorrections;
  final bool isPaused;
  final String? interruptionReason;
  final int? revisedOversForInnings;
  final int? targetRuns;
  final int consecutiveIgnoredWagonPrompts;
  final int wagonPromptDivisor;
  final int eligibleShotCounter;
  final String scorerName;
  final String? pendingHandoverToName;
  final bool composerCaptainApprovedHandover;
  final bool opponentCaptainApprovedHandover;
  final List<String> timelineEntries;
  final bool composerCaptainConfirmedScorecard;
  final bool opponentCaptainConfirmedScorecard;
  final bool scorerConfirmedScorecard;
  final bool isDisputed;
  final String? disputeReason;
  final bool rippleFired;
  final List<String> rippleLog;
  final DateTime scorecardPostedAt;

  const InningsState({
    required this.battingTeamName,
    required this.bowlingTeamName,
    required this.battingOrder,
    required this.bowlingRoster,
    required this.strikerName,
    required this.nonStrikerName,
    required this.currentBowlerName,
    required this.totalOversPerSide,
    required this.scorerName,
    required this.scorecardPostedAt,
    this.deliveries = const [],
    this.subRules = const ExtraSubRules(),
    this.pendingCorrections = const [],
    this.isPaused = false,
    this.interruptionReason,
    this.revisedOversForInnings,
    this.targetRuns,
    this.consecutiveIgnoredWagonPrompts = 0,
    this.wagonPromptDivisor = 1,
    this.eligibleShotCounter = 0,
    this.pendingHandoverToName,
    this.composerCaptainApprovedHandover = false,
    this.opponentCaptainApprovedHandover = false,
    this.timelineEntries = const [],
    this.composerCaptainConfirmedScorecard = false,
    this.opponentCaptainConfirmedScorecard = false,
    this.scorerConfirmedScorecard = false,
    this.isDisputed = false,
    this.disputeReason,
    this.rippleFired = false,
    this.rippleLog = const [],
  });

  bool get isFullyConfirmed =>
      composerCaptainConfirmedScorecard &&
      opponentCaptainConfirmedScorecard &&
      scorerConfirmedScorecard;

  /// PRD §7.14: "auto-confirm 48h if unchallenged."
  static const int scorecardAutoConfirmHours = 48;

  bool canAutoConfirm({DateTime Function() now = DateTime.now}) =>
      !isDisputed &&
      !isFullyConfirmed &&
      now().difference(scorecardPostedAt).inHours >= scorecardAutoConfirmHours;

  int get totalRuns => deliveries.fold(0, (sum, d) => sum + d.runs);
  int get wicketsLost => deliveries.where((d) => d.isWicket).length;
  int get _legalDeliveryCount => deliveries.where((d) => d.isLegal).length;
  int get legalBallsThisOver => _legalDeliveryCount % 6;
  int get completedOvers => _legalDeliveryCount ~/ 6;

  /// PRD §7.7: "offers revised-overs calculator" -- the innings' overs
  /// after any rain/delay adjustment, or the original format overs if
  /// none has happened yet.
  int get effectiveTotalOvers => revisedOversForInnings ?? totalOversPerSide;

  double get _oversFaced => completedOvers + legalBallsThisOver / 6;

  double get currentRunRate => _oversFaced > 0 ? totalRuns / _oversFaced : 0;

  double get oversRemaining => (effectiveTotalOvers - _oversFaced).clamp(
    0.0,
    effectiveTotalOvers.toDouble(),
  );

  /// Only meaningful for a 2nd-innings chase ([targetRuns] set) --
  /// PRD/DS give no target-setting flow of their own yet (no 2-innings
  /// match model exists), so this is null until a caller sets one.
  /// Recomputed fresh from [effectiveTotalOvers] on every read, so
  /// resuming from an interruption with revised overs automatically
  /// changes the answer -- AC: "resuming recomputes RRR strip."
  double? get requiredRunRate {
    final target = targetRuns;
    if (target == null) return null;
    if (oversRemaining <= 0) return double.infinity;
    return (target - totalRuns) / oversRemaining;
  }

  /// DS §11.7: "completeness % lives in Charts tab" -- Charts itself is
  /// E4-11 scope, but the underlying figure is computed here so this
  /// console can surface it inline in the meantime.
  double get wagonCompletionPercent {
    final eligible = deliveries.where((d) => d.isEligibleForWagonInput);
    if (eligible.isEmpty) return 0;
    final logged = eligible.where((d) => d.wagonSector != null).length;
    return 100 * logged / eligible.length;
  }

  /// AC: "ignoring the ghost 10 times in a row auto-reduces its prompt
  /// frequency" -- [wagonPromptDivisor] (1 normally) throttles how often
  /// an eligible shot actually prompts, once the scorer has shown 10
  /// consecutive times running that they don't want to be asked.
  bool get shouldPromptWagonThisShot =>
      eligibleShotCounter % wagonPromptDivisor == 0;

  /// PRD §2.6: "last 2 overs freely" -- the over each delivery belongs
  /// to (illegal/manual-swap balls share whichever over was in progress
  /// when they happened), so corrections can tell whether a ball is
  /// still inside the free window.
  List<int> get _overIndexPerDelivery {
    final result = <int>[];
    var legalCount = 0;
    for (final d in deliveries) {
      result.add(legalCount ~/ 6);
      if (d.isLegal) legalCount++;
    }
    return result;
  }

  static const int freeCorrectionWindowOvers = 2;

  bool isWithinFreeCorrectionWindow(int deliveryIndex) {
    final overIndices = _overIndexPerDelivery;
    if (deliveryIndex < 0 || deliveryIndex >= overIndices.length) return false;
    return completedOvers - overIndices[deliveryIndex] <
        freeCorrectionWindowOvers;
  }

  /// Every ball (legal or not) since the last completed-over boundary --
  /// what the plain Undo stack is allowed to reach into, and what the
  /// over-beads strip renders. Manual swap-strike markers aren't balls
  /// at all and never appear here.
  List<Delivery> get currentOverDeliveries {
    final target = legalBallsThisOver;
    final result = <Delivery>[];
    var legalCounted = 0;
    for (var i = deliveries.length - 1; i >= 0; i--) {
      final d = deliveries[i];
      if (d.isManualSwap) continue;
      if (d.isLegal) {
        if (legalCounted >= target) break;
        legalCounted++;
      }
      result.insert(0, d);
    }
    return result;
  }

  /// AC (backlog): "Unlimited undo within current over" -- the plain
  /// Undo button only ever pops the last delivery, so it's "free" iff
  /// that delivery is still part of the in-progress over. Reaching into
  /// an already-completed over needs the ball-timeline correction flow
  /// instead (PRD §2.6).
  bool get canUndoFreely => currentOverDeliveries.isNotEmpty;

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

  /// DS §7 screen 29: "FoW ladder." A second small replay -- kept
  /// separate from [_replay] since it tracks team-running-total/over
  /// position rather than per-batter stats or strike.
  List<FallOfWicket> get fallOfWickets {
    final result = <FallOfWicket>[];
    var runningRuns = 0;
    var legalBalls = 0;
    for (final d in deliveries) {
      runningRuns += d.runs;
      if (d.isWicket) {
        result.add(
          FallOfWicket(
            wicketNumber: result.length + 1,
            teamRunsAtFall: runningRuns,
            batterName: d.dismissedBatterName ?? currentStriker,
            oversAtFall: legalBalls ~/ 6,
            ballsIntoOverAtFall: legalBalls % 6,
          ),
        );
      }
      if (d.isLegal) legalBalls++;
    }
    return result;
  }

  /// DS §3.3: "Manhattan: bar width = (plot/overs)-2 gap, wicket dots 6
  /// on top." Runs scored in each completed-or-in-progress over, plus
  /// how many wickets fell in that over (rendered as dots, not a full
  /// custom bar chart -- see LiveMatchViewScreen's doc comment for why).
  List<(int runs, int wickets)> get runsPerOver {
    final result = <(int, int)>[];
    var overRuns = 0;
    var overWickets = 0;
    var legalBalls = 0;
    for (final d in deliveries) {
      overRuns += d.runs;
      if (d.isWicket) overWickets++;
      if (d.isLegal) {
        legalBalls++;
        if (legalBalls % 6 == 0) {
          result.add((overRuns, overWickets));
          overRuns = 0;
          overWickets = 0;
        }
      }
    }
    if (overRuns > 0 || legalBalls % 6 != 0) {
      result.add((overRuns, overWickets));
    }
    return result;
  }

  /// DS §3.3: "Worm: 2px lines, chasing overlay dashed for required-
  /// rate." Cumulative team total after each completed over.
  List<int> get cumulativeRunsPerOver {
    var running = 0;
    final result = <int>[];
    for (final (runs, _) in runsPerOver) {
      running += runs;
      result.add(running);
    }
    return result;
  }

  /// DS §3.3 Partnerships: runs added between consecutive wicket falls
  /// (plus the current, still-unbroken stand).
  List<int> get partnershipRuns {
    final result = <int>[];
    var previous = 0;
    for (final fow in fallOfWickets) {
      result.add(fow.teamRunsAtFall - previous);
      previous = fow.teamRunsAtFall;
    }
    if (totalRuns > previous) result.add(totalRuns - previous);
    return result;
  }

  /// DS §3.3 Wagon wheel: per-sector shot counts (a simplified list
  /// breakdown rather than a radial ground diagram -- see
  /// LiveMatchViewScreen's doc comment).
  Map<WagonSector, int> get wagonSectorCounts {
    final result = <WagonSector, int>{};
    for (final d in deliveries) {
      final sector = d.wagonSector;
      if (sector != null) result[sector] = (result[sector] ?? 0) + 1;
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
  ({
    String striker,
    String nonStriker,
    Map<String, BatterInnings> stats,
    List<String> strikerPerDelivery,
  })
  get _replay {
    var striker = strikerName;
    var nonStriker = nonStrikerName;
    final stats = <String, BatterInnings>{};
    final strikerPerDelivery = <String>[];
    var legalBallsInOver = 0;

    void swap() {
      final tmp = striker;
      striker = nonStriker;
      nonStriker = tmp;
    }

    for (final d in deliveries) {
      strikerPerDelivery.add(striker);
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
          dismissingBowlerName: d.bowlerName,
          dismissingFielderName: d.fielderName,
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
    return (
      striker: striker,
      nonStriker: nonStriker,
      stats: stats,
      strikerPerDelivery: strikerPerDelivery,
    );
  }

  Map<String, BatterInnings> get batters => _replay.stats;

  BowlerInnings get currentBowlerInnings =>
      bowlers[currentBowlerName] ?? BowlerInnings(name: currentBowlerName);

  String get currentStriker => _replay.striker;

  String get currentNonStriker => _replay.nonStriker;

  /// PRD §7.8: "Auto-generated text per ball." Who was actually facing
  /// each historical ball -- needed since [Delivery] itself doesn't
  /// store the striker (only the replay knows who was on strike at any
  /// given point).
  List<String> get strikerNamePerDelivery => _replay.strikerPerDelivery;

  InningsState copyWith({
    List<Delivery>? deliveries,
    String? currentBowlerName,
    List<CorrectionRequest>? pendingCorrections,
    bool? isPaused,
    String? interruptionReason,
    bool clearInterruptionReason = false,
    int? revisedOversForInnings,
    int? targetRuns,
    int? consecutiveIgnoredWagonPrompts,
    int? wagonPromptDivisor,
    int? eligibleShotCounter,
    String? scorerName,
    String? pendingHandoverToName,
    bool clearPendingHandoverToName = false,
    bool? composerCaptainApprovedHandover,
    bool? opponentCaptainApprovedHandover,
    List<String>? timelineEntries,
    bool? composerCaptainConfirmedScorecard,
    bool? opponentCaptainConfirmedScorecard,
    bool? scorerConfirmedScorecard,
    bool? isDisputed,
    String? disputeReason,
    bool? rippleFired,
    List<String>? rippleLog,
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
      scorerName: scorerName ?? this.scorerName,
      scorecardPostedAt: scorecardPostedAt,
      subRules: subRules,
      deliveries: deliveries ?? this.deliveries,
      pendingCorrections: pendingCorrections ?? this.pendingCorrections,
      isPaused: isPaused ?? this.isPaused,
      interruptionReason: clearInterruptionReason
          ? null
          : (interruptionReason ?? this.interruptionReason),
      revisedOversForInnings:
          revisedOversForInnings ?? this.revisedOversForInnings,
      targetRuns: targetRuns ?? this.targetRuns,
      consecutiveIgnoredWagonPrompts:
          consecutiveIgnoredWagonPrompts ?? this.consecutiveIgnoredWagonPrompts,
      wagonPromptDivisor: wagonPromptDivisor ?? this.wagonPromptDivisor,
      eligibleShotCounter: eligibleShotCounter ?? this.eligibleShotCounter,
      pendingHandoverToName: clearPendingHandoverToName
          ? null
          : (pendingHandoverToName ?? this.pendingHandoverToName),
      composerCaptainApprovedHandover:
          composerCaptainApprovedHandover ??
          this.composerCaptainApprovedHandover,
      opponentCaptainApprovedHandover:
          opponentCaptainApprovedHandover ??
          this.opponentCaptainApprovedHandover,
      timelineEntries: timelineEntries ?? this.timelineEntries,
      composerCaptainConfirmedScorecard:
          composerCaptainConfirmedScorecard ??
          this.composerCaptainConfirmedScorecard,
      opponentCaptainConfirmedScorecard:
          opponentCaptainConfirmedScorecard ??
          this.opponentCaptainConfirmedScorecard,
      scorerConfirmedScorecard:
          scorerConfirmedScorecard ?? this.scorerConfirmedScorecard,
      isDisputed: isDisputed ?? this.isDisputed,
      disputeReason: disputeReason ?? this.disputeReason,
      rippleFired: rippleFired ?? this.rippleFired,
      rippleLog: rippleLog ?? this.rippleLog,
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

/// DS §11.7: "Handover -> picker (present members)." Mock stand-in for
/// a real match-day attendance/check-in list, which doesn't exist yet.
List<String> mockPresentMembers() => const [
  'Deepak Sharma',
  'Rahul Deshmukh',
  'Sanjay Gupta',
];
