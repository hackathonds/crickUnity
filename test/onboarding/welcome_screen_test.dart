import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/onboarding/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness({
    required VoidCallback onGetStarted,
    required VoidCallback onExploreAsGuest,
  }) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: WelcomeScreen(
      onGetStarted: onGetStarted,
      onExploreAsGuest: onExploreAsGuest,
    ),
  );

  testWidgets('renders the first slide and starts on the first page dot', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(onGetStarted: () {}, onExploreAsGuest: () {}),
    );

    expect(find.text('Your career, verified'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Explore first'), findsOneWidget);
  });

  testWidgets('swiping the pager advances to the next slide', (tester) async {
    await tester.pumpWidget(
      harness(onGetStarted: () {}, onExploreAsGuest: () {}),
    );

    await tester.drag(
      find.byKey(const ValueKey('welcomeScreenPager')),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Money made simple'), findsOneWidget);
  });

  testWidgets('Get started invokes onGetStarted', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      harness(onGetStarted: () => tapped = true, onExploreAsGuest: () {}),
    );

    await tester.tap(find.text('Get started'));
    expect(tapped, isTrue);
  });

  testWidgets('Explore first invokes onExploreAsGuest', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      harness(onGetStarted: () {}, onExploreAsGuest: () => tapped = true),
    );

    await tester.tap(find.text('Explore first'));
    expect(tapped, isTrue);
  });
}
