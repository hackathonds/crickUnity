import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tournament_models.dart';

class TournamentsState {
  final List<Tournament> tournaments;
  final Tournament draft;

  const TournamentsState({this.tournaments = const [], required this.draft});

  TournamentsState copyWith({
    List<Tournament>? tournaments,
    Tournament? draft,
  }) {
    return TournamentsState(
      tournaments: tournaments ?? this.tournaments,
      draft: draft ?? this.draft,
    );
  }

  Tournament? tournamentById(String id) {
    for (final t in tournaments) {
      if (t.id == id) return t;
    }
    return null;
  }
}

/// Backlog E10-01 -- Tournament creation wizard engine. See
/// tournament_models.dart's top-of-file note for the exact PRD §8.1
/// wizard steps and the two creation-time-mandatory pre-declared rules.
class TournamentsNotifier extends Notifier<TournamentsState> {
  @override
  TournamentsState build() => TournamentsState(draft: Tournament(id: _newId()));

  static String _newId({DateTime Function() now = DateTime.now}) =>
      'tournament-${now().microsecondsSinceEpoch}';

  void updateDraft(Tournament Function(Tournament) transform) {
    state = state.copyWith(draft: transform(state.draft));
  }

  void resetDraft() {
    state = state.copyWith(draft: Tournament(id: _newId()));
  }

  /// PRD §8.1: "Publish (Draft->Published; edits post-publish are
  /// versioned & notify registrants)." No registrants exist yet
  /// (Registration is E10-02) so the notify-on-edit half of this rule
  /// has nothing to fire against yet -- flagged as E10-02's job once a
  /// registrant list exists.
  ///
  /// Returns null on success, or a validation message if
  /// [Tournament.canPublish] rejects the draft (this should be
  /// unreachable from the UI, which disables Publish until canPublish
  /// is true, but the notifier itself never trusts an unchecked flag).
  String? publish() {
    if (!state.draft.canPublish) {
      return 'Tie-breaker order, rain-final rule, and withdrawal rule must all be set before publishing.';
    }
    final published = state.draft.copyWith(
      status: TournamentStatus.published,
      publishedVersion: 1,
    );
    state = state.copyWith(
      tournaments: [...state.tournaments, published],
      draft: Tournament(id: _newId()),
    );
    return null;
  }

  /// PRD §8.2: entry-fee escrow credit on registration approval. Not a
  /// content edit, so it does not bump [Tournament.publishedVersion]
  /// the way [editPublished] does.
  void addToEscrow(String tournamentId, int amount) {
    state = state.copyWith(
      tournaments: [
        for (final t in state.tournaments)
          if (t.id == tournamentId)
            t.copyWith(escrowedAmount: t.escrowedAmount + amount)
          else
            t,
      ],
    );
  }

  /// Post-publish edits are versioned per PRD §8.1.
  void editPublished(
    String tournamentId,
    Tournament Function(Tournament) transform,
  ) {
    state = state.copyWith(
      tournaments: [
        for (final t in state.tournaments)
          if (t.id == tournamentId)
            transform(t).copyWith(publishedVersion: t.publishedVersion + 1)
          else
            t,
      ],
    );
  }
}

final tournamentsProvider =
    NotifierProvider<TournamentsNotifier, TournamentsState>(
      TournamentsNotifier.new,
    );
