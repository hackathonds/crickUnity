import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'scoring_models.dart';

/// PRD §7.7 / DS §7-27 -- sub-task 1/4 of E4-04 (see scoring_models.dart
/// for the exact split boundaries). `deliveries` is the only mutable
/// state; every score/stat is a derived getter on [InningsState], so
/// undo is simply "drop the last delivery."
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

  void recordWicket({
    required DismissalType dismissalType,
    String? fielderName,
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

  void undo() {
    if (state.deliveries.isEmpty) return;
    state = state.copyWith(
      deliveries: state.deliveries.sublist(0, state.deliveries.length - 1),
    );
  }
}

final inningsProvider = NotifierProvider<InningsNotifier, InningsState>(
  InningsNotifier.new,
);
