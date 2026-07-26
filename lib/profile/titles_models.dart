/// PRD §18: "Titles: equipable single title next to name (earned:
/// 'Streak Master', 'Iron Player', 'Guardian of the Ground' for record
/// holders; seasonal titles expire with a collector's archive)."
class EquipableTitle {
  final String name;
  final bool isExpired;

  const EquipableTitle({required this.name, this.isExpired = false});
}

/// Mock earned-titles catalog for the debug demo and tests -- no backend
/// titles system exists yet.
List<EquipableTitle> mockEarnedTitles() => const [
  EquipableTitle(name: 'Streak Master'),
  EquipableTitle(name: 'Iron Player'),
  EquipableTitle(name: 'Guardian of the Ground'),
  EquipableTitle(name: 'Season 4 Champion', isExpired: true),
];
