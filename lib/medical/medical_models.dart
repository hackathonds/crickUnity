/// DS §11.16 (Safety & identity flows): "Medical & emergency card:
/// Profile -> private section; form (blood group select, allergies
/// tags, conditions, emergency contact); consent screen states exactly
/// who sees it and when (event-window reveal), toggle per team;
/// captain's event-day view: roster menu -> Medical (only within
/// window, view-only, watermarked 'visible during event'). Injury log:
/// add-injury sheet (type, date, notes private) -> auto-Injured
/// availability + streak-shield note; return-to-play checklist screen
/// (self-check rows -> confirm) reactivates availability."
///
/// Backlog cites this story against "G.13" -- no Appendix G exists
/// anywhere in the frozen PRD (only A and B are real, established
/// earlier this session), flagged rather than guessed at.
library;

enum BloodGroup {
  aPositive,
  aNegative,
  bPositive,
  bNegative,
  abPositive,
  abNegative,
  oPositive,
  oNegative,
}

const Map<BloodGroup, String> bloodGroupLabels = {
  BloodGroup.aPositive: 'A+',
  BloodGroup.aNegative: 'A-',
  BloodGroup.bPositive: 'B+',
  BloodGroup.bNegative: 'B-',
  BloodGroup.abPositive: 'AB+',
  BloodGroup.abNegative: 'AB-',
  BloodGroup.oPositive: 'O+',
  BloodGroup.oNegative: 'O-',
};

class MedicalCard {
  final BloodGroup? bloodGroup;
  final List<String> allergies;
  final List<String> conditions;
  final String emergencyContactName;
  final String emergencyContactPhone;

  /// "toggle per team" -- which of the player's teams may reveal this
  /// card during an event window.
  final Map<String, bool> teamRevealToggles;

  const MedicalCard({
    this.bloodGroup,
    this.allergies = const [],
    this.conditions = const [],
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.teamRevealToggles = const {},
  });

  MedicalCard copyWith({
    BloodGroup? bloodGroup,
    List<String>? allergies,
    List<String>? conditions,
    String? emergencyContactName,
    String? emergencyContactPhone,
    Map<String, bool>? teamRevealToggles,
  }) {
    return MedicalCard(
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      conditions: conditions ?? this.conditions,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      teamRevealToggles: teamRevealToggles ?? this.teamRevealToggles,
    );
  }
}

class InjuryEntry {
  final String id;
  final String type;
  final DateTime date;
  final String notes;
  final bool active;

  const InjuryEntry({
    required this.id,
    required this.type,
    required this.date,
    required this.notes,
    this.active = true,
  });

  InjuryEntry copyWith({bool? active}) {
    return InjuryEntry(
      id: id,
      type: type,
      date: date,
      notes: notes,
      active: active ?? this.active,
    );
  }
}

/// "return-to-play checklist screen (self-check rows -> confirm)."
/// PRD/DS name no specific checklist items -- flagged judgment call:
/// standard graduated-return self-check questions.
const List<String> returnToPlayChecklistRows = [
  'Pain-free during light activity',
  'Full range of motion restored',
  'Cleared by a medical professional (if applicable)',
  'Comfortable with match-intensity movement',
];
