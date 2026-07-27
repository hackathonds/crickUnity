/// PRD §8.4 (Points Table): "Points table live-updates on match
/// confirmation; NRR computed & tappable to see formula inputs;
/// manual adjustments (penalties/walkovers) badge-marked with public
/// reason." Backlog cites "G.3" for the what-if calculator -- no
/// Appendix G exists anywhere in the frozen PRD (only Appendix A and B
/// are real, confirmed by grepping every `^# Appendix` heading, same
/// phantom-citation pattern flagged repeatedly this session).
///
/// No structural link exists yet between the live-scoring Match model
/// (matches/scoring_provider.dart) and a Tournament fixture -- wiring
/// a genuine ripple from match confirmation into tournament standings
/// would mean threading a tournamentId/fixtureId through the entire
/// match-creation and live-scoring pipeline, disproportionate to this
/// M-sized story. Results are instead recorded directly against a
/// Fixture here (a debug-style organizer action), same "stand-in for a
/// missing upstream trigger" convention as several earlier stories
/// this session (e.g. records_provider.dart's transferRecord, E8-02).
class MatchResult {
  final String fixtureId;
  final int homeRuns;
  final double homeOvers;
  final int awayRuns;
  final double awayOvers;
  final String? winnerRegistrationId; // null = tie/no-result
  final bool isManualAdjustment;
  final String? adjustmentReason;

  const MatchResult({
    required this.fixtureId,
    required this.homeRuns,
    required this.homeOvers,
    required this.awayRuns,
    required this.awayOvers,
    this.winnerRegistrationId,
    this.isManualAdjustment = false,
    this.adjustmentReason,
  });
}

/// PRD's NRR is the standard cricket formula: (runs scored / overs
/// faced) - (runs conceded / overs bowled), aggregated across a team's
/// matches.
double netRunRate({
  required int runsFor,
  required double oversFor,
  required int runsAgainst,
  required double oversAgainst,
}) {
  final forRate = oversFor == 0 ? 0.0 : runsFor / oversFor;
  final againstRate = oversAgainst == 0 ? 0.0 : runsAgainst / oversAgainst;
  return forRate - againstRate;
}

class StandingsRow {
  final String registrationId;
  final String teamName;
  final int played;
  final int won;
  final int lost;
  final int tied;
  final int points;
  final int runsFor;
  final double oversFor;
  final int runsAgainst;
  final double oversAgainst;

  const StandingsRow({
    required this.registrationId,
    required this.teamName,
    this.played = 0,
    this.won = 0,
    this.lost = 0,
    this.tied = 0,
    this.points = 0,
    this.runsFor = 0,
    this.oversFor = 0,
    this.runsAgainst = 0,
    this.oversAgainst = 0,
  });

  double get nrr => netRunRate(
    runsFor: runsFor,
    oversFor: oversFor,
    runsAgainst: runsAgainst,
    oversAgainst: oversAgainst,
  );
}

/// PRD (backlog line): "slider scenarios savable." A saved what-if
/// scenario projects one unplayed fixture's result and re-derives the
/// table around it, without touching real recorded results.
class WhatIfScenario {
  final String id;
  final String name;
  final String fixtureId;
  final String hypotheticalWinnerRegistrationId;
  final int hypotheticalMargin;
  final DateTime createdAt;

  const WhatIfScenario({
    required this.id,
    required this.name,
    required this.fixtureId,
    required this.hypotheticalWinnerRegistrationId,
    required this.hypotheticalMargin,
    required this.createdAt,
  });
}
