/// Held-capability roles — PRD §2.2-2.17. An account can hold several at
/// once (non-negotiable #10: roles are activity-inferred, never chosen).
///
/// Guest (PRD §2.1) is a distinct *unauthenticated* app state, not a role an
/// account holds alongside others — excluded from this set.
enum UserRole {
  player,
  captain,
  viceCaptain,
  manager,
  scorer,
  umpire,
  coach,
  teamOwner,
  academyOwner,
  groundOwner,
  tournamentOrganizer,
  clubOwner,
  fan,
  sponsor,
  admin,
  superAdmin,
}

/// PRD §3.1/§3.6: "account switcher (multi-role identities, e.g.,
/// 'Deepak – Scorer view')" -- the display label for each held role.
const Map<UserRole, String> userRoleLabels = {
  UserRole.player: 'Player',
  UserRole.captain: 'Captain',
  UserRole.viceCaptain: 'Vice-Captain',
  UserRole.manager: 'Manager',
  UserRole.scorer: 'Scorer',
  UserRole.umpire: 'Umpire',
  UserRole.coach: 'Coach',
  UserRole.teamOwner: 'Team Owner',
  UserRole.academyOwner: 'Academy Owner',
  UserRole.groundOwner: 'Ground Owner',
  UserRole.tournamentOrganizer: 'Organizer',
  UserRole.clubOwner: 'Club Owner',
  UserRole.fan: 'Fan',
  UserRole.sponsor: 'Sponsor',
  UserRole.admin: 'Admin',
  UserRole.superAdmin: 'Super Admin',
};
