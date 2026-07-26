import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/onboarding/warm_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(VoidCallback onDone) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: WarmUpScreen(onDone: onDone),
  );

  testWidgets('renders every suggested name with a Follow button', (
    tester,
  ) async {
    await tester.pumpWidget(harness(() {}));

    expect(find.text('Arjun Rao'), findsOneWidget);
    expect(find.text('Follow'), findsWidgets);
  });

  testWidgets('tapping Follow toggles that row to Following', (tester) async {
    await tester.pumpWidget(harness(() {}));

    await tester.tap(find.byKey(const ValueKey('warmUpFollowButton_0')));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('warmUpSuggestion_0')),
        matching: find.text('Following'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Done always calls onDone, with no follow required', (
    tester,
  ) async {
    var done = false;
    await tester.pumpWidget(harness(() => done = true));

    await tester.tap(find.byKey(const ValueKey('warmUpDone')));
    await tester.pump();

    expect(done, isTrue);
  });
}
