import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'team_member_models.dart';

class MembersRolesState {
  final List<TeamMember> roster;
  final List<TeamLogEntry> log;

  const MembersRolesState({this.roster = const [], this.log = const []});

  MembersRolesState copyWith({
    List<TeamMember>? roster,
    List<TeamLogEntry>? log,
  }) {
    return MembersRolesState(
      roster: roster ?? this.roster,
      log: log ?? this.log,
    );
  }

  Map<String, dynamic> toJson() => {
    'roster': roster.map((m) => m.toJson()).toList(),
    'log': log.map((l) => l.toJson()).toList(),
  };

  factory MembersRolesState.fromJson(Map<String, dynamic> json) {
    return MembersRolesState(
      roster: [
        for (final m in (json['roster'] as List? ?? const []))
          TeamMember.fromJson(m as Map<String, dynamic>),
      ],
      log: [
        for (final l in (json['log'] as List? ?? const []))
          TeamLogEntry.fromJson(l as Map<String, dynamic>),
      ],
    );
  }
}

/// PRD §2.3-2.4: role-change/removal constraints. §2.4's VC exclusions
/// ("cannot remove the Captain, cannot appoint another VC, cannot demote
/// the Manager") and the "last-admin guard" (can't leave a team with no
/// Captain/Owner -- the full succession wizard is a separate future
/// story, E3-15; this is just the structural block on removal itself).
class MembersRolesNotifier extends PersistedNotifier<MembersRolesState> {
  @override
  String get persistenceKey => 'members_roles_v1';

  @override
  MembersRolesState seed() => MembersRolesState(roster: mockRoster());

  @override
  Map<String, dynamic> toJson(MembersRolesState value) => value.toJson();

  @override
  MembersRolesState fromJson(Map<String, dynamic> json) =>
      MembersRolesState.fromJson(json);

  TeamMember _find(String name) =>
      state.roster.firstWhere((m) => m.name == name);

  /// Returns null on success; a human-readable reason string if denied
  /// (never mutates state in that case).
  String? changeRole({
    required String memberName,
    required TeamMemberRole newRole,
    required TeamMemberRole actingRole,
    required String actorName,
  }) {
    if (actingRole != TeamMemberRole.owner &&
        actingRole != TeamMemberRole.captain &&
        actingRole != TeamMemberRole.viceCaptain) {
      return "You don't have permission to change roles.";
    }
    final target = _find(memberName);
    if (actingRole == TeamMemberRole.viceCaptain) {
      if (newRole == TeamMemberRole.viceCaptain) {
        return 'A Vice-Captain cannot appoint another Vice-Captain.';
      }
      if (target.role == TeamMemberRole.manager) {
        return 'A Vice-Captain cannot demote the Manager.';
      }
    }

    final updatedRoster = [
      for (final member in state.roster)
        if (member.name == memberName)
          TeamMember(name: member.name, role: newRole)
        else
          member,
    ];
    state = state.copyWith(
      roster: updatedRoster,
      log: [
        ...state.log,
        TeamLogEntry(
          timestamp: DateTime.now(),
          action: 'Changed role to ${teamMemberRoleLabels[newRole]}',
          actorName: actorName,
          targetName: memberName,
        ),
      ],
    );
    return null;
  }

  /// AC: "removal requires reason and writes team log." Returns null on
  /// success; a human-readable denial reason otherwise.
  String? removeMember({
    required String memberName,
    required TeamMemberRole actingRole,
    required String actorName,
    required String reason,
  }) {
    if (reason.trim().isEmpty) {
      return 'A reason is required to remove a member.';
    }
    if (actingRole != TeamMemberRole.owner &&
        actingRole != TeamMemberRole.captain &&
        actingRole != TeamMemberRole.viceCaptain) {
      return "You don't have permission to remove members.";
    }
    final target = _find(memberName);
    // AC: a Vice-Captain cannot remove the Captain.
    if (actingRole == TeamMemberRole.viceCaptain &&
        target.role == TeamMemberRole.captain) {
      return 'A Vice-Captain cannot remove the Captain.';
    }
    final isSoleAdmin =
        (target.role == TeamMemberRole.captain ||
            target.role == TeamMemberRole.owner) &&
        state.roster
                .where(
                  (m) =>
                      m.role == TeamMemberRole.captain ||
                      m.role == TeamMemberRole.owner,
                )
                .length <=
            1;
    if (isSoleAdmin) {
      return 'Transfer captaincy/ownership before removing the last '
          'admin from the team.';
    }

    state = state.copyWith(
      roster: state.roster.where((m) => m.name != memberName).toList(),
      log: [
        ...state.log,
        TeamLogEntry(
          timestamp: DateTime.now(),
          action: 'Removed from team',
          actorName: actorName,
          targetName: memberName,
          reason: reason,
        ),
      ],
    );
    return null;
  }
}

final membersRolesProvider =
    NotifierProvider<MembersRolesNotifier, MembersRolesState>(
      MembersRolesNotifier.new,
    );
