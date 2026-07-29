import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'fixture_models.dart';
import 'registration_models.dart';
import 'standings_models.dart';
import 'tournament_models.dart';
import 'tournaments_provider.dart';

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

  Map<String, dynamic> toJson() => {
    'resultsByTournament': {
      for (final entry in resultsByTournament.entries)
        entry.key: [for (final r in entry.value) r.toJson()],
    },
    'scenariosByTournament': {
      for (final entry in scenariosByTournament.entries)
        entry.key: [for (final s in entry.value) s.toJson()],
    },
  };

  factory StandingsState.fromJson(Map<String, dynamic> json) {
    return StandingsState(
      resultsByTournament: {
        for (final entry
            in (json['resultsByTournament'] as Map<String, dynamic>).entries)
          entry.key: [
            for (final r in entry.value as List)
              MatchResult.fromJson(r as Map<String, dynamic>),
          ],
      },
      scenariosByTournament: {
        for (final entry
            in (json['scenariosByTournament'] as Map<String, dynamic>).entries)
          entry.key: [
            for (final s in entry.value as List)
              WhatIfScenario.fromJson(s as Map<String, dynamic>),
          ],
      },
    );
  }
}

/// Backlog E10-04 -- Points table + NRR + what-if calculator engine.
/// See standings_models.dart's top-of-file note for the flagged
/// simplification (results recorded directly, not rippled from live
/// scoring) and the phantom "G.3" citation.
class StandingsNotifier extends PersistedNotifier<StandingsState> {
  @override
  String get persistenceKey => 'standings_v1';

  @override
  StandingsState seed() => const StandingsState();

  @override
  Map<String, dynamic> toJson(StandingsState value) => value.toJson();

  @override
  StandingsState fromJson(Map<String, dynamic> json) =>
      StandingsState.fromJson(json);

  /// PRD §2.12: "cannot change a completed match result without both
  /// captains + scorer acknowledgment (or documented committee
  /// ruling, which is publicly logged)." A result already existing
  /// for this fixture makes this a *change*, not a first entry, so a
  /// [committeeRulingReason] becomes mandatory (only the committee-
  /// ruling path is reachable -- no multi-account ack system exists,
  /// flagged). Returns null on success, or a rejection message.
  String? recordResult(
    String tournamentId,
    String fixtureId, {
    required int homeRuns,
    required double homeOvers,
    required int awayRuns,
    required double awayOvers,
    required String? winnerRegistrationId,
    String? committeeRulingReason,
  }) {
    final isChange = state
        .resultsFor(tournamentId)
        .any((r) => r.fixtureId == fixtureId);
    if (isChange &&
        (committeeRulingReason == null ||
            committeeRulingReason.trim().isEmpty)) {
      return 'Changing a completed result requires a documented committee ruling.';
    }
    _addResult(
      tournamentId,
      MatchResult(
        fixtureId: fixtureId,
        homeRuns: homeRuns,
        homeOvers: homeOvers,
        awayRuns: awayRuns,
        awayOvers: awayOvers,
        winnerRegistrationId: winnerRegistrationId,
        committeeRulingReason: isChange ? committeeRulingReason : null,
      ),
    );
    return null;
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
    ref.read(tournamentsProvider.notifier).markOrganizerActive(tournamentId);
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
  ///
  /// [teams] should include both approved and withdrawn registrations
  /// (not approved-only) so PRD §8 edge cases' withdrawal rule can be
  /// genuinely applied: a withdrawn team's rows still exist here so
  /// "past results stand" credits their opponents correctly; matches
  /// involving them are voided entirely when the rule is
  /// pastResultsVoid.
  List<StandingsRow> computeStandings(
    Tournament tournament,
    List<TeamRegistration> teams,
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
      for (final team in teams)
        team.id: StandingsRow(
          registrationId: team.id,
          teamName: team.teamName,
          isWithdrawn: team.status == RegistrationStatus.withdrawn,
        ),
    };

    for (final fixture in fixtures) {
      final result = byFixture[fixture.id];
      if (result == null) continue;
      final home = rows[fixture.homeRegistrationId];
      final away = rows[fixture.awayRegistrationId];
      if (home == null || away == null) continue;
      if ((home.isWithdrawn || away.isWithdrawn) &&
          tournament.withdrawalRule == WithdrawalRule.pastResultsVoid) {
        continue;
      }

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
        isWithdrawn: home.isWithdrawn,
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
        isWithdrawn: away.isWithdrawn,
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
