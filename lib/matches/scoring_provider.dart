import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'scoring_models.dart';

/// PRD §7.7 / DS §7-27 -- E4-04's full 4-way split (see
/// scoring_models.dart for the exact scope of each sub-task), plus
/// E4-06's undo/correction-window rules layered on top. `deliveries`
/// and `pendingCorrections` are the only mutable state; every score/
/// stat is a derived getter on [InningsState].
class InningsNotifier extends Notifier<InningsState> {
  @override
  InningsState build() {
    final order = mockBattingOrder();
    final bowlingRoster = mockBowlingRoster();
    return InningsState(
      battingTeamName: 'Riverside Strikers',
      bowlingTeamName: 'Central Warriors',
      battingOrder: order,
      bowlingRoster: bowlingRoster,
      strikerName: order[0],
      nonStrikerName: order[1],
      currentBowlerName: bowlingRoster[0],
      totalOversPerSide: 20,
    );
  }

  void recordRun(int runs) {
    state = state.copyWith(
      deliveries: [
        ...state.deliveries,
        Delivery(bowlerName: state.currentBowlerName, runs: runs),
      ],
    );
  }

  /// [dismissedBatterName] (E4-05, "run-out sub-fields"): defaults to
  /// the striker -- only a run-out can name the non-striker instead.
  void recordWicket({
    required DismissalType dismissalType,
    String? fielderName,
    String? dismissedBatterName,
    required String newBatterName,
  }) {
    state = state.copyWith(
      deliveries: [
        ...state.deliveries,
        Delivery(
          bowlerName: state.currentBowlerName,
          runs: 0,
          isWicket: true,
          dismissalType: dismissalType,
          fielderName: fielderName,
          dismissedBatterName: dismissedBatterName ?? state.currentStriker,
          newBatterName: newBatterName,
        ),
      ],
    );
  }

  /// PRD §7.7 / AC: "Given format says no-ball = 1 run + rebowl, Then
  /// extras honor the match's sub-rules from E4-01" -- [Delivery.extra]
  /// reads [InningsState.subRules] to decide runs and over-legality.
  void recordExtra(ExtraType type, {int additionalRuns = 0}) {
    state = state.copyWith(
      deliveries: [
        ...state.deliveries,
        Delivery.extra(
          bowlerName: state.currentBowlerName,
          type: type,
          additionalRuns: additionalRuns,
          subRules: state.subRules,
        ),
      ],
    );
  }

  /// PRD §7.7: "end-over auto-advance with next-bowler picker (bowler-
  /// overs limits enforced per format rules)." The screen is
  /// responsible for prompting at the right moment (over-end) and only
  /// offering [InningsState.eligibleNextBowlers] -- this just performs
  /// the switch once a valid choice is made.
  void selectNextBowler(String bowlerName) {
    state = state.copyWith(currentBowlerName: bowlerName);
  }

  /// PRD §7.7: "swap-strike" -- a manual override the scorer can tap
  /// any time, independent of the automatic odd-runs/over-end rotation.
  void manualSwapStrike() {
    state = state.copyWith(
      deliveries: [
        ...state.deliveries,
        Delivery.manualSwap(bowlerName: state.currentBowlerName),
      ],
    );
  }

  /// PRD §2.6: "Unlimited undo within current over" -- refuses once the
  /// last delivery belongs to an already-completed over; a correction
  /// for that needs [requestCorrection] instead.
  void undo() {
    if (!state.canUndoFreely) return;
    state = state.copyWith(
      deliveries: state.deliveries.sublist(0, state.deliveries.length - 1),
    );
  }

  /// PRD §2.6: "edit balls within the correction window (last 2 overs
  /// freely; older balls require both captains' acknowledgment)." A
  /// ball still inside the free window corrects immediately; an older
  /// one opens a pending [CorrectionRequest] that only takes effect
  /// once both captains acknowledge it.
  void requestCorrection({
    required int deliveryIndex,
    required int proposedRuns,
    required String reason,
  }) {
    if (state.isWithinFreeCorrectionWindow(deliveryIndex)) {
      _applyCorrection(deliveryIndex, proposedRuns);
      return;
    }
    state = state.copyWith(
      pendingCorrections: [
        ...state.pendingCorrections,
        CorrectionRequest(
          deliveryIndex: deliveryIndex,
          proposedRuns: proposedRuns,
          reason: reason,
        ),
      ],
    );
  }

  void acknowledgeCorrection(
    int deliveryIndex, {
    required bool asComposerCaptain,
  }) {
    final requests = <CorrectionRequest>[];
    for (final request in state.pendingCorrections) {
      if (request.deliveryIndex != deliveryIndex) {
        requests.add(request);
        continue;
      }
      final updated = asComposerCaptain
          ? request.copyWith(composerCaptainAcked: true)
          : request.copyWith(opponentCaptainAcked: true);
      if (updated.isFullyAcked) {
        _applyCorrection(updated.deliveryIndex, updated.proposedRuns);
      } else {
        requests.add(updated);
      }
    }
    state = state.copyWith(pendingCorrections: requests);
  }

  void _applyCorrection(int deliveryIndex, int proposedRuns) {
    state = state.copyWith(
      deliveries: [
        for (var i = 0; i < state.deliveries.length; i++)
          if (i == deliveryIndex)
            state.deliveries[i].correctedTo(proposedRuns)
          else
            state.deliveries[i],
      ],
    );
  }
}

final inningsProvider = NotifierProvider<InningsNotifier, InningsState>(
  InningsNotifier.new,
);
