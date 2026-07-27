/// PRD §19 "Attendance Analytics" bullet: "individual & team trends,
/// no-show patterns by weekday/venue distance ('no-shows spike when
/// ground >15 km -- pick closer grounds?')." No attendance-history store
/// exists anywhere in the app (attendance is only ever a same-match
/// boolean flag scattered across expenses/scoring/practice-session
/// models, never persisted across matches) -- flagged synthetic
/// dataset, same convention as every other missing-backend gap this
/// session.
library;

class AttendanceRecord {
  final String matchLabel;
  final DateTime date;
  final double groundDistanceKm;
  final bool attended;

  const AttendanceRecord({
    required this.matchLabel,
    required this.date,
    required this.groundDistanceKm,
    required this.attended,
  });
}

const List<String> weekdayLabels = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

List<AttendanceRecord> mockAttendance(DateTime now) => [
  AttendanceRecord(
    matchLabel: 'vs Titans',
    date: now.subtract(const Duration(days: 3)),
    groundDistanceKm: 4,
    attended: true,
  ),
  AttendanceRecord(
    matchLabel: 'vs Riverside Warriors',
    date: now.subtract(const Duration(days: 10)),
    groundDistanceKm: 22,
    attended: false,
  ),
  AttendanceRecord(
    matchLabel: 'vs City Titans',
    date: now.subtract(const Duration(days: 17)),
    groundDistanceKm: 6,
    attended: true,
  ),
  AttendanceRecord(
    matchLabel: 'vs Strikers CC',
    date: now.subtract(const Duration(days: 24)),
    groundDistanceKm: 18,
    attended: false,
  ),
  AttendanceRecord(
    matchLabel: 'vs Riverside Warriors',
    date: now.subtract(const Duration(days: 31)),
    groundDistanceKm: 5,
    attended: true,
  ),
  AttendanceRecord(
    matchLabel: 'vs Titans',
    date: now.subtract(const Duration(days: 38)),
    groundDistanceKm: 4,
    attended: true,
  ),
  AttendanceRecord(
    matchLabel: 'vs City Titans',
    date: now.subtract(const Duration(days: 45)),
    groundDistanceKm: 20,
    attended: false,
  ),
  AttendanceRecord(
    matchLabel: 'vs Strikers CC',
    date: now.subtract(const Duration(days: 52)),
    groundDistanceKm: 7,
    attended: true,
  ),
  AttendanceRecord(
    matchLabel: 'vs Riverside Warriors',
    date: now.subtract(const Duration(days: 59)),
    groundDistanceKm: 25,
    attended: false,
  ),
  AttendanceRecord(
    matchLabel: 'vs Titans',
    date: now.subtract(const Duration(days: 66)),
    groundDistanceKm: 5,
    attended: true,
  ),
  AttendanceRecord(
    matchLabel: 'vs City Titans',
    date: now.subtract(const Duration(days: 73)),
    groundDistanceKm: 6,
    attended: true,
  ),
  AttendanceRecord(
    matchLabel: 'vs Strikers CC',
    date: now.subtract(const Duration(days: 80)),
    groundDistanceKm: 19,
    attended: false,
  ),
];

double noShowRate(List<AttendanceRecord> records) {
  if (records.isEmpty) return 0;
  final noShows = records.where((r) => !r.attended).length;
  return 100 * noShows / records.length;
}

Map<int, double> noShowRateByWeekday(List<AttendanceRecord> records) {
  final byDay = <int, List<AttendanceRecord>>{};
  for (final r in records) {
    byDay.putIfAbsent(r.date.weekday, () => []).add(r);
  }
  return {
    for (final entry in byDay.entries) entry.key: noShowRate(entry.value),
  };
}

/// PRD's own example threshold: "ground >15 km."
double noShowRateWithinDistance(
  List<AttendanceRecord> records, {
  required bool beyond15km,
}) {
  final subset = records
      .where(
        (r) => beyond15km ? r.groundDistanceKm > 15 : r.groundDistanceKm <= 15,
      )
      .toList();
  return noShowRate(subset);
}
