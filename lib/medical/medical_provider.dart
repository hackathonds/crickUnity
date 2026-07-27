import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'medical_models.dart';

class MedicalState {
  final MedicalCard card;
  final List<InjuryEntry> injuries;
  final Set<int> returnToPlayChecked;

  const MedicalState({
    this.card = const MedicalCard(),
    this.injuries = const [],
    this.returnToPlayChecked = const {},
  });

  bool get hasActiveInjury => injuries.any((i) => i.active);

  /// PRD/DS name no streak-shield formula -- flagged: an active injury
  /// shields the player's activity streak from breaking while they
  /// can't play, same "flagged judgment call" convention as other
  /// unspecified formulas this session.
  bool get streakShieldActive => hasActiveInjury;

  MedicalState copyWith({
    MedicalCard? card,
    List<InjuryEntry>? injuries,
    Set<int>? returnToPlayChecked,
  }) {
    return MedicalState(
      card: card ?? this.card,
      injuries: injuries ?? this.injuries,
      returnToPlayChecked: returnToPlayChecked ?? this.returnToPlayChecked,
    );
  }
}

/// No real per-player medical-record persistence or cross-module
/// availability-override wiring exists (the real Availability Matrix,
/// teams/availability_matrix_models.dart, only ever models yes/maybe/no
/// responses, never an "Injured" auto-override) -- flagged, same
/// convention as every other missing-backend gap this session.
class MedicalNotifier extends Notifier<MedicalState> {
  @override
  MedicalState build() => const MedicalState();

  void updateCard({
    BloodGroup? bloodGroup,
    List<String>? allergies,
    List<String>? conditions,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) {
    state = state.copyWith(
      card: state.card.copyWith(
        bloodGroup: bloodGroup,
        allergies: allergies,
        conditions: conditions,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
      ),
    );
  }

  void setTeamReveal(String teamName, bool allowed) {
    state = state.copyWith(
      card: state.card.copyWith(
        teamRevealToggles: {...state.card.teamRevealToggles, teamName: allowed},
      ),
    );
  }

  /// DS: "add-injury sheet ... -> auto-Injured availability +
  /// streak-shield note."
  void addInjury({
    required String type,
    required DateTime date,
    required String notes,
  }) {
    state = state.copyWith(
      injuries: [
        InjuryEntry(
          id: 'injury-${DateTime.now().millisecondsSinceEpoch}',
          type: type,
          date: date,
          notes: notes,
        ),
        ...state.injuries,
      ],
      returnToPlayChecked: const {},
    );
  }

  void toggleReturnToPlayRow(int index) {
    final checked = {...state.returnToPlayChecked};
    checked.contains(index) ? checked.remove(index) : checked.add(index);
    state = state.copyWith(returnToPlayChecked: checked);
  }

  bool get allReturnToPlayChecked =>
      state.returnToPlayChecked.length == returnToPlayChecklistRows.length;

  /// DS: "return-to-play checklist ... confirm reactivates
  /// availability." Resolves every active injury.
  void confirmReturnToPlay() {
    state = state.copyWith(
      injuries: [for (final i in state.injuries) i.copyWith(active: false)],
      returnToPlayChecked: const {},
    );
  }
}

final medicalProvider = NotifierProvider<MedicalNotifier, MedicalState>(
  MedicalNotifier.new,
);
