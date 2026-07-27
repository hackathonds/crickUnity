import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fixtures_provider.dart';
import 'standings_provider.dart';
import 'stats_models.dart';

class StatsState {
  final Map<String, List<PlayerTournamentStat>> statsByTournament;
  final Map<String, StatsQualification> qualificationsByTournament;
  final Map<String, List<TournamentAward>> awardsByTournament;
  final Map<String, List<String>> championHistoryByTournament;

  const StatsState({
    this.statsByTournament = const {},
    this.qualificationsByTournament = const {},
    this.awardsByTournament = const {},
    this.championHistoryByTournament = const {},
  });

  StatsState copyWith({
    Map<String, List<PlayerTournamentStat>>? statsByTournament,
    Map<String, StatsQualification>? qualificationsByTournament,
    Map<String, List<TournamentAward>>? awardsByTournament,
    Map<String, List<String>>? championHistoryByTournament,
  }) {
    return StatsState(
      statsByTournament: statsByTournament ?? this.statsByTournament,
      qualificationsByTournament:
          qualificationsByTournament ?? this.qualificationsByTournament,
      awardsByTournament: awardsByTournament ?? this.awardsByTournament,
      championHistoryByTournament:
          championHistoryByTournament ?? this.championHistoryByTournament,
    );
  }

  List<String> championHistoryFor(String tournamentId) =>
      championHistoryByTournament[tournamentId] ?? const [];

  List<PlayerTournamentStat> statsFor(String tournamentId) =>
      statsByTournament[tournamentId] ?? const [];

  StatsQualification qualificationFor(String tournamentId) =>
      qualificationsByTournament[tournamentId] ?? const StatsQualification();

  List<TournamentAward> awardsFor(String tournamentId) =>
      awardsByTournament[tournamentId] ?? const [];

  List<PlayerTournamentStat> orangeList(String tournamentId) =>
      [...statsFor(tournamentId)]..sort((a, b) => b.runs.compareTo(a.runs));

  List<PlayerTournamentStat> purpleList(String tournamentId) =>
      [...statsFor(tournamentId)]
        ..sort((a, b) => b.wickets.compareTo(a.wickets));

  List<PlayerTournamentStat> bestStrikeRateList(String tournamentId) {
    final qualification = qualificationFor(tournamentId);
    return statsFor(tournamentId)
        .where((s) => s.ballsFaced >= qualification.minBallsFacedForStrikeRate)
        .toList()
      ..sort((a, b) => b.strikeRate.compareTo(a.strikeRate));
  }

  List<PlayerTournamentStat> bestEconomyList(String tournamentId) {
    final qualification = qualificationFor(tournamentId);
    return statsFor(tournamentId)
        .where((s) => s.oversBowled >= qualification.minOversBowledForEconomy)
        .toList()
      ..sort((a, b) => a.economy.compareTo(b.economy));
  }

  /// "Best figures" = most wickets, fewest runs conceded as tiebreak.
  List<PlayerTournamentStat> bestFiguresList(String tournamentId) =>
      [...statsFor(tournamentId)]..sort((a, b) {
        final cmp = b.wickets.compareTo(a.wickets);
        return cmp != 0 ? cmp : a.runsConceded.compareTo(b.runsConceded);
      });
}

/// Backlog E10-08 -- Stats hub + awards + records engine. See
/// stats_models.dart's top-of-file note for the exact PRD §8.10-8.12
/// quote and the flagged per-fixture entry simplification.
class StatsNotifier extends Notifier<StatsState> {
  @override
  StatsState build() => const StatsState();

  void recordPlayerStat(
    String tournamentId,
    String playerName,
    String teamName, {
    int runs = 0,
    int ballsFaced = 0,
    int wickets = 0,
    int runsConceded = 0,
    double oversBowled = 0,
    DateTime Function() now = DateTime.now,
  }) {
    final existing = state.statsFor(tournamentId);
    final current = existing
        .where((s) => s.playerName == playerName)
        .firstOrNull;
    final updated = PlayerTournamentStat(
      id: current?.id ?? 'stat-${now().microsecondsSinceEpoch}',
      tournamentId: tournamentId,
      playerName: playerName,
      teamName: teamName,
      runs: (current?.runs ?? 0) + runs,
      ballsFaced: (current?.ballsFaced ?? 0) + ballsFaced,
      wickets: (current?.wickets ?? 0) + wickets,
      runsConceded: (current?.runsConceded ?? 0) + runsConceded,
      oversBowled: (current?.oversBowled ?? 0) + oversBowled,
    );
    state = state.copyWith(
      statsByTournament: {
        ...state.statsByTournament,
        tournamentId: [
          for (final s in existing)
            if (s.playerName != playerName) s,
          updated,
        ],
      },
    );
  }

  void setQualification(
    String tournamentId, {
    int? minBallsFacedForStrikeRate,
    int? minOversBowledForEconomy,
  }) {
    final current = state.qualificationFor(tournamentId);
    state = state.copyWith(
      qualificationsByTournament: {
        ...state.qualificationsByTournament,
        tournamentId: current.copyWith(
          minBallsFacedForStrikeRate: minBallsFacedForStrikeRate,
          minOversBowledForEconomy: minOversBowledForEconomy,
        ),
      },
    );
  }

  /// PRD: "Awards page: auto-computed nominees." Top of each list
  /// becomes the nominee; Player of the Tournament is a flagged
  /// judgment call (no formula given) using most runs as the proxy.
  void generateNominees(String tournamentId) {
    final orange = state.orangeList(tournamentId);
    final purple = state.purpleList(tournamentId);
    final bestSR = state.bestStrikeRateList(tournamentId);
    final bestEcon = state.bestEconomyList(tournamentId);
    final bestFigures = state.bestFiguresList(tournamentId);

    final nominees = <AwardCategory, PlayerTournamentStat?>{
      AwardCategory.mostRuns: orange.firstOrNull,
      AwardCategory.mostWickets: purple.firstOrNull,
      AwardCategory.bestStrikeRate: bestSR.firstOrNull,
      AwardCategory.bestEconomy: bestEcon.firstOrNull,
      AwardCategory.bestFigures: bestFigures.firstOrNull,
      AwardCategory.playerOfTheTournament: orange.firstOrNull,
    };

    final awards = [
      for (final entry in nominees.entries)
        if (entry.value != null)
          TournamentAward(
            id: 'award-${tournamentId}_${entry.key.name}',
            tournamentId: tournamentId,
            category: entry.key,
            nomineeName: entry.value!.playerName,
          ),
    ];
    state = state.copyWith(
      awardsByTournament: {...state.awardsByTournament, tournamentId: awards},
    );
  }

  /// PRD §8.16: "evergreen tournament records ('Highest total in
  /// Monsoon Cup history') -- auto-checked every confirmed match."
  /// Genuinely computed from the real E10-04 recorded match results
  /// and E10-03 fixtures, not a mocked number.
  (String teamName, int runs)? highestTeamTotalRecord(String tournamentId) {
    final results = ref.read(standingsProvider).resultsFor(tournamentId);
    final fixtures = ref.read(fixturesProvider).forTournament(tournamentId);
    final fixtureById = {for (final f in fixtures) f.id: f};
    (String, int)? best;
    for (final result in results) {
      final fixture = fixtureById[result.fixtureId];
      if (fixture == null) continue;
      if (best == null || result.homeRuns > best.$2) {
        best = (fixture.homeTeamName, result.homeRuns);
      }
      if (result.awayRuns > best.$2) {
        best = (fixture.awayTeamName, result.awayRuns);
      }
    }
    return best;
  }

  /// PRD §8.16: "Multi-season container: past editions list, hall of
  /// champions." No real multi-year edition/season model exists yet
  /// (flagged) -- the organizer logs past champions manually.
  void logChampion(String tournamentId, String entry) {
    state = state.copyWith(
      championHistoryByTournament: {
        ...state.championHistoryByTournament,
        tournamentId: [...state.championHistoryFor(tournamentId), entry],
      },
    );
  }

  /// PRD: "organizer confirms winners at closing; awards mint to
  /// profiles with tournament provenance."
  void confirmAward(
    String tournamentId,
    String awardId, {
    DateTime Function() now = DateTime.now,
  }) {
    final awards = state.awardsFor(tournamentId);
    state = state.copyWith(
      awardsByTournament: {
        ...state.awardsByTournament,
        tournamentId: [
          for (final a in awards)
            if (a.id == awardId)
              a.copyWith(confirmed: true, confirmedAt: now())
            else
              a,
        ],
      },
    );
  }
}

final statsProvider = NotifierProvider<StatsNotifier, StatsState>(
  StatsNotifier.new,
);
