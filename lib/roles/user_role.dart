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
