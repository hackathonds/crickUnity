import 'package:cricunity/profile/activity_calendar_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeHeatLevels', () {
    test('a match day weighs 3', () {
      final levels = computeHeatLevels([
        ActivityEntry(
          date: DateTime(2026, 3, 5),
          type: ActivityType.match,
          detail: 'vs Titans',
        ),
      ]);

      expect(levels[DateTime(2026, 3, 5)], 3);
    });

    test('a social-only day weighs 0', () {
      final levels = computeHeatLevels([
        ActivityEntry(
          date: DateTime(2026, 3, 5),
          type: ActivityType.social,
          detail: 'Meetup',
        ),
      ]);

      expect(levels[DateTime(2026, 3, 5)], 0);
    });

    test('multiple same-day entries sum weights, capped at 3', () {
      final levels = computeHeatLevels([
        ActivityEntry(
          date: DateTime(2026, 3, 5),
          type: ActivityType.match,
          detail: 'vs Titans',
        ),
        ActivityEntry(
          date: DateTime(2026, 3, 5),
          type: ActivityType.social,
          detail: 'Team dinner',
        ),
        ActivityEntry(
          date: DateTime(2026, 3, 5),
          type: ActivityType.practice,
          detail: 'Nets',
        ),
      ]);

      // 3 (match) + 0 (social) + 2 (practice) = 5, capped to the
      // calendar's 4-step (0-3) ramp.
      expect(levels[DateTime(2026, 3, 5)], 3);
    });

    test('entries on different days produce independent levels', () {
      final levels = computeHeatLevels([
        ActivityEntry(
          date: DateTime(2026, 3, 5),
          type: ActivityType.practice,
          detail: 'Nets',
        ),
        ActivityEntry(
          date: DateTime(2026, 3, 6),
          type: ActivityType.scoring,
          detail: 'Scored a match',
        ),
      ]);

      expect(levels[DateTime(2026, 3, 5)], 2);
      expect(levels[DateTime(2026, 3, 6)], 2);
      expect(levels.length, 2);
    });

    test('a bare DateTime with a time component still buckets by day', () {
      final levels = computeHeatLevels([
        ActivityEntry(
          date: DateTime(2026, 3, 5, 18, 30),
          type: ActivityType.umpiring,
          detail: 'Umpired: U19 final',
        ),
      ]);

      expect(levels[DateTime(2026, 3, 5)], 2);
    });
  });
}
