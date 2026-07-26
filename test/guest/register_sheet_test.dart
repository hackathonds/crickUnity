import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/guest/register_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(VoidCallback onOpen) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: Scaffold(
      body: Center(
        child: ElevatedButton(onPressed: onOpen, child: const Text('Open')),
      ),
    ),
  );

  testWidgets('shows the action-specific value line and both buttons', (
    tester,
  ) async {
    await tester.pumpWidget(harness(() {}));
    final context = tester.element(find.text('Open'));

    showRegisterSheet(
      context: context,
      valueLine: 'Create a free profile to follow Rohan',
      onContinueWithPhone: () {},
    );
    await tester.pumpAndSettle();

    expect(find.text('Create a free profile to follow Rohan'), findsOneWidget);
    expect(find.text('Continue with phone'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
  });

  testWidgets(
    'Continue with phone dismisses the sheet and calls the callback',
    (tester) async {
      var tapped = false;
      await tester.pumpWidget(harness(() {}));
      final context = tester.element(find.text('Open'));

      showRegisterSheet(
        context: context,
        valueLine: 'Create a free profile to follow Rohan',
        onContinueWithPhone: () => tapped = true,
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('registerSheetContinueWithPhone')),
      );
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      expect(find.text('Create a free profile to follow Rohan'), findsNothing);
    },
  );

  testWidgets('Not now dismisses the sheet without calling the callback', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(harness(() {}));
    final context = tester.element(find.text('Open'));

    showRegisterSheet(
      context: context,
      valueLine: 'Create a free profile to follow Rohan',
      onContinueWithPhone: () => tapped = true,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('registerSheetNotNow')));
    await tester.pumpAndSettle();

    expect(tapped, isFalse);
    expect(find.text('Create a free profile to follow Rohan'), findsNothing);
  });
}
