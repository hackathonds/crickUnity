import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'match_models.dart';

class MatchesState {
  final List<MatchRecord> matches;

  const MatchesState({this.matches = const []});

  MatchesState copyWith({List<MatchRecord>? matches}) {
    return MatchesState(matches: matches ?? this.matches);
  }
}

/// PRD §7.1: "Creating notifies opponent captain -> Accept/Propose
/// changes (diff view)/Decline. Match is Draft until both accept."
/// PRD §7.3: "Availability poll auto-sent on match confirm (deadline
/// default 24h before start; captain-editable)" -- modeled here as a
/// boolean + computed deadline rather than a real integration with the
/// Availability Matrix module (E3-06), since that provider's shape
/// assumes an existing team roster/squad context this match-creation
/// flow doesn't have.
class MatchesNotifier extends Notifier<MatchesState> {
  @override
  MatchesState build() => const MatchesState();

  String submitMatch({
    required MatchDraft draft,
    required String composerTeamName,
    DateTime Function() now = DateTime.now,
  }) {
    final id = 'match-${now().millisecondsSinceEpoch}';
    state = state.copyWith(
      matches: [
        MatchRecord(
          id: id,
          composerTeamName: composerTeamName,
          draft: draft,
          status: MatchStatus.pendingOpponent,
        ),
        ...state.matches,
      ],
    );
    return id;
  }

  void acceptMatch(String matchId, {DateTime Function() now = DateTime.now}) {
    state = state.copyWith(
      matches: [
        for (final m in state.matches)
          if (m.id == matchId) _confirm(m, now) else m,
      ],
    );
  }

  void declineMatch(String matchId) {
    state = state.copyWith(
      matches: [
        for (final m in state.matches)
          if (m.id == matchId) m.copyWith(status: MatchStatus.declined) else m,
      ],
    );
  }

  void proposeChanges(
    String matchId, {
    String? groundName,
    DateTime? dateTime,
  }) {
    state = state.copyWith(
      matches: [
        for (final m in state.matches)
          if (m.id == matchId)
            m.copyWith(
              status: MatchStatus.changesProposedToComposer,
              proposedGroundName: groundName,
              proposedDateTime: dateTime,
            )
          else
            m,
      ],
    );
  }

  /// AC: "Given opponent proposes a change, Then I see a field-level
  /// diff and one-tap accept." This is that one tap -- it applies every
  /// proposed field at once.
  void acceptProposedChanges(
    String matchId, {
    DateTime Function() now = DateTime.now,
  }) {
    state = state.copyWith(
      matches: [
        for (final m in state.matches)
          if (m.id == matchId)
            _confirm(
              m.copyWith(
                draft: m.draft.copyWith(
                  groundName: m.proposedGroundName,
                  dateTime: m.proposedDateTime,
                ),
                clearProposedGroundName: true,
                clearProposedDateTime: true,
              ),
              now,
            )
          else
            m,
      ],
    );
  }

  MatchRecord _confirm(MatchRecord m, DateTime Function() now) {
    return m.copyWith(
      status: MatchStatus.accepted,
      availabilityPollSent: true,
      availabilityDeadline: m.draft.dateTime.subtract(
        Duration(hours: m.draft.availabilityDeadlineHours),
      ),
    );
  }
}

final matchesProvider = NotifierProvider<MatchesNotifier, MatchesState>(
  MatchesNotifier.new,
);
