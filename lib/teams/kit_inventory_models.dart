/// DS §7 screen 21 (Kit Inventory): "Kit rows show custody avatar +
/// [Hand over] flow (both confirm)."
class KitItem {
  final String id;
  final String name;
  final String custodianName;

  /// The proposed next custodian while a hand-over is pending -- null
  /// when there is no hand-over in progress. Custody only actually
  /// transfers once this person confirms receipt.
  final String? pendingRecipient;

  const KitItem({
    required this.id,
    required this.name,
    required this.custodianName,
    this.pendingRecipient,
  });

  KitItem copyWith({
    String? custodianName,
    String? pendingRecipient,
    bool clearPendingRecipient = false,
  }) {
    return KitItem(
      id: id,
      name: name,
      custodianName: custodianName ?? this.custodianName,
      pendingRecipient: clearPendingRecipient
          ? null
          : (pendingRecipient ?? this.pendingRecipient),
    );
  }
}

/// Mock data for the debug demo and tests -- no backend kit-inventory
/// service exists yet.
List<KitItem> mockKitItems() => const [
  KitItem(id: 'kit-1', name: 'Team helmet', custodianName: 'Kabir Singh'),
  KitItem(
    id: 'kit-2',
    name: 'Wicket-keeping pads',
    custodianName: 'Priya Nair',
  ),
  KitItem(
    id: 'kit-3',
    name: 'Practice bowling machine balls',
    custodianName: 'Arjun Mehta',
  ),
];

/// Mock roster for the hand-over recipient picker -- no team-membership
/// service exists yet.
List<String> mockKitTeamMemberNames() => const [
  'Kabir Singh',
  'Priya Nair',
  'Arjun Mehta',
  'Sana Iyer',
];
