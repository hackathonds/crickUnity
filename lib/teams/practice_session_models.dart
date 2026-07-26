import 'availability_matrix_models.dart';

/// PRD §6.9-6.10. Backlog cites "PRD Appx E" for the Drill Library --
/// that appendix doesn't exist (only Appendix A/B do, same gap already
/// flagged in E2-05 for a different missing appendix). Proceeded on DS
/// §7 screen 15's own concrete wording ("drill list rows (name·
/// prescription·XP chip)") for the drill shape, with a small
/// representative mock library rather than guessing invented content.
class Drill {
  final String name;
  final String prescription;
  final int xp;

  const Drill({required this.name, required this.prescription, this.xp = 10});
}

List<Drill> mockDrillLibrary() => const [
  Drill(name: 'Throwdowns', prescription: '20 balls, 3 sets', xp: 15),
  Drill(name: 'Fielding relay', prescription: '10 min, 2 groups', xp: 10),
  Drill(name: 'Yorker practice', prescription: '6 overs', xp: 15),
];

class NoShowRecord {
  final String memberName;
  final bool excused;
  final String? reason;

  const NoShowRecord({
    required this.memberName,
    this.excused = false,
    this.reason,
  });
}

/// PRD §6.9: "Create session: date/time, venue, focus tags (nets/
/// fielding/fitness), capacity, RSVP deadline."
class PracticeSession {
  final String venueName;
  final DateTime scheduledAt;
  final List<String> focusTags;
  final int capacity;
  final List<Drill> drills;
  final List<String> roster;
  final Map<String, AvailabilityResponse> rsvps;
  final Set<String> checkedIn;
  final List<NoShowRecord> noShows;
  final bool ended;
  final DateTime? rsvpDeadline;

  const PracticeSession({
    required this.venueName,
    required this.scheduledAt,
    this.focusTags = const [],
    this.capacity = 20,
    this.drills = const [],
    this.roster = const [],
    this.rsvps = const {},
    this.checkedIn = const {},
    this.noShows = const [],
    this.ended = false,
    this.rsvpDeadline,
  });

  PracticeSession copyWith({
    Map<String, AvailabilityResponse>? rsvps,
    Set<String>? checkedIn,
    List<NoShowRecord>? noShows,
    bool? ended,
  }) {
    return PracticeSession(
      venueName: venueName,
      scheduledAt: scheduledAt,
      focusTags: focusTags,
      capacity: capacity,
      drills: drills,
      roster: roster,
      rsvps: rsvps ?? this.rsvps,
      checkedIn: checkedIn ?? this.checkedIn,
      noShows: noShows ?? this.noShows,
      ended: ended ?? this.ended,
      rsvpDeadline: rsvpDeadline,
    );
  }
}

/// Mock data for the debug demo and tests -- no backend practice-session
/// service exists yet. [scheduledAt] defaults near "now" so the debug
/// demo naturally lands inside the check-in window.
PracticeSession mockPracticeSession({DateTime Function() now = DateTime.now}) {
  return PracticeSession(
    venueName: 'Deccan Gymkhana',
    scheduledAt: now(),
    focusTags: const ['Nets', 'Fielding'],
    drills: mockDrillLibrary(),
    roster: const ['Priya Nair', 'Kabir Singh', 'Ananya Iyer', 'Farhan Ali'],
    rsvps: const {
      'Priya Nair': AvailabilityResponse.yes,
      'Kabir Singh': AvailabilityResponse.yes,
      'Ananya Iyer': AvailabilityResponse.maybe,
      'Farhan Ali': AvailabilityResponse.no,
    },
  );
}
