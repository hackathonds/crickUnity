/// PRD §5.3 (Career Statistics): "Split by format tabs. Batting: M,
/// Inns, Runs, HS, Avg, SR, 50s, 100s, 4s, 6s, ducks, not-outs. Bowling:
/// O, W, Best, Avg, Econ, SR, 3W/5W, maidens, dots%. Fielding: catches,
/// run-outs, stumpings. ... Each stat tappable -> underlying verified
/// match list. Verified vs Unverified split ... Manual 'pre-app career'
/// entry allowed but permanently labeled 'Self-reported' and excluded
/// from rankings."
/// PRD §5.7 (Performance Charts): "Runs/wickets by match (last
/// 10/season/career), form curve, SR vs Avg scatter per bowling type
/// faced, dismissal-type pie, scoring-zone wagon aggregate ... Public
/// sees season-level; detailed opposition splits are Self + Teammate
/// view."
library;

enum StatVerifiedFilter { verified, unverified }

const Map<StatVerifiedFilter, String> statVerifiedFilterLabels = {
  StatVerifiedFilter.verified: 'Verified',
  StatVerifiedFilter.unverified: 'Unverified',
};

class BattingCareerRow {
  final int matches;
  final int innings;
  final int runs;
  final int highestScore;
  final bool highestScoreNotOut;
  final int dismissals;
  final int balls;
  final int fifties;
  final int hundreds;
  final int fours;
  final int sixes;
  final int ducks;
  final int notOuts;

  const BattingCareerRow({
    this.matches = 0,
    this.innings = 0,
    this.runs = 0,
    this.highestScore = 0,
    this.highestScoreNotOut = false,
    this.dismissals = 0,
    this.balls = 0,
    this.fifties = 0,
    this.hundreds = 0,
    this.fours = 0,
    this.sixes = 0,
    this.ducks = 0,
    this.notOuts = 0,
  });

  double get average => dismissals == 0 ? runs.toDouble() : runs / dismissals;
  double get strikeRate => balls == 0 ? 0 : 100 * runs / balls;
}

class BowlingCareerRow {
  final int matches;
  final int legalBalls;
  final int wickets;
  final int runsConceded;
  final String bestFigures;
  final int threeWicketHauls;
  final int fiveWicketHauls;
  final int dotBalls;
  final int maidens;

  const BowlingCareerRow({
    this.matches = 0,
    this.legalBalls = 0,
    this.wickets = 0,
    this.runsConceded = 0,
    this.bestFigures = '-',
    this.threeWicketHauls = 0,
    this.fiveWicketHauls = 0,
    this.dotBalls = 0,
    this.maidens = 0,
  });

  double get overs => legalBalls / 6;
  double get average => wickets == 0 ? 0 : runsConceded / wickets;
  double get economy => legalBalls == 0 ? 0 : 6 * runsConceded / legalBalls;
  double get strikeRate => wickets == 0 ? 0 : legalBalls / wickets;
  double get dotBallPercent =>
      legalBalls == 0 ? 0 : 100 * dotBalls / legalBalls;
}

class FieldingCareerRow {
  final int catches;
  final int runOuts;
  final int stumpings;

  const FieldingCareerRow({
    this.catches = 0,
    this.runOuts = 0,
    this.stumpings = 0,
  });
}

/// AC: "every stat number opens its source list" -- the matches feeding
/// one particular stat, with the PRD's "permanently labeled
/// 'Self-reported'" rule surfaced per row.
class StatSourceEntry {
  final String matchLabel;
  final String detail;
  final bool isPreApp;

  const StatSourceEntry({
    required this.matchLabel,
    required this.detail,
    this.isPreApp = false,
  });
}

class CareerStatsSnapshot {
  final BattingCareerRow batting;
  final BowlingCareerRow bowling;
  final FieldingCareerRow fielding;

  const CareerStatsSnapshot({
    required this.batting,
    required this.bowling,
    required this.fielding,
  });
}
