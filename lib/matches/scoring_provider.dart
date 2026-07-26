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
    return InningsState(
      battingTeamName: 'Riverside Strikers',
      bowlingTeamName: 'Central Warriors',
      battingOrder: order,
      strikerName: order[0],
      nonStrikerName: order[1],
      currentBowlerName: 'Deepak Sharma',
    );
  }

  void recordRun(int runs) {
    state = state.copyWith(
      deliveries: [
        ...state.deliveries,
        Delivery(runs: runs),
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
          runs: 0,
          isWicket: true,
          dismissalType: dismissalType,
          fielderName: fielderName,
          newBatterName: newBatterName,
        ),
      ],
    );
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
