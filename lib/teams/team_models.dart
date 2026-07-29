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

  Map<String, dynamic> toJson() => {
    'changedAt': changedAt.toIso8601String(),
    'field': field,
    'from': from,
    'to': to,
  };

  factory TeamIdentityChangeLogEntry.fromJson(Map<String, dynamic> json) {
    return TeamIdentityChangeLogEntry(
      changedAt: DateTime.parse(json['changedAt'] as String),
      field: json['field'] as String,
      from: json['from'] as String,
      to: json['to'] as String,
    );
  }
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
  final int followerCount;
  final int memberCount;

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
    this.followerCount = 0,
    this.memberCount = 0,
    this.formerName,
    this.formerNameExpiresAt,
  });

  bool formerNameActive({DateTime Function() now = DateTime.now}) =>
      formerName != null &&
      formerNameExpiresAt != null &&
      now().isBefore(formerNameExpiresAt!);

  Map<String, dynamic> toJson() => {
    'name': name,
    'city': city,
    'homeGround': homeGround,
    'formatFocus': formatFocus.map((f) => f.name).toList(),
    'joinPolicy': joinPolicy.name,
    'primaryColor': primaryColor.toARGB32(),
    'secondaryColor': secondaryColor.toARGB32(),
    'isArchived': isArchived,
    'changeLog': changeLog.map((e) => e.toJson()).toList(),
    'followerCount': followerCount,
    'memberCount': memberCount,
    'formerName': formerName,
    'formerNameExpiresAt': formerNameExpiresAt?.toIso8601String(),
  };

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      name: json['name'] as String,
      city: json['city'] as String,
      homeGround: json['homeGround'] as String?,
      formatFocus: [
        for (final f in (json['formatFocus'] as List? ?? const []))
          TeamFormat.values.byName(f as String),
      ],
      joinPolicy: TeamJoinPolicy.values.byName(
        json['joinPolicy'] as String? ?? TeamJoinPolicy.open.name,
      ),
      primaryColor: Color(json['primaryColor'] as int? ?? 0xFF123B2A),
      secondaryColor: Color(json['secondaryColor'] as int? ?? 0xFFE0A82E),
      isArchived: json['isArchived'] as bool? ?? false,
      changeLog: [
        for (final e in (json['changeLog'] as List? ?? const []))
          TeamIdentityChangeLogEntry.fromJson(e as Map<String, dynamic>),
      ],
      followerCount: json['followerCount'] as int? ?? 0,
      memberCount: json['memberCount'] as int? ?? 0,
      formerName: json['formerName'] as String?,
      formerNameExpiresAt: (json['formerNameExpiresAt'] as String?) == null
          ? null
          : DateTime.parse(json['formerNameExpiresAt'] as String),
    );
  }
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
  followerCount: 340,
  memberCount: 18,
  primaryColor: const Color(0xFF123B2A),
  secondaryColor: const Color(0xFFE0A82E),
);
