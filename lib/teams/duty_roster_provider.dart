import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'duty_roster_models.dart';

class ClaimResult {
  final String? error;
  final int coinsGranted;
  final int xpGranted;

  const ClaimResult({this.error, this.coinsGranted = 0, this.xpGranted = 0});

  bool get succeeded => error == null;
}

class DutyRosterState {
  final List<DutySlot> slots;

  const DutyRosterState({this.slots = const []});

  DutyRosterState copyWith({List<DutySlot>? slots}) {
    return DutyRosterState(slots: slots ?? this.slots);
  }

  Map<String, dynamic> toJson() => {
    'slots': slots.map((s) => s.toJson()).toList(),
  };

  factory DutyRosterState.fromJson(Map<String, dynamic> json) {
    return DutyRosterState(
      slots: [
        for (final s in (json['slots'] as List? ?? const []))
          DutySlot.fromJson(s as Map<String, dynamic>),
      ],
    );
  }
}

/// DS §7 screen 19 (Duty Roster): "Duty slots show claimant avatar or
/// [Claim]." DS's UI shows a direct self-claim action -- PRD's "logged
/// by captain" wording is read as the captain having originally posted
/// the slot, not a separate approval step before the reward grants.
class DutyRosterNotifier extends PersistedNotifier<DutyRosterState> {
  @override
  String get persistenceKey => 'duty_roster_v1';

  @override
  DutyRosterState seed() => DutyRosterState(slots: mockDutySlots());

  @override
  Map<String, dynamic> toJson(DutyRosterState value) => value.toJson();

  @override
  DutyRosterState fromJson(Map<String, dynamic> json) =>
      DutyRosterState.fromJson(json);

  ClaimResult claim(String slotId, String memberName) {
    final slot = state.slots.firstWhere((s) => s.id == slotId);
    if (slot.claimantName != null) {
      return const ClaimResult(error: 'Already claimed.');
    }
    state = state.copyWith(
      slots: [
        for (final s in state.slots)
          if (s.id == slotId) s.copyWith(claimantName: memberName) else s,
      ],
    );
    return const ClaimResult(
      coinsGranted: volunteerDutyCoins,
      xpGranted: volunteerDutyXp,
    );
  }

  void unclaim(String slotId) {
    state = state.copyWith(
      slots: [
        for (final s in state.slots)
          if (s.id == slotId) s.copyWith(clearClaimant: true) else s,
      ],
    );
  }
}

final dutyRosterProvider =
    NotifierProvider<DutyRosterNotifier, DutyRosterState>(
      DutyRosterNotifier.new,
    );
