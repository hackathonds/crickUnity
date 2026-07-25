import 'package:cricunity/design_system/components/app_snackbar.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showing a second snackbar replaces the first', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themes[AppTheme.defaultLight],
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                showAppSnackbar(context, 'First message');
                showAppSnackbar(context, 'Second message');
              },
              child: const Text('show'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Second message'), findsOneWidget);
    expect(find.text('First message'), findsNothing);
  });

  testWidgets('the action button fires its callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themes[AppTheme.defaultLight],
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showAppSnackbar(
                context,
                'Item removed',
                actionLabel: 'UNDO',
                onAction: () => tapped = true,
              ),
              child: const Text('show'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();
    // Let the snackbar's entrance animation finish so it's hit-testable,
    // without pumpAndSettle (which would wait out the full 5s auto-dismiss).
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('UNDO'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
