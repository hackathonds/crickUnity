/// PRD §8.5-8.6 (Groups/Knockout): "Group standings roll into knockout
/// seeding automatically per rules; bracket view with tappable slots;
/// 'path to final' view for each team."
///
/// No explicit multi-group split (Group A/B) exists yet -- this story
/// treats groupsPlusKnockout tournaments as a single group whose
/// standings (E10-04) seed the bracket, flagged as a simplification
/// pending a real multi-group model. Pure-knockout tournaments seed
/// directly by registration order (no separate seeding-input UI is
/// named in the backlog line beyond "brackets + seeding").
library;

/// Standard single-elimination bracket seeding order (e.g. for 8:
/// 1v8, 4v5, 2v7, 3v6) -- ensures the top seeds can only meet in later
/// rounds. [n] must be a power of two.
List<int> seedSlotOrder(int n) {
  if (n == 1) return [1];
  final prev = seedSlotOrder(n ~/ 2);
  final result = <int>[];
  for (final s in prev) {
    result.add(s);
    result.add(n + 1 - s);
  }
  return result;
}

int nextPowerOfTwo(int n) {
  var size = 1;
  while (size < n) {
    size *= 2;
  }
  return size;
}

class BracketMatch {
  final String id;
  final String tournamentId;
  final int round; // 0-indexed; 0 = first round
  final int slotIndex; // position within the round
  final String? teamAId;
  final String? teamAName;
  final String? teamBId;
  final String? teamBName;
  final String? winnerId;

  const BracketMatch({
    required this.id,
    required this.tournamentId,
    required this.round,
    required this.slotIndex,
    this.teamAId,
    this.teamAName,
    this.teamBId,
    this.teamBName,
    this.winnerId,
  });

  /// A bye is round 0 only: exactly one seed exists for the pairing
  /// (the other seed number is beyond the real team count), so the
  /// present team advances with no match played.
  bool get isBye => round == 0 && ((teamAId == null) != (teamBId == null));

  bool get isPlayable => teamAId != null && teamBId != null && winnerId == null;

  BracketMatch copyWith({
    String? teamAId,
    String? teamAName,
    String? teamBId,
    String? teamBName,
    String? winnerId,
  }) {
    return BracketMatch(
      id: id,
      tournamentId: tournamentId,
      round: round,
      slotIndex: slotIndex,
      teamAId: teamAId ?? this.teamAId,
      teamAName: teamAName ?? this.teamAName,
      teamBId: teamBId ?? this.teamBId,
      teamBName: teamBName ?? this.teamBName,
      winnerId: winnerId ?? this.winnerId,
    );
  }
}
