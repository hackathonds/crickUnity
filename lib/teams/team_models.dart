import 'package:flutter/material.dart';

/// PRD §5.2's format list, reused here for a team's "Format focus."
enum TeamFormat { t10, t20, thirtyOver, testStyle }

const Map<TeamFormat, String> teamFormatLabels = {
  TeamFormat.t10: 'T10',
  TeamFormat.t20: 'T20',
  TeamFormat.thirtyOver: '30-over',
  TeamFormat.testStyle: 'Test-style',
};

/// PRD §6.1: "Join policy (Open / Request / Invite-only)."
enum TeamJoinPolicy { open, request, inviteOnly }

const Map<TeamJoinPolicy, String> teamJoinPolicyLabels = {
  TeamJoinPolicy.open: 'Open',
  TeamJoinPolicy.request: 'Request',
  TeamJoinPolicy.inviteOnly: 'Invite-only',
};

/// PRD §6.2: "edits to Name/Logo notify members and keep a change log."
class TeamIdentityChangeLogEntry {
  final DateTime changedAt;
  final String field;
  final String from;
  final String to;

  const TeamIdentityChangeLogEntry({
    required this.changedAt,
    required this.field,
    required this.from,
    required this.to,
  });
}

/// A plain data holder -- no backend Team model exists yet, same
/// precedent as [PlayerProfile] (mock/demo data only).
class Team {
  final String name;
  final String city;
  final String? homeGround;
  final List<TeamFormat> formatFocus;
  final TeamJoinPolicy joinPolicy;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isArchived;
  final List<TeamIdentityChangeLogEntry> changeLog;

  /// PRD §6.2: "'Formerly known as…' for 90 days on public profile."
  final String? formerName;
  final DateTime? formerNameExpiresAt;

  const Team({
    required this.name,
    required this.city,
    this.homeGround,
    this.formatFocus = const [],
    this.joinPolicy = TeamJoinPolicy.open,
    this.primaryColor = const Color(0xFF123B2A),
    this.secondaryColor = const Color(0xFFE0A82E),
    this.isArchived = false,
    this.changeLog = const [],
    this.formerName,
    this.formerNameExpiresAt,
  });

  bool formerNameActive({DateTime Function() now = DateTime.now}) =>
      formerName != null &&
      formerNameExpiresAt != null &&
      now().isBefore(formerNameExpiresAt!);
}

/// Mock "teams that already exist" catalog -- stands in for the
/// name-unique-in-city backend check (PRD §6.1) until a real teams
/// service exists.
List<String> mockExistingTeamNamesInCity(String city) {
  if (city.trim().toLowerCase() == 'pune') {
    return const ['Lions CC', 'Deccan Strikers', 'Riverside Warriors'];
  }
  return const [];
}

/// Mock data for the debug demo and tests.
Team mockTeam() => Team(
  name: 'Lions CC',
  city: 'Pune',
  homeGround: 'Deccan Gymkhana',
  formatFocus: const [TeamFormat.t20, TeamFormat.thirtyOver],
  joinPolicy: TeamJoinPolicy.request,
  primaryColor: const Color(0xFF123B2A),
  secondaryColor: const Color(0xFFE0A82E),
);
