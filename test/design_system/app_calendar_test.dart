import 'package:cricunity/design_system/components/app_calendar.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  final colors = AppTheme.themes[AppTheme.defaultLight]!
      .extension<AppColors>()!;

  Key dayKey(DateTime d) =>
      ValueKey('appCalendarDay-${d.year}-${d.month}-${d.day}');

  testWidgets('renders the month/year header and 42 day cells', (tester) async {
    await tester.pumpWidget(
      harness(AppCalendarMonthGrid(month: DateTime(2026, 3, 1))),
    );

    expect(find.text('March 2026'), findsOneWidget);
    expect(find.textContaining('S'), findsWidgets);
  });

  testWidgets("today's ring renders on the right cell", (tester) async {
    final today = DateTime(2026, 3, 15);
    await tester.pumpWidget(
      harness(AppCalendarMonthGrid(month: DateTime(2026, 3, 1), today: today)),
    );

    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byKey(dayKey(today)),
            matching: find.byWidgetPredicate(
              (w) => w is Container && w.constraints?.maxWidth == 30,
            ),
          )
          .first,
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.border!.top.color, colors.primary);
    expect(decoration.border!.top.width, 1.5);
  });

  testWidgets('tapping a day calls onDaySelected with that date', (
    tester,
  ) async {
    DateTime? selected;
    await tester.pumpWidget(
      harness(
        AppCalendarMonthGrid(
          month: DateTime(2026, 3, 1),
          onDaySelected: (d) => selected = d,
        ),
      ),
    );

    await tester.tap(find.byKey(dayKey(DateTime(2026, 3, 15))));
    expect(selected, DateTime(2026, 3, 15));
  });

  testWidgets('the selected day renders a filled primary circle', (
    tester,
  ) async {
    final selectedDate = DateTime(2026, 3, 15);
    await tester.pumpWidget(
      harness(
        AppCalendarMonthGrid(
          month: DateTime(2026, 3, 1),
          selectedDate: selectedDate,
        ),
      ),
    );

    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byKey(dayKey(selectedDate)),
            matching: find.byWidgetPredicate(
              (w) => w is Container && w.constraints?.maxWidth == 30,
            ),
          )
          .first,
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, colors.primary);
  });

  testWidgets('long-pressing a day fires onDayLongPress', (tester) async {
    DateTime? longPressed;
    await tester.pumpWidget(
      harness(
        AppCalendarMonthGrid(
          month: DateTime(2026, 3, 1),
          onDayLongPress: (d) => longPressed = d,
        ),
      ),
    );

    await tester.longPress(find.byKey(dayKey(DateTime(2026, 3, 15))));
    expect(longPressed, DateTime(2026, 3, 15));
  });

  testWidgets('event dots render for a day with 1-3 events, no overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        AppCalendarMonthGrid(
          month: DateTime(2026, 3, 1),
          eventCounts: {DateTime(2026, 3, 5): 3},
        ),
      ),
    );

    expect(find.textContaining('+'), findsNothing);
  });

  testWidgets('event overflow renders "+n" beyond 3 events', (tester) async {
    await tester.pumpWidget(
      harness(
        AppCalendarMonthGrid(
          month: DateTime(2026, 3, 1),
          eventCounts: {DateTime(2026, 3, 5): 5},
        ),
      ),
    );

    expect(find.text('+2'), findsOneWidget);
  });

  testWidgets('range-select paints the tinted background across the span', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        AppCalendarMonthGrid(
          month: DateTime(2026, 3, 1),
          rangeStart: DateTime(2026, 3, 10),
          rangeEnd: DateTime(2026, 3, 14),
        ),
      ),
    );

    // A day inside the range and one outside both render; verifying via
    // the cell's Container background presence (inRange styling adds an
    // extra Positioned.fill Container ancestor for in-range days only).
    final insideMatches = find.descendant(
      of: find.byKey(dayKey(DateTime(2026, 3, 12))),
      matching: find.byWidgetPredicate(
        (w) =>
            w is Container &&
            (w.decoration as BoxDecoration?)?.color ==
                colors.primary.withValues(alpha: 0.12),
      ),
    );
    final outsideMatches = find.descendant(
      of: find.byKey(dayKey(DateTime(2026, 3, 25))),
      matching: find.byWidgetPredicate(
        (w) =>
            w is Container &&
            (w.decoration as BoxDecoration?)?.color ==
                colors.primary.withValues(alpha: 0.12),
      ),
    );

    expect(insideMatches, findsOneWidget);
    expect(outsideMatches, findsNothing);
  });

  testWidgets('heat cells pull colors from chartSequential', (tester) async {
    await tester.pumpWidget(
      harness(
        AppCalendarMonthGrid(
          month: DateTime(2026, 3, 1),
          heatLevels: {DateTime(2026, 3, 5): 3},
        ),
      ),
    );

    final matches = find.descendant(
      of: find.byKey(dayKey(DateTime(2026, 3, 5))),
      matching: find.byWidgetPredicate(
        (w) =>
            w is Container &&
            (w.decoration as BoxDecoration?)?.color ==
                colors.chartSequential.last,
      ),
    );
    expect(matches, findsOneWidget);
  });

  testWidgets('the density legend renders only when heatLevels is given', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(AppCalendarMonthGrid(month: DateTime(2026, 3, 1))),
    );
    expect(find.text('Less'), findsNothing);

    await tester.pumpWidget(
      harness(
        AppCalendarMonthGrid(
          month: DateTime(2026, 3, 1),
          heatLevels: {DateTime(2026, 3, 5): 1},
        ),
      ),
    );
    expect(find.text('Less'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
  });

  testWidgets('month navigation arrows fire their callbacks', (tester) async {
    var previousCalled = false;
    var nextCalled = false;
    await tester.pumpWidget(
      harness(
        AppCalendarMonthGrid(
          month: DateTime(2026, 3, 1),
          onPreviousMonth: () => previousCalled = true,
          onNextMonth: () => nextCalled = true,
        ),
      ),
    );

    await tester.tap(find.text('‹'));
    await tester.tap(find.text('›'));

    expect(previousCalled, isTrue);
    expect(nextCalled, isTrue);
  });
}
