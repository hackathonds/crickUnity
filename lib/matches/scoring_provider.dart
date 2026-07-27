import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../offline/queued_action.dart';
import '../recognition/personal_bests_provider.dart';
import '../recognition/record_models.dart';
import '../rewards/achievements_provider.dart';
import '../rewards/rewards_models.dart';
import '../rewards/rewards_provider.dart';
import '../rewards/streaks_provider.dart';
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
      scorecardPostedAt: DateTime.now(),
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

  /// PRD §7.14: "both captains + scorer confirm." A dispute (checked
  /// first) always wins -- confirming after a dispute is a no-op until
  /// the dispute is resolved (no resolution flow exists yet, out of
  /// this story's scope per the backlog's own AC, which only covers
  /// confirm-fires-ripple and dispute-freezes-it).
  void confirmScorecard(ConfirmerRole role) {
    if (state.isDisputed) return;
    state = switch (role) {
      ConfirmerRole.composerCaptain => state.copyWith(
        composerCaptainConfirmedScorecard: true,
      ),
      ConfirmerRole.opponentCaptain => state.copyWith(
        opponentCaptainConfirmedScorecard: true,
      ),
      ConfirmerRole.scorer => state.copyWith(scorerConfirmedScorecard: true),
    };
    _maybeFireRipple();
  }

  /// PRD §13 anti-fraud gate: disputing "freezes downstream releases."
  void disputeScorecard(String reason) {
    state = state.copyWith(
      isDisputed: true,
      disputeReason: reason,
      timelineEntries: [
        ...state.timelineEntries,
        'Scorecard disputed: $reason. Both captains notified; '
            'rewards/settlement on hold.',
      ],
    );
  }

  /// PRD §7.14: "auto-confirm 48h if unchallenged."
  void checkAutoConfirm({DateTime Function() now = DateTime.now}) {
    if (!state.canAutoConfirm(now: now)) return;
    state = state.copyWith(
      composerCaptainConfirmedScorecard: true,
      opponentCaptainConfirmedScorecard: true,
      scorerConfirmedScorecard: true,
    );
    _maybeFireRipple();
  }

  /// PRD Pillar 1: "One completed match updates 9 systems
  /// automatically." AC: "the full Match Ripple fires exactly once" --
  /// [InningsState.rippleFired] guards against firing twice even if
  /// confirmation state is touched again afterward. E6-01's coin/XP
  /// engine now genuinely exists -- "Coins/XP/badges awarded" is a real
  /// [RewardsNotifier.awardActions] call, not just a log line, same
  /// quality bar as E5-07's Team Wallet integration. Scoped to the
  /// scorer (the one concrete named identity [InningsState] always
  /// carries -- there's no real multi-account system to award every
  /// participant individually against, flagged). No E5/E6 module exists
  /// for the other 8 ripple lines, so those stay a log of what would
  /// fire.
  void _maybeFireRipple() {
    if (state.rippleFired || state.isDisputed || !state.isFullyConfirmed) {
      return;
    }
    ref
        .read(rewardsProvider.notifier)
        .awardActions(
          _matchEarningActionsFor(state.scorerName),
          contextLabel: '${state.battingTeamName} vs ${state.bowlingTeamName}',
        );
    // PRD §13.2: "Playing streak: consecutive weeks with >=1 cricket
    // activity." A completed, confirmed match is real cricket activity
    // -- same scorer-scoped identity used above (flagged there).
    ref.read(streaksProvider.notifier).recordActivity();
    // E6-04's "Scorer Supreme" badge tier -- same zero-dispute check
    // scorerZeroDisputes above already computed.
    final everCorrected = state.deliveries.any((d) => d.isCorrected);
    if (!everCorrected && state.pendingCorrections.isEmpty) {
      ref.read(achievementsProvider.notifier).recordDisputeFreeMatchScored();
    }
    // E8-04's Personal Bests -- "Achievements & records checked" below
    // is a real check for the scorer's own batting/bowling line, same
    // scoped identity used above (flagged there).
    final scorerBatting = state.batters[state.scorerName];
    final scorerBowling = state.bowlers[state.scorerName];
    ref.read(personalBestsProvider.notifier).checkPerformance({
      if (scorerBatting != null)
        RecordCategory.highestIndividualScore: scorerBatting.runs,
      if (scorerBowling != null)
        RecordCategory.bestBowlingFigures: scorerBowling.wickets,
    });
    state = state.copyWith(
      rippleFired: true,
      rippleLog: const [
        'Player & team stats updated',
        'Rankings recalculated',
        'Expense split finalized & settlements opened',
        'Coins/XP/badges awarded',
        'Attendance written',
        'Achievements & records checked (ground/tournament)',
        'Social summary post drafted',
        'Trust & Sportsmanship updated',
        'AI insights & analytics fed',
      ],
    );
  }

  List<EarningAction> _matchEarningActionsFor(String name) {
    final actions = <EarningAction>[EarningAction.scorerMatch];
    final everCorrected = state.deliveries.any((d) => d.isCorrected);
    if (!everCorrected && state.pendingCorrections.isEmpty) {
      actions.add(EarningAction.scorerZeroDisputes);
    }
    final batting = state.batters[name];
    if (batting != null) {
      actions.add(EarningAction.playVerifiedMatch);
      if (batting.runs >= 100) {
        actions.add(EarningAction.century);
      } else if (batting.runs >= 50) {
        actions.add(EarningAction.fifty);
      }
    }
    final bowling = state.bowlers[name];
    if (bowling != null) {
      if (bowling.wickets >= 5) {
        actions.add(EarningAction.fiveWickets);
      } else if (bowling.wickets >= 3) {
        actions.add(EarningAction.threeWickets);
      }
    }
    if (state.finalMvp == name) {
      actions.add(EarningAction.mvp);
    }
    return actions;
  }

  /// PRD §7.16: "decided by: opposing captain pick (preferred, prompts
  /// them) or auto." Overrides the auto-suggestion whenever the
  /// opposing captain acts -- see [InningsState.finalMvp].
  void pickMvp(String playerName) {
    state = state.copyWith(mvpCaptainPick: playerName);
  }

  /// PRD §7.16: "Awards mint profile entries + coins." Gated on the
  /// scorecard already being confirmed (PRD §13 anti-fraud gate, same
  /// gate the rest of the ripple respects) -- no real Profile module
  /// exists to write into, so minting is a log of what would be written,
  /// same convention as [_maybeFireRipple]'s ripple log. Guarded by
  /// [InningsState.awardsMinted] so it can only fire once.
  void mintAwards() {
    if (state.awardsMinted || !state.rippleFired) return;
    final entries = <String>['${state.finalMvp} awarded MVP (+50 coins)'];
    final bestBatter = state.bestBatterName;
    if (bestBatter != null) {
      entries.add('$bestBatter awarded Best Batter (+20 coins)');
    }
    final bestBowler = state.bestBowlerName;
    if (bestBowler != null) {
      entries.add('$bestBowler awarded Best Bowler (+20 coins)');
    }
    final bestFielder = state.bestFielderName;
    if (bestFielder != null) {
      entries.add('$bestFielder awarded Best Fielder (+20 coins)');
    }
    state = state.copyWith(awardsMinted: true, awardsLog: entries);
  }

  /// PRD §7.8: "scorer quick-edit" of the auto-generated commentary
  /// line for a specific ball -- a prose edit, not a scoring-fact
  /// correction, so no correction-window gating applies.
  void editCommentary(int deliveryIndex, String text) {
    state = state.copyWith(
      deliveries: [
        for (var i = 0; i < state.deliveries.length; i++)
          if (i == deliveryIndex)
            state.deliveries[i].withCommentaryOverride(text)
          else
            state.deliveries[i],
      ],
    );
  }

  /// PRD §7.8: "scorer can add custom notes."
  void addCustomNote(String text) {
    state = state.copyWith(
      customNotes: [
        ...state.customNotes,
        CommentaryNote(
          afterDeliveryIndex: state.deliveries.length - 1,
          text: text,
        ),
      ],
    );
  }
}

final inningsProvider = NotifierProvider<InningsNotifier, InningsState>(
  InningsNotifier.new,
);
