import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../teams/availability_matrix_models.dart';
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
          squadNames: mockSquadNames(),
        ),
        ...state.matches,
      ],
    );
    return id;
  }

  /// DS §7-25 / PRD notification table: cancellation is terminal --
  /// struck header + reason banner, no further RSVP action.
  void cancelMatch(String matchId, String reason) {
    state = state.copyWith(
      matches: [
        for (final m in state.matches)
          if (m.id == matchId)
            m.copyWith(status: MatchStatus.cancelled, cancelledReason: reason)
          else
            m,
      ],
    );
  }

  /// A reschedule keeps the match accepted/live but moves its date/time
  /// and clears every existing response, forcing fresh RSVPs.
  void rescheduleMatch(
    String matchId, {
    required DateTime newDateTime,
    required String reason,
  }) {
    state = state.copyWith(
      matches: [
        for (final m in state.matches)
          if (m.id == matchId)
            m.copyWith(
              draft: m.draft.copyWith(dateTime: newDateTime),
              rescheduleReason: reason,
              availabilityResponses: const {},
              availabilityDeadline: newDateTime.subtract(
                Duration(hours: m.draft.availabilityDeadlineHours),
              ),
            )
          else
            m,
      ],
    );
  }

  void respondAvailability(
    String matchId,
    String playerName,
    AvailabilityResponse response,
  ) {
    state = state.copyWith(
      matches: [
        for (final m in state.matches)
          if (m.id == matchId)
            m.copyWith(
              availabilityResponses: {
                ...m.availabilityResponses,
                playerName: response,
              },
            )
          else
            m,
      ],
    );
  }

  /// E17-03 (DS §1.5): the in-app availability-response row's undo
  /// snackbar reverts to no-response, rather than re-showing a second
  /// confirm step.
  void clearAvailabilityResponse(String matchId, String playerName) {
    state = state.copyWith(
      matches: [
        for (final m in state.matches)
          if (m.id == matchId)
            m.copyWith(
              availabilityResponses: {
                for (final entry in m.availabilityResponses.entries)
                  if (entry.key != playerName) entry.key: entry.value,
              },
            )
          else
            m,
      ],
    );
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

  /// AC amendment #3 (PRD §7.1): "'Challenge a friend/team' entry
  /// creates a challenge card the receiver accepts into the wizard." A
  /// challenge is lighter-weight than a Friendly invite -- the receiver
  /// fills in ground/time as part of accepting, in one step, rather
  /// than a blind Accept on a fully sender-authored draft.
  void acceptChallengeWithDetails(
    String matchId, {
    required String groundName,
    required DateTime dateTime,
    DateTime Function() now = DateTime.now,
  }) {
    state = state.copyWith(
      matches: [
        for (final m in state.matches)
          if (m.id == matchId)
            _confirm(
              m.copyWith(
                draft: m.draft.copyWith(
                  groundName: groundName,
                  dateTime: dateTime,
                ),
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

  /// PRD §7.6: "digital coin flip (either captain taps; animation;
  /// result recorded)." This is the "result recorded" step -- the
  /// screen owns the flip animation itself and calls this once it's
  /// done, so the two stay independent (a slow/dropped frame in the
  /// animation never blocks the actual coin-toss outcome).
  String flipCoin(
    String matchId, {
    bool Function() pickComposerWon = _defaultCoinPick,
  }) {
    final match = state.matches.firstWhere((m) => m.id == matchId);
    final winner = pickComposerWon()
        ? match.composerTeamName
        : match.draft.opponentTeamName;
    state = state.copyWith(
      matches: [
        for (final m in state.matches)
          if (m.id == matchId) m.copyWith(pendingTossWinner: winner) else m,
      ],
    );
    return winner;
  }

  void chooseTossDecision(
    String matchId,
    TossDecision decision, {
    DateTime Function() now = DateTime.now,
  }) {
    state = state.copyWith(
      matches: [
        for (final m in state.matches)
          if (m.id == matchId && m.pendingTossWinner != null)
            _recordToss(
              m,
              winningTeamName: m.pendingTossWinner!,
              decision: decision,
              isManual: false,
              now: now,
            )
          else
            m,
      ],
    );
  }

  void recordManualToss(
    String matchId, {
    required String winningTeamName,
    required TossDecision decision,
    DateTime Function() now = DateTime.now,
  }) {
    state = state.copyWith(
      matches: [
        for (final m in state.matches)
          if (m.id == matchId)
            _recordToss(
              m,
              winningTeamName: winningTeamName,
              decision: decision,
              isManual: true,
              now: now,
            )
          else
            m,
      ],
    );
  }

  MatchRecord _recordToss(
    MatchRecord m, {
    required String winningTeamName,
    required TossDecision decision,
    required bool isManual,
    required DateTime Function() now,
  }) {
    return m.copyWith(
      clearPendingTossWinner: true,
      tossResult: TossResult(
        winningTeamName: winningTeamName,
        decision: decision,
        isManual: isManual,
        recordedAt: now(),
      ),
      timelineEntries: [
        ...m.timelineEntries,
        '$winningTeamName won the toss, chose to '
            '${tossDecisionLabels[decision]!.toLowerCase()}.',
      ],
    );
  }

  /// PRD §7.24: "Private match: link-holders must be approved." A guest
  /// who opens a private match's link lands here first -- no-op if
  /// already approved or already pending, so re-opening the link twice
  /// doesn't duplicate the request.
  void requestViewerAccess(String matchId, String viewerName) {
    state = state.copyWith(
      matches: [
        for (final m in state.matches)
          if (m.id == matchId &&
              !m.approvedViewerNames.contains(viewerName) &&
              !m.pendingViewerRequests.contains(viewerName))
            m.copyWith(
              pendingViewerRequests: [...m.pendingViewerRequests, viewerName],
            )
          else
            m,
      ],
    );
  }

  void approveViewerAccess(String matchId, String viewerName) {
    state = state.copyWith(
      matches: [
        for (final m in state.matches)
          if (m.id == matchId)
            m.copyWith(
              pendingViewerRequests: [
                for (final n in m.pendingViewerRequests)
                  if (n != viewerName) n,
              ],
              approvedViewerNames: [...m.approvedViewerNames, viewerName],
            )
          else
            m,
      ],
    );
  }

  void denyViewerAccess(String matchId, String viewerName) {
    state = state.copyWith(
      matches: [
        for (final m in state.matches)
          if (m.id == matchId)
            m.copyWith(
              pendingViewerRequests: [
                for (final n in m.pendingViewerRequests)
                  if (n != viewerName) n,
              ],
            )
          else
            m,
      ],
    );
  }

  /// PRD §2.6: "Cannot score a match they are playing in (system
  /// blocks; override only if both captains approve -- flagged
  /// 'self-scored, reduced verification weight')." The flag itself
  /// (not modeled here -- it lives entirely on this record, separate
  /// from the independent live-scoring [InningsState] stack) survives
  /// approval; only the block is lifted.
  void approveSelfScoringOverride(
    String matchId, {
    required bool asComposerCaptain,
  }) {
    state = state.copyWith(
      matches: [
        for (final m in state.matches)
          if (m.id == matchId)
            m.copyWith(
              composerCaptainApprovedSelfScoring: asComposerCaptain
                  ? true
                  : m.composerCaptainApprovedSelfScoring,
              opponentCaptainApprovedSelfScoring: !asComposerCaptain
                  ? true
                  : m.opponentCaptainApprovedSelfScoring,
            )
          else
            m,
      ],
    );
  }

  /// PRD §2.7: "cannot umpire a match involving their own active team;
  /// conflict flag; both captains must waive."
  void waiveUmpireConflict(String matchId, {required bool asComposerCaptain}) {
    state = state.copyWith(
      matches: [
        for (final m in state.matches)
          if (m.id == matchId)
            m.copyWith(
              composerCaptainWaivedUmpireConflict: asComposerCaptain
                  ? true
                  : m.composerCaptainWaivedUmpireConflict,
              opponentCaptainWaivedUmpireConflict: !asComposerCaptain
                  ? true
                  : m.opponentCaptainWaivedUmpireConflict,
            )
          else
            m,
      ],
    );
  }
}

bool _defaultCoinPick() => Random().nextBool();

final matchesProvider = NotifierProvider<MatchesNotifier, MatchesState>(
  MatchesNotifier.new,
);
