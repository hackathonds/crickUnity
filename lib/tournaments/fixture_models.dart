/// PRD §8.3 (Fixtures): "Auto-generator honors: ground availability
/// windows, team blackout dates (teams may submit up to 2), rest gaps,
/// double-header limits. Manual drag-adjust with conflict warnings.
/// Publishing notifies all squads; any change -> change-record with
/// reason + re-notify affected."
///
/// No cross-module tie to the real Ground-booking calendar (E9-03)
/// exists -- a tournament's own organizer-submitted venue+date pool
/// stands in for "ground availability windows," flagged as a smaller,
/// self-contained scheduling surface rather than reaching into a
/// different module's per-hour booking model for what this story
/// needs as whole-day match slots.
class VenueSlot {
  final String venueName;
  final DateTime date;

  const VenueSlot({required this.venueName, required this.date});

  bool sameSlot(VenueSlot other) =>
      venueName == other.venueName && date == other.date;

  Map<String, dynamic> toJson() => {
    'venueName': venueName,
    'date': date.toIso8601String(),
  };

  factory VenueSlot.fromJson(Map<String, dynamic> json) {
    return VenueSlot(
      venueName: json['venueName'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }
}

/// PRD names no exact rest-gap length or double-header cap -- flagged
/// judgment calls.
const int minRestDaysBetweenMatches = 1;
const int maxMatchesPerTeamPerDay = 1;

class FixtureChangeRecord {
  final String reason;
  final DateTime changedAt;
  final String? previousVenueName;
  final DateTime? previousDate;

  const FixtureChangeRecord({
    required this.reason,
    required this.changedAt,
    this.previousVenueName,
    this.previousDate,
  });

  Map<String, dynamic> toJson() => {
    'reason': reason,
    'changedAt': changedAt.toIso8601String(),
    'previousVenueName': previousVenueName,
    'previousDate': previousDate?.toIso8601String(),
  };

  factory FixtureChangeRecord.fromJson(Map<String, dynamic> json) {
    return FixtureChangeRecord(
      reason: json['reason'] as String,
      changedAt: DateTime.parse(json['changedAt'] as String),
      previousVenueName: json['previousVenueName'] as String?,
      previousDate: json['previousDate'] != null
          ? DateTime.parse(json['previousDate'] as String)
          : null,
    );
  }
}

class Fixture {
  final String id;
  final String tournamentId;
  final String homeRegistrationId;
  final String homeTeamName;
  final String awayRegistrationId;
  final String awayTeamName;
  final String? venueName;
  final DateTime? date;
  final List<FixtureChangeRecord> changeHistory;

  const Fixture({
    required this.id,
    required this.tournamentId,
    required this.homeRegistrationId,
    required this.homeTeamName,
    required this.awayRegistrationId,
    required this.awayTeamName,
    this.venueName,
    this.date,
    this.changeHistory = const [],
  });

  bool get isScheduled => venueName != null && date != null;

  Fixture copyWith({
    String? venueName,
    DateTime? date,
    List<FixtureChangeRecord>? changeHistory,
  }) {
    return Fixture(
      id: id,
      tournamentId: tournamentId,
      homeRegistrationId: homeRegistrationId,
      homeTeamName: homeTeamName,
      awayRegistrationId: awayRegistrationId,
      awayTeamName: awayTeamName,
      venueName: venueName ?? this.venueName,
      date: date ?? this.date,
      changeHistory: changeHistory ?? this.changeHistory,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tournamentId': tournamentId,
    'homeRegistrationId': homeRegistrationId,
    'homeTeamName': homeTeamName,
    'awayRegistrationId': awayRegistrationId,
    'awayTeamName': awayTeamName,
    'venueName': venueName,
    'date': date?.toIso8601String(),
    'changeHistory': [for (final c in changeHistory) c.toJson()],
  };

  factory Fixture.fromJson(Map<String, dynamic> json) {
    return Fixture(
      id: json['id'] as String,
      tournamentId: json['tournamentId'] as String,
      homeRegistrationId: json['homeRegistrationId'] as String,
      homeTeamName: json['homeTeamName'] as String,
      awayRegistrationId: json['awayRegistrationId'] as String,
      awayTeamName: json['awayTeamName'] as String,
      venueName: json['venueName'] as String?,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : null,
      changeHistory: [
        for (final c in json['changeHistory'] as List)
          FixtureChangeRecord.fromJson(c as Map<String, dynamic>),
      ],
    );
  }
}
