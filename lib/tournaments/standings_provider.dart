import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fixture_models.dart';
import 'registration_models.dart';
import 'standings_models.dart';
import 'tournament_models.dart';

class StandingsState {
  final Map<String, List<MatchResult>> resultsByTournament;
  final Map<String, List<WhatIfScenario>> scenariosByTournament;

  const StandingsState({
    this.resultsByTournament = const {},
    this.scenariosByTournament = const {},
  });

  StandingsState copyWith({
    Map<String, List<MatchResult>>? resultsByTournament,
    Map<String, List<WhatIfScenario>>? scenariosByTournament,
  }) {
    return StandingsState(
      resultsByTournament: resultsByTournament ?? this.resultsByTournament,
      scenariosByTournament:
          scenariosByTournament ?? this.scenariosByTournament,
    );
  }

  List<MatchResult> resultsFor(String tournamentId) =>
      resultsByTournament[tournamentId] ?? const [];

  List<WhatIfScenario> scenariosFor(String tournamentId) =>
      scenariosByTournament[tournamentId] ?? const [];
}

/// Backlog E10-04 -- Points table + NRR + what-if calculator engine.
/// See standings_models.dart's top-of-file note for the flagged
/// simplification (results recorded directly, not rippled from live
/// scoring) and the phantom "G.3" citation.
class StandingsNotifier extends Notifier<StandingsState> {
  @override
  StandingsState build() => const StandingsState();

  void recordResult(
    String tournamentId,
    String fixtureId, {
    required int homeRuns,
    required double homeOvers,
    required int awayRuns,
    required double awayOvers,
    required String? winnerRegistrationId,
  }) {
    _addResult(
      tournamentId,
      MatchResult(
        fixtureId: fixtureId,
        homeRuns: homeRuns,
        homeOvers: homeOvers,
        awayRuns: awayRuns,
        awayOvers: awayOvers,
        winnerRegistrationId: winnerRegistrationId,
      ),
    );
  }

  /// PRD §8.4: "manual adjustments (penalties/walkovers) badge-marked
  /// with public reason."
  void recordWalkover(
    String tournamentId,
    String fixtureId,
    String winnerRegistrationId,
    String reason,
  ) {
    _addResult(
      tournamentId,
      MatchResult(
        fixtureId: fixtureId,
        homeRuns: 0,
        homeOvers: 0,
        awayRuns: 0,
        awayOvers: 0,
        winnerRegistrationId: winnerRegistrationId,
        isManualAdjustment: true,
        adjustmentReason: reason,
      ),
    );
  }

  void _addResult(String tournamentId, MatchResult result) {
    final current = state.resultsFor(tournamentId);
    state = state.copyWith(
      resultsByTournament: {
        ...state.resultsByTournament,
        tournamentId: [
          for (final r in current)
            if (r.fixtureId != result.fixtureId) r,
          result,
        ],
      },
    );
  }

  void addScenario(String tournamentId, WhatIfScenario scenario) {
    state = state.copyWith(
      scenariosByTournament: {
        ...state.scenariosByTournament,
        tournamentId: [...state.scenariosFor(tournamentId), scenario],
      },
    );
  }

  void removeScenario(String tournamentId, String scenarioId) {
    state = state.copyWith(
      scenariosByTournament: {
        ...state.scenariosByTournament,
        tournamentId: state
            .scenariosFor(tournamentId)
            .where((s) => s.id != scenarioId)
            .toList(),
      },
    );
  }

  /// PRD §8.4: NRR "tappable to see formula inputs" and points-table
  /// live derivation. [extraResult] lets the what-if calculator inject
  /// one hypothetical result without touching real recorded state.
  List<StandingsRow> computeStandings(
    Tournament tournament,
    List<TeamRegistration> approvedTeams,
    List<Fixture> fixtures,
    List<MatchResult> results, {
    MatchResult? extraResult,
  }) {
    final effectiveResults = [
      for (final r in results)
        if (extraResult == null || r.fixtureId != extraResult.fixtureId) r,
      ?extraResult,
    ];
    final byFixture = {for (final r in effectiveResults) r.fixtureId: r};
    final scheme = tournament.pointsScheme;

    final rows = <String, StandingsRow>{
      for (final team in approvedTeams)
        team.id: StandingsRow(registrationId: team.id, teamName: team.teamName),
    };

    for (final fixture in fixtures) {
      final result = byFixture[fixture.id];
      if (result == null) continue;
      final home = rows[fixture.homeRegistrationId];
      final away = rows[fixture.awayRegistrationId];
      if (home == null || away == null) continue;

      final homeWon = result.winnerRegistrationId == fixture.homeRegistrationId;
      final awayWon = result.winnerRegistrationId == fixture.awayRegistrationId;
      final isTie = result.winnerRegistrationId == null;

      rows[fixture.homeRegistrationId] = StandingsRow(
        registrationId: home.registrationId,
        teamName: home.teamName,
        played: home.played + 1,
        won: home.won + (homeWon ? 1 : 0),
        lost: home.lost + (awayWon ? 1 : 0),
        tied: home.tied + (isTie ? 1 : 0),
        points:
            home.points +
            (homeWon ? scheme.winPoints : (isTie ? scheme.tiePoints : 0)),
        runsFor: home.runsFor + result.homeRuns,
        oversFor: home.oversFor + result.homeOvers,
        runsAgainst: home.runsAgainst + result.awayRuns,
        oversAgainst: home.oversAgainst + result.awayOvers,
      );
      rows[fixture.awayRegistrationId] = StandingsRow(
        registrationId: away.registrationId,
        teamName: away.teamName,
        played: away.played + 1,
        won: away.won + (awayWon ? 1 : 0),
        lost: away.lost + (homeWon ? 1 : 0),
        tied: away.tied + (isTie ? 1 : 0),
        points:
            away.points +
            (awayWon ? scheme.winPoints : (isTie ? scheme.tiePoints : 0)),
        runsFor: away.runsFor + result.awayRuns,
        oversFor: away.oversFor + result.awayOvers,
        runsAgainst: away.runsAgainst + result.homeRuns,
        oversAgainst: away.oversAgainst + result.homeOvers,
      );
    }

    final sorted = rows.values.toList();
    _applyTieBreakers(sorted, tournament, fixtures, byFixture);
    return sorted;
  }

  /// PRD §8.1: "tie-breakers ordered list: points->H2H->NRR->toss of
  /// coin." Points is the primary sort key; H2H only resolves a
  /// head-to-head tie between exactly two teams that have played each
  /// other (a 3+-way tie falls through to NRR, flagged simplification);
  /// toss-of-coin has no real coin-flip mechanism here, so a stable
  /// id-order stands in as the final, documented tiebreak.
  void _applyTieBreakers(
    List<StandingsRow> rows,
    Tournament tournament,
    List<Fixture> fixtures,
    Map<String, MatchResult> byFixture,
  ) {
    rows.sort((a, b) {
      for (final tieBreaker in tournament.tieBreakerOrder) {
        final cmp = switch (tieBreaker) {
          TieBreaker.points => b.points.compareTo(a.points),
          TieBreaker.headToHead => _headToHeadCompare(
            a,
            b,
            fixtures,
            byFixture,
          ),
          TieBreaker.nrr => b.nrr.compareTo(a.nrr),
          TieBreaker.tossOfCoin => a.registrationId.compareTo(b.registrationId),
        };
        if (cmp != 0) return cmp;
      }
      return 0;
    });
  }

  int _headToHeadCompare(
    StandingsRow a,
    StandingsRow b,
    List<Fixture> fixtures,
    Map<String, MatchResult> byFixture,
  ) {
    final fixture = fixtures
        .where(
          (f) =>
              (f.homeRegistrationId == a.registrationId &&
                  f.awayRegistrationId == b.registrationId) ||
              (f.homeRegistrationId == b.registrationId &&
                  f.awayRegistrationId == a.registrationId),
        )
        .firstOrNull;
    if (fixture == null) return 0;
    final result = byFixture[fixture.id];
    if (result == null || result.winnerRegistrationId == null) return 0;
    if (result.winnerRegistrationId == a.registrationId) return -1;
    if (result.winnerRegistrationId == b.registrationId) return 1;
    return 0;
  }
}

final standingsProvider = NotifierProvider<StandingsNotifier, StandingsState>(
  StandingsNotifier.new,
);
