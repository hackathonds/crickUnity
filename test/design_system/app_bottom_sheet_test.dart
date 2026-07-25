import 'package:cricunity/design_system/components/app_bottom_sheet.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness({required bool hasUnsavedInput}) {
    return MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showAppBottomSheet<void>(
                context: context,
                title: 'Test sheet',
                hasUnsavedInput: hasUnsavedInput,
                contentBuilder: (context) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('sheet content'),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'without unsaved input, dragging the grabber down dismisses the sheet',
    (tester) async {
      await tester.pumpWidget(harness(hasUnsavedInput: false));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Test sheet'), findsOneWidget);

      await tester.drag(
        find.byKey(const ValueKey('appBottomSheetGrabber')),
        const Offset(0, 120),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test sheet'), findsNothing);
    },
  );

  testWidgets(
    'with unsaved input, dragging the grabber down bounces and offers Save/Discard '
    '(the story AC)',
    (tester) async {
      await tester.pumpWidget(harness(hasUnsavedInput: true));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const ValueKey('appBottomSheetGrabber')),
        const Offset(0, 120),
      );
      await tester.pumpAndSettle();

      // The sheet is still open (bounced back), and a Save/Discard dialog
      // appeared instead of the sheet dismissing.
      expect(find.text('Test sheet'), findsOneWidget);
      expect(find.text('Save your changes?'), findsOneWidget);

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.text('Test sheet'), findsNothing);
    },
  );

  testWidgets(
    'a drag below the dismiss threshold does not trigger a dismiss attempt',
    (tester) async {
      await tester.pumpWidget(harness(hasUnsavedInput: false));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const ValueKey('appBottomSheetGrabber')),
        const Offset(0, 20),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test sheet'), findsOneWidget);
    },
  );
}
