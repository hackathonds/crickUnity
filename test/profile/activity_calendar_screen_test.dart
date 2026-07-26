import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/profile/activity_calendar_models.dart';
import 'package:cricunity/profile/activity_calendar_screen.dart';
import 'package:cricunity/profile/profile_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final matchDay = DateTime(2026, 3, 5);
  final entries = [
    ActivityEntry(
      date: matchDay,
      type: ActivityType.match,
      detail: 'vs Titans',
    ),
    ActivityEntry(
      date: matchDay,
      type: ActivityType.social,
      detail: 'Team dinner',
    ),
  ];

  Widget harness({
    required ViewerRelation relation,
    List<ActivityEntry>? entries,
  }) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: ActivityCalendarScreen(
      entries: entries ?? [],
      relation: relation,
      initialMonth: DateTime(2026, 3),
    ),
  );

  Finder dayFinder(DateTime date) => find.byKey(
    ValueKey('appCalendarDay-${date.year}-${date.month}-${date.day}'),
  );

  testWidgets('empty entries show the Empty state, not a blank calendar', (
    tester,
  ) async {
    await tester.pumpWidget(harness(relation: ViewerRelation.self));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('activityCalendarGrid')), findsNothing);
    expect(find.textContaining('No cricket activity yet'), findsOneWidget);
  });

  testWidgets(
    'AC: public and follower viewers see the heat grid but tapping a day '
    'never opens a detail peek',
    (tester) async {
      for (final relation in [ViewerRelation.public, ViewerRelation.follower]) {
        await tester.pumpWidget(harness(relation: relation, entries: entries));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('activityCalendarGrid')),
          findsOneWidget,
        );
        await tester.tap(dayFinder(matchDay));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('activityDayPeekList')),
          findsNothing,
          reason: 'day peek leaked for relation $relation',
        );
      }
    },
  );

  testWidgets(
    'AC: a teammate (Friends tier) sees event types on tap but not the '
    'Self-only detail text',
    (tester) async {
      await tester.pumpWidget(
        harness(relation: ViewerRelation.teammate, entries: entries),
      );
      await tester.pumpAndSettle();

      await tester.tap(dayFinder(matchDay));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('activityDayPeekList')), findsOneWidget);
      expect(find.text('Match'), findsOneWidget);
      expect(find.text('Social'), findsOneWidget);
      expect(find.textContaining('vs Titans'), findsNothing);
      expect(find.textContaining('Team dinner'), findsNothing);
    },
  );

  testWidgets('AC: self sees full event detail on tap', (tester) async {
    await tester.pumpWidget(
      harness(relation: ViewerRelation.self, entries: entries),
    );
    await tester.pumpAndSettle();

    await tester.tap(dayFinder(matchDay));
    await tester.pumpAndSettle();

    expect(find.textContaining('vs Titans'), findsOneWidget);
    expect(find.textContaining('Team dinner'), findsOneWidget);
  });

  testWidgets('tapping a day with no activity does nothing', (tester) async {
    await tester.pumpWidget(
      harness(relation: ViewerRelation.self, entries: entries),
    );
    await tester.pumpAndSettle();

    await tester.tap(dayFinder(DateTime(2026, 3, 6)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('activityDayPeekList')), findsNothing);
  });

  testWidgets('the month pager advances and retreats', (tester) async {
    await tester.pumpWidget(
      harness(relation: ViewerRelation.self, entries: entries),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('March'), findsOneWidget);

    await tester.tap(find.text('›'));
    await tester.pumpAndSettle();
    expect(find.textContaining('April'), findsOneWidget);

    await tester.tap(find.text('‹'));
    await tester.tap(find.text('‹'));
    await tester.pumpAndSettle();
    expect(find.textContaining('February'), findsOneWidget);
  });
}
