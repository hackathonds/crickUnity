import 'package:cricunity/design_system/components/app_dialog.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget typedConfirmHarness() {
    return MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => showAppTypedConfirmDialog(
              context: context,
              title: 'Delete team',
              body: 'This cannot be undone.',
              confirmPhrase: 'DELETE',
            ),
            child: const Text('open typed'),
          ),
        ),
      ),
    );
  }

  testWidgets(
    "typed-confirm's destructive action stays disabled until the typed text matches exactly",
    (tester) async {
      await tester.pumpWidget(typedConfirmHarness());
      await tester.tap(find.text('open typed'));
      await tester.pumpAndSettle();

      TextButton deleteButton() => tester.widget<TextButton>(
        find.ancestor(
          of: find.text('Delete'),
          matching: find.byType(TextButton),
        ),
      );

      expect(deleteButton().onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'DEL');
      await tester.pump();
      expect(deleteButton().onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'DELETE');
      await tester.pump();
      expect(deleteButton().onPressed, isNotNull);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete team'), findsNothing);
    },
  );

  testWidgets(
    'attempting to open a second dialog while one is open is a no-op',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themes[AppTheme.defaultLight],
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  showAppConfirmDialog(
                    context: context,
                    title: 'First',
                    body: 'first body',
                  );
                  showAppTypedConfirmDialog(
                    context: context,
                    title: 'Second',
                    body: 'second body',
                    confirmPhrase: 'X',
                  );
                },
                child: const Text('open both'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open both'));
      await tester.pumpAndSettle();

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsNothing);
      expect(find.byType(Dialog), findsOneWidget);
    },
  );
}
