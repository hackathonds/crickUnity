import '../design_system/icons/app_icon_id.dart';
import 'user_role.dart';

/// A role-gated drawer console entry — PRD §3.3, section 3 ("Consoles").
class ConsoleInfo {
  final String name;
  final AppIconId icon;

  const ConsoleInfo(this.name, this.icon);

  @override
  bool operator ==(Object other) =>
      other is ConsoleInfo && other.name == name && other.icon == icon;

  @override
  int get hashCode => Object.hash(name, icon);
}

const _captainConsole = ConsoleInfo('Captain Console', AppIconId.bat);

/// Every role that unlocks a drawer console, and which one. Captain,
/// Vice-Captain, and Team Owner all act inside the same Captain Console
/// (PRD §2.3-2.4/2.9); every other console-holding role maps 1:1.
final Map<UserRole, ConsoleInfo> consoleRegistry = {
  UserRole.captain: _captainConsole,
  UserRole.viceCaptain: _captainConsole,
  UserRole.teamOwner: _captainConsole,
  UserRole.manager: const ConsoleInfo('Manager / Treasury', AppIconId.wallet),
  UserRole.scorer: const ConsoleInfo('Scorer Console', AppIconId.scorebook),
  UserRole.umpire: const ConsoleInfo('Umpire Console', AppIconId.whistle),
  UserRole.coach: const ConsoleInfo('Coach Console', AppIconId.people),
  UserRole.groundOwner: const ConsoleInfo('Ground Console', AppIconId.pitch),
  UserRole.academyOwner: const ConsoleInfo('Academy Console', AppIconId.trophy),
  UserRole.tournamentOrganizer: const ConsoleInfo(
    'Organizer Console',
    AppIconId.chest,
  ),
  UserRole.clubOwner: const ConsoleInfo('Club Console', AppIconId.stumps),
  UserRole.sponsor: const ConsoleInfo('Sponsor Console', AppIconId.coin),
};

/// The distinct set of consoles currently unlocked for [roles], in
/// [consoleRegistry]'s iteration order, de-duplicated (Captain/VC/Owner
/// collapse to one entry).
List<ConsoleInfo> consolesFor(Set<UserRole> roles) {
  final seen = <ConsoleInfo>{};
  final result = <ConsoleInfo>[];
  for (final entry in consoleRegistry.entries) {
    if (!roles.contains(entry.key)) continue;
    if (seen.add(entry.value)) result.add(entry.value);
  }
  return result;
}
