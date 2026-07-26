import 'package:cricunity/design_system/components/app_timeline.dart';
import 'package:cricunity/design_system/icons/app_icon.dart';
import 'package:cricunity/design_system/icons/app_icon_id.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: Scaffold(body: SizedBox(height: 400, child: child)),
  );

  final day1 = DateTime(2026, 3, 1);
  final day2 = DateTime(2026, 3, 2);

  testWidgets('renders one date header per distinct day, in order', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        AppTimeline(
          entries: [
            AppTimelineEntry(date: day1, content: const Text('Event A')),
            AppTimelineEntry(date: day1, content: const Text('Event B')),
            AppTimelineEntry(date: day2, content: const Text('Event C')),
          ],
          dateLabelBuilder: (d) => d == day1 ? 'Day 1' : 'Day 2',
        ),
      ),
    );

    expect(find.text('Day 1'), findsOneWidget);
    expect(find.text('Day 2'), findsOneWidget);
    expect(find.text('Event A'), findsOneWidget);
    expect(find.text('Event B'), findsOneWidget);
    expect(find.text('Event C'), findsOneWidget);
  });

  testWidgets('a regular entry renders a plain 10px node, no icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        AppTimeline(
          entries: [
            AppTimelineEntry(date: day1, content: const Text('Event A')),
          ],
          dateLabelBuilder: (d) => 'Day 1',
        ),
      ),
    );

    expect(find.byKey(const ValueKey('appTimelineNode')), findsOneWidget);
    expect(find.byKey(const ValueKey('appTimelineKeyEventNode')), findsNothing);
  });

  testWidgets('a key event renders the 28px circle with its icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        AppTimeline(
          entries: [
            AppTimelineEntry(
              date: day1,
              isKeyEvent: true,
              icon: AppIconId.trophy,
              content: const Text('Match won'),
            ),
          ],
          dateLabelBuilder: (d) => 'Day 1',
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('appTimelineKeyEventNode')),
      findsOneWidget,
    );
    expect(find.byType(AppIcon), findsOneWidget);
    expect(find.byKey(const ValueKey('appTimelineNode')), findsNothing);
  });
}
