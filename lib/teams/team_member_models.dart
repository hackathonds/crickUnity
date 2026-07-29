/// Actual roster roles (distinct from [TeamViewerRole], which also
/// covers non-member viewers like public/follower).
enum TeamMemberRole { player, manager, viceCaptain, captain, owner }

const Map<TeamMemberRole, String> teamMemberRoleLabels = {
  TeamMemberRole.player: 'Player',
  TeamMemberRole.manager: 'Manager',
  TeamMemberRole.viceCaptain: 'Vice-Captain',
  TeamMemberRole.captain: 'Captain',
  TeamMemberRole.owner: 'Owner',
};

class TeamMember {
  final String name;
  final TeamMemberRole role;

  const TeamMember({required this.name, required this.role});

  Map<String, dynamic> toJson() => {'name': name, 'role': role.name};

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      name: json['name'] as String,
      role: TeamMemberRole.values.byName(json['role'] as String),
    );
  }
}

/// PRD §2.3: "invite/remove players (removal requires reason, logged)."
class TeamLogEntry {
  final DateTime timestamp;
  final String action;
  final String actorName;
  final String targetName;
  final String? reason;

  const TeamLogEntry({
    required this.timestamp,
    required this.action,
    required this.actorName,
    required this.targetName,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'action': action,
    'actorName': actorName,
    'targetName': targetName,
    'reason': reason,
  };

  factory TeamLogEntry.fromJson(Map<String, dynamic> json) {
    return TeamLogEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      action: json['action'] as String,
      actorName: json['actorName'] as String,
      targetName: json['targetName'] as String,
      reason: json['reason'] as String?,
    );
  }
}

/// PRD §6.5-6.7: "Team Settings screen exposes a Permission Matrix table
/// (rows=actions, columns=roles, checkmarks) so every member can see who
/// can do what." Each row's fixed grant set is derived directly from
/// §2.2-2.5/2.9's stated per-role permissions -- not an exhaustive
/// official matrix (the PRD only gives prose permission lists per role),
/// but every checkmark below traces to a specific quoted permission.
class PermissionMatrixRow {
  final String action;
  final Set<TeamMemberRole> grantedTo;

  const PermissionMatrixRow({required this.action, required this.grantedTo});
}

const List<PermissionMatrixRow> permissionMatrixRows = [
  PermissionMatrixRow(
    action: 'Invite players',
    grantedTo: {
      TeamMemberRole.captain,
      TeamMemberRole.viceCaptain,
      TeamMemberRole.owner,
    },
  ),
  PermissionMatrixRow(
    action: 'Approve/deny join requests',
    grantedTo: {
      TeamMemberRole.captain,
      TeamMemberRole.viceCaptain,
      TeamMemberRole.owner,
    },
  ),
  PermissionMatrixRow(
    action: 'Create matches',
    grantedTo: {
      TeamMemberRole.captain,
      TeamMemberRole.viceCaptain,
      TeamMemberRole.owner,
    },
  ),
  PermissionMatrixRow(
    action: 'Edit team identity (name/logo)',
    grantedTo: {TeamMemberRole.captain, TeamMemberRole.owner},
  ),
  PermissionMatrixRow(
    action: 'Post announcements',
    grantedTo: {
      TeamMemberRole.captain,
      TeamMemberRole.viceCaptain,
      TeamMemberRole.manager,
      TeamMemberRole.owner,
    },
  ),
  PermissionMatrixRow(
    action: 'Record/edit expenses',
    grantedTo: {TeamMemberRole.manager, TeamMemberRole.owner},
  ),
  PermissionMatrixRow(
    action: 'View full treasury',
    grantedTo: {
      TeamMemberRole.captain,
      TeamMemberRole.viceCaptain,
      TeamMemberRole.manager,
      TeamMemberRole.owner,
    },
  ),
  // VC has "everything Captain has" (§2.4) minus specific carve-outs
  // ("cannot appoint another VC," "cannot demote the Manager," "cannot
  // remove the Captain") -- those exceptions are enforced procedurally
  // in the actual change-role/remove flows, not as a coarser matrix
  // checkmark this table format can't represent.
  PermissionMatrixRow(
    action: 'Appoint/demote roles',
    grantedTo: {
      TeamMemberRole.captain,
      TeamMemberRole.viceCaptain,
      TeamMemberRole.owner,
    },
  ),
  PermissionMatrixRow(
    action: 'Remove members',
    grantedTo: {
      TeamMemberRole.captain,
      TeamMemberRole.viceCaptain,
      TeamMemberRole.owner,
    },
  ),
  PermissionMatrixRow(
    action: 'Transfer ownership',
    grantedTo: {TeamMemberRole.owner},
  ),
];

/// PRD §6.5-6.7: "Owner can toggle 6 configurable cells (e.g., 'VC can
/// approve expenses': on/off; 'Manager can create matches': off by
/// default)." The PRD only names these two cells as illustrative
/// examples ("e.g.") -- the other 4 aren't specified anywhere in either
/// frozen document. Rather than inventing 4 unstated toggles, this list
/// holds only the two the source docs actually name; the remaining count
/// is flagged as an open question in this story's PR description.
class ConfigurablePermissionCell {
  final String label;
  final bool defaultValue;

  const ConfigurablePermissionCell({
    required this.label,
    required this.defaultValue,
  });
}

const List<ConfigurablePermissionCell> configurablePermissionCells = [
  ConfigurablePermissionCell(
    label: 'VC can approve expenses',
    defaultValue: true,
  ),
  ConfigurablePermissionCell(
    label: 'Manager can create matches',
    defaultValue: false,
  ),
];

/// Mock roster for the debug demo and tests -- no backend teams-
/// membership service exists yet.
List<TeamMember> mockRoster() => const [
  TeamMember(name: 'Rohan Verma', role: TeamMemberRole.owner),
  TeamMember(name: 'Arjun Rao', role: TeamMemberRole.captain),
  TeamMember(name: 'Priya Nair', role: TeamMemberRole.viceCaptain),
  TeamMember(name: 'Kabir Singh', role: TeamMemberRole.manager),
  TeamMember(name: 'Ananya Iyer', role: TeamMemberRole.player),
  TeamMember(name: 'Farhan Ali', role: TeamMemberRole.player),
];
