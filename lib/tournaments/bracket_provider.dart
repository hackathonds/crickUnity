import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bracket_models.dart';

class BracketState {
  final Map<String, List<BracketMatch>> matchesByTournament;

  const BracketState({this.matchesByTournament = const {}});

  BracketState copyWith({
    Map<String, List<BracketMatch>>? matchesByTournament,
  }) => BracketState(
    matchesByTournament: matchesByTournament ?? this.matchesByTournament,
  );

  List<BracketMatch> forTournament(String tournamentId) =>
      matchesByTournament[tournamentId] ?? const [];
}

/// Backlog E10-05 -- Brackets + seeding engine. See bracket_models.dart's
/// top-of-file note for the exact PRD §8.5-8.6 quote and the
/// single-group simplification this implements.
class BracketNotifier extends Notifier<BracketState> {
  @override
  BracketState build() => const BracketState();

  /// [seededTeams] must already be in seed-rank order (1st seed first).
  void generateBracket(
    String tournamentId,
    List<(String id, String name)> seededTeams,
  ) {
    if (seededTeams.length < 2) return;
    final bracketSize = nextPowerOfTwo(seededTeams.length);
    final slotOrder = seedSlotOrder(bracketSize);
    final numRounds = _log2(bracketSize);

    final matches = <BracketMatch>[];

    // Round 0: pair slots per the standard seeding order; a seed
    // number beyond the real team count means "no such team" (a bye).
    for (var i = 0; i < bracketSize ~/ 2; i++) {
      final seedA = slotOrder[2 * i];
      final seedB = slotOrder[2 * i + 1];
      final teamA = seedA <= seededTeams.length ? seededTeams[seedA - 1] : null;
      final teamB = seedB <= seededTeams.length ? seededTeams[seedB - 1] : null;
      final isBye = (teamA == null) != (teamB == null);
      matches.add(
        BracketMatch(
          id: 'bracket-${tournamentId}_r0_s$i',
          tournamentId: tournamentId,
          round: 0,
          slotIndex: i,
          teamAId: teamA?.$1,
          teamAName: teamA?.$2,
          teamBId: teamB?.$1,
          teamBName: teamB?.$2,
          winnerId: isBye ? (teamA ?? teamB)?.$1 : null,
        ),
      );
    }

    // Later rounds start empty (TBD) -- winners propagate in as
    // earlier rounds are decided.
    for (var round = 1; round < numRounds; round++) {
      final slotsInRound = bracketSize ~/ (1 << (round + 1));
      for (var i = 0; i < slotsInRound; i++) {
        matches.add(
          BracketMatch(
            id: 'bracket-${tournamentId}_r${round}_s$i',
            tournamentId: tournamentId,
            round: round,
            slotIndex: i,
          ),
        );
      }
    }

    state = state.copyWith(
      matchesByTournament: {
        ...state.matchesByTournament,
        tournamentId: matches,
      },
    );

    // Propagate round-0 byes immediately -- they carry a winner but no
    // played match, so the next round must already reflect them.
    for (final match in matches.where((m) => m.round == 0 && m.isBye)) {
      _placeInNextRound(tournamentId, match, match.winnerId!);
    }
  }

  int _log2(int n) {
    var count = 0;
    var value = n;
    while (value > 1) {
      value ~/= 2;
      count++;
    }
    return count;
  }

  /// PRD §8.5-8.6: "bracket view with tappable slots" -- tapping a
  /// playable match records its winner and advances them.
  void recordWinner(
    String tournamentId,
    String matchId,
    String winnerId,
    String winnerName,
  ) {
    final matches = state.forTournament(tournamentId);
    final match = matches.where((m) => m.id == matchId).firstOrNull;
    if (match == null || !match.isPlayable) return;
    final updated = match.copyWith(winnerId: winnerId);
    state = state.copyWith(
      matchesByTournament: {
        ...state.matchesByTournament,
        tournamentId: [
          for (final m in matches)
            if (m.id == matchId) updated else m,
        ],
      },
    );
    _placeInNextRound(tournamentId, updated, winnerId, winnerName: winnerName);
  }

  void _placeInNextRound(
    String tournamentId,
    BracketMatch decidedMatch,
    String winnerId, {
    String? winnerName,
  }) {
    final matches = state.forTournament(tournamentId);
    final nextRound = decidedMatch.round + 1;
    final nextSlot = decidedMatch.slotIndex ~/ 2;
    final target = matches
        .where((m) => m.round == nextRound && m.slotIndex == nextSlot)
        .firstOrNull;
    if (target == null) return; // decidedMatch was the final

    final isTeamA = decidedMatch.slotIndex.isEven;
    final name =
        winnerName ?? decidedMatch.teamAName ?? decidedMatch.teamBName ?? '';
    final updatedTarget = isTeamA
        ? target.copyWith(teamAId: winnerId, teamAName: name)
        : target.copyWith(teamBId: winnerId, teamBName: name);

    state = state.copyWith(
      matchesByTournament: {
        ...state.matchesByTournament,
        tournamentId: [
          for (final m in matches)
            if (m.id == target.id) updatedTarget else m,
        ],
      },
    );
  }

  /// PRD: "'path to final' view for each team" -- every bracket match
  /// this team appears in (as a real slot or eventual TBD opponent),
  /// in round order.
  List<BracketMatch> pathToFinal(String tournamentId, String teamId) {
    return state
        .forTournament(tournamentId)
        .where((m) => m.teamAId == teamId || m.teamBId == teamId)
        .toList()
      ..sort((a, b) => a.round.compareTo(b.round));
  }
}

final bracketProvider = NotifierProvider<BracketNotifier, BracketState>(
  BracketNotifier.new,
);
