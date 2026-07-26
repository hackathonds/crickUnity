import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../offline/queued_action.dart';
import 'scoring_models.dart';

/// PRD §7.7 / DS §7-27 -- E4-04's full 4-way split (see
/// scoring_models.dart for the exact scope of each sub-task), plus
/// E4-06's undo/correction-window rules and E4-08's offline-sync
/// queueing layered on top. `deliveries` and `pendingCorrections` are
/// the only mutable state; every score/stat is a derived getter on
/// [InningsState].
class InningsNotifier extends Notifier<InningsState> {
  int _ballCount = 0;

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
      scorerName: 'Deepak Sharma',
    );
  }

  void recordRun(int runs) {
    final delivery = Delivery(bowlerName: state.currentBowlerName, runs: runs);
    state = state.copyWith(
      deliveries: [...state.deliveries, delivery],
      eligibleShotCounter: delivery.isEligibleForWagonInput
          ? state.eligibleShotCounter + 1
          : state.eligibleShotCounter,
    );
    _queueSync('$runs run${runs == 1 ? '' : 's'}');
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
    _queueSync('Wicket (${dismissalTypeLabels[dismissalType]})');
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
    _queueSync(extraTypeLabels[type]!);
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

  /// PRD §7.7: "Rain/Delay button pauses match clock, notifies
  /// followers, offers revised-overs calculator." Pausing/notifying
  /// followers is the screen's job (a toast, same as Toss's broadcast);
  /// this just records that scoring is paused and why.
  void startInterruption(String reason) {
    state = state.copyWith(isPaused: true, interruptionReason: reason);
  }

  /// AC: "resuming recomputes RRR strip" -- [revisedOvers] (null keeps
  /// the original format overs) flows straight into
  /// [InningsState.effectiveTotalOvers], which every rate getter reads
  /// fresh, so nothing needs to be explicitly "recomputed" here.
  void resumeFromInterruption({int? revisedOvers}) {
    state = state.copyWith(
      isPaused: false,
      clearInterruptionReason: true,
      revisedOversForInnings: revisedOvers ?? state.revisedOversForInnings,
    );
  }

  /// No 2-innings match model exists yet -- setting a chase target is a
  /// standalone action rather than part of a real innings-transition
  /// flow, just enough to make requiredRunRate demonstrable.
  void setTarget(int target) {
    state = state.copyWith(targetRuns: target);
  }

  /// PRD §7.7 offline UX: "scoring continues seamlessly ... banner
  /// 'Saving locally -- will sync'." The ball is already applied to
  /// local state above regardless of connectivity -- this just enqueues
  /// the mock "sync to server" side of it through the existing E0-06
  /// offline-queue infra, which already auto-flushes every pending
  /// action the moment [isOnlineProvider] flips back to true. No real
  /// backend exists to actually sync to, so the "sync" is a short
  /// simulated delay that always succeeds.
  void _queueSync(String label) {
    _ballCount++;
    ref
        .read(queuedActionsProvider.notifier)
        .submit(
          label: 'Ball $_ballCount: $label',
          isMoneyAction: false,
          perform: () async {
            await Future.delayed(const Duration(milliseconds: 300));
          },
        );
  }

  /// DS §11.7: "tap sector to log" -- also counts as re-engaging, so the
  /// prompt returns to full frequency (AC's throttle is specifically for
  /// a scorer who keeps *ignoring* it).
  void logWagonSector(int deliveryIndex, WagonSector sector) {
    state = state.copyWith(
      deliveries: [
        for (var i = 0; i < state.deliveries.length; i++)
          if (i == deliveryIndex)
            state.deliveries[i].withWagonSector(sector)
          else
            state.deliveries[i],
      ],
      consecutiveIgnoredWagonPrompts: 0,
      wagonPromptDivisor: 1,
    );
  }

  static const int _wagonIgnoreThreshold = 10;
  static const int _wagonThrottledDivisor = 4;

  /// AC: "ignoring the ghost 10 times in a row auto-reduces its prompt
  /// frequency (respect the scorer)."
  void ignoreWagonPrompt() {
    final ignoredCount = state.consecutiveIgnoredWagonPrompts + 1;
    if (ignoredCount >= _wagonIgnoreThreshold) {
      state = state.copyWith(
        consecutiveIgnoredWagonPrompts: 0,
        wagonPromptDivisor: _wagonThrottledDivisor,
      );
    } else {
      state = state.copyWith(consecutiveIgnoredWagonPrompts: ignoredCount);
    }
  }

  /// DS §11.7: "Scorer handover: Console overflow -> Handover -> picker
  /// (present members) -> both-captains approve sheet ... console
  /// transfers with toast; audit line in match timeline."
  void requestHandover(String newScorerName) {
    state = state.copyWith(
      pendingHandoverToName: newScorerName,
      composerCaptainApprovedHandover: false,
      opponentCaptainApprovedHandover: false,
    );
  }

  void approveHandover({required bool asComposerCaptain}) {
    final composerApproved =
        asComposerCaptain || state.composerCaptainApprovedHandover;
    final opponentApproved =
        !asComposerCaptain || state.opponentCaptainApprovedHandover;
    if (composerApproved && opponentApproved) {
      final newScorer = state.pendingHandoverToName!;
      state = state.copyWith(
        scorerName: newScorer,
        clearPendingHandoverToName: true,
        composerCaptainApprovedHandover: false,
        opponentCaptainApprovedHandover: false,
        timelineEntries: [
          ...state.timelineEntries,
          'Scoring handed over from ${state.scorerName} to $newScorer.',
        ],
      );
    } else {
      state = state.copyWith(
        composerCaptainApprovedHandover: composerApproved,
        opponentCaptainApprovedHandover: opponentApproved,
      );
    }
  }
}

final inningsProvider = NotifierProvider<InningsNotifier, InningsState>(
  InningsNotifier.new,
);
