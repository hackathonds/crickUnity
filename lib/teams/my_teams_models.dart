import 'package:flutter/material.dart' show Color;

import 'team_member_models.dart';
import 'team_models.dart';
import 'team_viewer_role.dart';

/// DS §7.3 screen 10 ("My Teams"): "Cards 96 with role chip + next-event
/// caption; long-press = default/mute/leave." Backlog: "switcher | open /
/// create | team cards with role chips | member | empty: create/join
/// CTAs." No aggregator of "every team I'm a member of" exists anywhere
/// else in this app -- every other screen either already knows which
/// team it's showing ([Team]) or the single role a member holds on it
/// ([TeamViewerRole]/[TeamMemberRole]); this is the one place that needs
/// a whole list of (team, role) pairs at once.
class MyTeamMembership {
  final Team team;
  final TeamMemberRole role;
  final bool isDefault;
  final bool isMuted;

  /// "Next-event caption" (DS) -- no cross-module link from a team to
  /// its next scheduled match/practice exists yet (that would need a
  /// real per-team calendar query); a short mock string stands in, same
  /// honest-gap convention used throughout this app.
  final String nextEventCaption;

  const MyTeamMembership({
    required this.team,
    required this.role,
    this.isDefault = false,
    this.isMuted = false,
    required this.nextEventCaption,
  });

  MyTeamMembership copyWith({bool? isDefault, bool? isMuted}) =>
      MyTeamMembership(
        team: team,
        role: role,
        isDefault: isDefault ?? this.isDefault,
        isMuted: isMuted ?? this.isMuted,
        nextEventCaption: nextEventCaption,
      );
}

/// [TeamMemberRole] (a roster role -- always a real member) and
/// [TeamViewerRole] (also covers non-members) share every name a member
/// can actually hold, so this is a direct mapping, never a guess.
TeamViewerRole memberRoleToViewerRole(TeamMemberRole role) => switch (role) {
  TeamMemberRole.player => TeamViewerRole.player,
  TeamMemberRole.manager => TeamViewerRole.manager,
  TeamMemberRole.viceCaptain => TeamViewerRole.viceCaptain,
  TeamMemberRole.captain => TeamViewerRole.captain,
  TeamMemberRole.owner => TeamViewerRole.owner,
};

/// Mock roster for the debug demo -- deliberately varied (a default team,
/// a muted one, three different roles) so the switcher's own behaviors
/// are all demonstrable at once.
List<MyTeamMembership> mockMyTeams() => [
  MyTeamMembership(
    team: mockTeam(),
    role: TeamMemberRole.captain,
    isDefault: true,
    nextEventCaption: 'Practice tomorrow, 6:30 AM',
  ),
  MyTeamMembership(
    team: const Team(
      name: 'Riverside Strikers',
      city: 'Pune',
      homeGround: 'Riverside Oval',
      followerCount: 210,
      memberCount: 15,
      primaryColor: Color(0xFF1B3A6B),
      secondaryColor: Color(0xFFD9A441),
    ),
    role: TeamMemberRole.player,
    nextEventCaption: 'Match vs Central Warriors, Sun 7:00 AM',
  ),
  MyTeamMembership(
    team: const Team(
      name: 'Deccan Nomads',
      city: 'Pune',
      followerCount: 64,
      memberCount: 12,
      primaryColor: Color(0xFF6B3A1B),
      secondaryColor: Color(0xFF4C8C4A),
    ),
    role: TeamMemberRole.viceCaptain,
    isMuted: true,
    nextEventCaption: 'No upcoming events',
  ),
];
