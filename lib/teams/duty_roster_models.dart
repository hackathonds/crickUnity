/// PRD §13.1 earning table: "Volunteer (drinks/kit duty logged by
/// captain) | 5 coins | 10 XP | Volunteer bonus."
const int volunteerDutyCoins = 5;
const int volunteerDutyXp = 10;

class DutySlot {
  final String id;
  final String label;
  final String? claimantName;

  const DutySlot({required this.id, required this.label, this.claimantName});

  DutySlot copyWith({String? claimantName, bool clearClaimant = false}) {
    return DutySlot(
      id: id,
      label: label,
      claimantName: clearClaimant ? null : (claimantName ?? this.claimantName),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'claimantName': claimantName,
  };

  factory DutySlot.fromJson(Map<String, dynamic> json) {
    return DutySlot(
      id: json['id'] as String,
      label: json['label'] as String,
      claimantName: json['claimantName'] as String?,
    );
  }
}

/// Mock data for the debug demo and tests -- no backend duty-roster
/// service exists yet.
List<DutySlot> mockDutySlots() => const [
  DutySlot(
    id: 'duty-1',
    label: 'Drinks -- Sunday match',
    claimantName: 'Priya Nair',
  ),
  DutySlot(id: 'duty-2', label: 'Kit bag -- Sunday match'),
  DutySlot(id: 'duty-3', label: 'Scorebook -- Sunday match'),
];
