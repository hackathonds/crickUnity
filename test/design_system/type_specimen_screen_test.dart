import 'package:cricunity/design_system/debug/type_specimen_screen.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const roleLabels = [
    'Display',
    'H1',
    'H2',
    'Title',
    'Subtitle',
    'Body',
    'Caption',
    'Label',
    'Button',
    'Stat',
    'Scoreboard',
    'Money',
    'Tabular alignment (Stat)',
  ];

  testWidgets('renders every type role for QA', (tester) async {
    // The specimen list is long enough that a normal test-sized viewport
    // would only build items near the visible sliver area — make the
    // surface tall enough that the whole list is in view at once.
    tester.view.physicalSize = const Size(400, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themes[AppTheme.defaultLight],
        home: const TypeSpecimenScreen(),
      ),
    );

    for (final label in roleLabels) {
      expect(find.text(label), findsOneWidget, reason: 'missing role: $label');
    }
  });

  testWidgets('scaling to 135% does not throw or overflow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themes[AppTheme.defaultLight],
        home: const TypeSpecimenScreen(),
      ),
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
