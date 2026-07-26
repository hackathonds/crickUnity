/// PRD §2.2-2.5/2.9 role permissions, condensed into the single tier
/// this screen needs to know about: does this viewer belong to the team
/// at all, and if so with which role. `public`/`follower` mirror
/// [ViewerRelation.public]/[.follower] from the Player Profile module,
/// kept separate here since a team's role model (Owner/Captain/VC/
/// Manager/Player) has no equivalent on a player profile.
enum TeamViewerRole {
  public,
  follower,
  player,
  manager,
  viceCaptain,
  captain,
  owner,
}

extension TeamViewerRoleAccess on TeamViewerRole {
  bool get isMember =>
      this != TeamViewerRole.public && this != TeamViewerRole.follower;

  /// PRD §2.3-2.5/2.9: Owner ("full historical treasury"), Captain
  /// ("view full team expense ledger"), VC ("treasury approvals
  /// visible"), Manager ("Treasury console" listed as a visible module)
  /// all have treasury access; a plain Player does not.
  bool get canSeeMoneyTab => switch (this) {
    TeamViewerRole.owner ||
    TeamViewerRole.captain ||
    TeamViewerRole.viceCaptain ||
    TeamViewerRole.manager => true,
    _ => false,
  };

  /// PRD §2.5: Manager's own "visible modules" list (Treasury console,
  /// sponsor console, logistics calendar) never includes team settings/
  /// permission-matrix administration -- that stays Owner/Captain/VC
  /// only, same set as "edit identity fields" in E3-01's Edit Team split.
  bool get canSeeManageTab => switch (this) {
    TeamViewerRole.owner ||
    TeamViewerRole.captain ||
    TeamViewerRole.viceCaptain => true,
    _ => false,
  };
}
