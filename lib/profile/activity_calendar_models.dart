/// PRD §5.12: "GitHub-style heat grid: darker = more cricket that day
/// (match=3, practice=2, scoring/umpiring=2, social-only=0)."
enum ActivityType { match, practice, scoring, umpiring, social }

const Map<ActivityType, int> activityTypeWeight = {
  ActivityType.match: 3,
  ActivityType.practice: 2,
  ActivityType.scoring: 2,
  ActivityType.umpiring: 2,
  ActivityType.social: 0,
};

const Map<ActivityType, String> activityTypeLabels = {
  ActivityType.match: 'Match',
  ActivityType.practice: 'Practice',
  ActivityType.scoring: 'Scoring',
  ActivityType.umpiring: 'Umpiring',
  ActivityType.social: 'Social',
};

/// `detail` is the Self-only specific description (e.g. "vs Titans") --
/// PRD §5.12: "Friends see event types" (just [type]), "Self sees
/// everything" (adds [detail]).
class ActivityEntry {
  final DateTime date;
  final ActivityType type;
  final String detail;

  const ActivityEntry({
    required this.date,
    required this.type,
    required this.detail,
  });
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// PRD §5.12's heat value for a day is the summed weight of that day's
/// activity, capped to the 4-step ramp (DS §3.10) the calendar already
/// renders on a 0-3 scale.
Map<DateTime, int> computeHeatLevels(List<ActivityEntry> entries) {
  final totals = <DateTime, int>{};
  for (final entry in entries) {
    final day = _dateOnly(entry.date);
    final weight = activityTypeWeight[entry.type]!;
    totals[day] = (totals[day] ?? 0) + weight;
  }
  return totals.map((day, total) => MapEntry(day, total.clamp(0, 3)));
}

/// Mock month of activity for the debug demo and tests -- no backend
/// activity feed exists yet.
List<ActivityEntry> mockActivityEntries({DateTime? month}) {
  final reference = month ?? DateTime.now();
  DateTime day(int d) => DateTime(reference.year, reference.month, d);

  return [
    ActivityEntry(date: day(2), type: ActivityType.practice, detail: 'Nets'),
    ActivityEntry(date: day(5), type: ActivityType.match, detail: 'vs Titans'),
    ActivityEntry(
      date: day(9),
      type: ActivityType.scoring,
      detail: 'Scored: Lions vs Kings',
    ),
    ActivityEntry(
      date: day(12),
      type: ActivityType.match,
      detail: 'vs Strikers',
    ),
    ActivityEntry(
      date: day(12),
      type: ActivityType.social,
      detail: 'Team dinner',
    ),
    ActivityEntry(
      date: day(15),
      type: ActivityType.umpiring,
      detail: 'Umpired: U19 final',
    ),
    ActivityEntry(
      date: day(19),
      type: ActivityType.practice,
      detail: 'Fielding drills',
    ),
    ActivityEntry(date: day(23), type: ActivityType.social, detail: 'Meetup'),
  ];
}
