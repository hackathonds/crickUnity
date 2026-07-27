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
}
