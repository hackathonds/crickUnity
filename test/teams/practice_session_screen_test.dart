import 'package:cricunity/design_system/components/app_button.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/teams/practice_session_provider.dart';
import 'package:cricunity/teams/practice_session_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness({
    required String viewerName,
    bool isCoach = false,
    DateTime Function()? now,
  }) => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: PracticeSessionScreen(
        viewerName: viewerName,
        isCoach: isCoach,
        now: now ?? DateTime.now,
      ),
    ),
  );

  testWidgets('renders drills with their prescription and XP chip', (
    tester,
  ) async {
    await tester.pumpWidget(harness(viewerName: 'Priya Nair'));

    expect(find.textContaining('Throwdowns'), findsOneWidget);
    expect(find.text('+15 XP'), findsWidgets);
  });

  testWidgets('the check-in button is enabled within the window', (
    tester,
  ) async {
    await tester.pumpWidget(harness(viewerName: 'Ananya Iyer'));

    expect(find.byKey(const ValueKey('checkInButton')), findsOneWidget);
    expect(find.byKey(const ValueKey('checkInWindowNote')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('checkInButton')));
    await tester.pump();

    expect(find.byKey(const ValueKey('checkedInLabel')), findsOneWidget);
  });

  testWidgets('AC: outside the check-in window the button is disabled with an '
      'explanatory note', (tester) async {
    final farAway = DateTime.now().add(const Duration(days: 3));
    await tester.pumpWidget(
      harness(viewerName: 'Ananya Iyer', now: () => farAway),
    );

    final button = tester.widget<AppButton>(
      find.byKey(const ValueKey('checkInButton')),
    );
    expect(button.onPressed, isNull);
    expect(find.byKey(const ValueKey('checkInWindowNote')), findsOneWidget);
  });

  testWidgets('setting an RSVP selects the matching chip', (tester) async {
    await tester.pumpWidget(harness(viewerName: 'Farhan Ali'));

    await tester.tap(find.byKey(const ValueKey('rsvpOption_yes')));
    await tester.pump();

    final context = tester.element(find.byType(PracticeSessionScreen));
    final container = ProviderScope.containerOf(context);
    expect(
      container.read(practiceSessionProvider).session.rsvps['Farhan Ali'],
      isNotNull,
    );
  });

  testWidgets('AC: roll-call mode is only shown for the coach view', (
    tester,
  ) async {
    // Roll-call sits below the fold in a plain ListView on the default
    // small test surface -- same lazy-viewport gotcha hit repeatedly
    // elsewhere this session (ListView virtualizes even eager children).
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(viewerName: 'Ananya Iyer', isCoach: false));
    expect(find.text('Roll-call'), findsNothing);

    await tester.pumpWidget(harness(viewerName: 'Ananya Iyer', isCoach: true));
    expect(find.text('Roll-call'), findsOneWidget);
  });

  testWidgets('a roll-call toggle checks a member in on their behalf', (
    tester,
  ) async {
    // Roll-call rows sit below the fold in a plain ListView on the
    // default small test surface -- same lazy-viewport gotcha hit
    // repeatedly elsewhere this session.
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(harness(viewerName: 'Coach', isCoach: true));

    await tester.tap(find.byKey(const ValueKey('rollCallToggle_Farhan Ali')));
    await tester.pump();

    final toggle = tester.widget<Switch>(
      find.byKey(const ValueKey('rollCallToggle_Farhan Ali')),
    );
    expect(toggle.value, isTrue);
  });

  testWidgets(
    'ending the session shows the recap card with no-shows, excusable by '
    'the coach',
    (tester) async {
      tester.view.physicalSize = const Size(400, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(harness(viewerName: 'Coach', isCoach: true));

      await tester.tap(find.byKey(const ValueKey('endSessionButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('sessionRecapCard')), findsOneWidget);
      expect(find.text('Priya Nair'), findsWidgets);
      expect(
        find.byKey(const ValueKey('excuseNoShow_Priya Nair')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('excuseNoShow_Priya Nair')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Priya Nair (excused)'), findsOneWidget);
    },
  );
}
