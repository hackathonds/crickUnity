import 'package:cricunity/design_system/components/app_dropdown_field.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: Scaffold(body: child),
  );

  const fewOptions = ['T20', 'ODI', 'Test', 'T10'];
  const manyOptions = [
    'Green Park',
    'Oval Maidan',
    'City Stadium',
    'Riverside Ground',
    'Hill View Turf',
    'Central Park Pitch',
    'Lakeside Arena',
    'Sunrise Ground',
    'Community Field',
    'Eastside Turf',
  ];

  testWidgets('tapping the field opens the sheet with a row per option', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        AppDropdownField<String>(
          label: 'Format',
          value: null,
          options: fewOptions,
          labelBuilder: (v) => v,
          onChanged: (_) {},
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('appDropdownFieldBox')));
    await tester.pumpAndSettle();

    for (final option in fewOptions) {
      expect(find.text(option), findsOneWidget);
    }
  });

  testWidgets('no search row when options.length <= 8', (tester) async {
    await tester.pumpWidget(
      harness(
        AppDropdownField<String>(
          label: 'Format',
          value: null,
          options: fewOptions,
          labelBuilder: (v) => v,
          onChanged: (_) {},
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('appDropdownFieldBox')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('appDropdownSearchField')), findsNothing);
  });

  testWidgets('search row appears when options.length > 8', (tester) async {
    await tester.pumpWidget(
      harness(
        AppDropdownField<String>(
          label: 'Ground',
          value: null,
          options: manyOptions,
          labelBuilder: (v) => v,
          onChanged: (_) {},
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('appDropdownFieldBox')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('appDropdownSearchField')),
      findsOneWidget,
    );
  });

  testWidgets('typing in the search row filters the visible rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        AppDropdownField<String>(
          label: 'Ground',
          value: null,
          options: manyOptions,
          labelBuilder: (v) => v,
          onChanged: (_) {},
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('appDropdownFieldBox')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('appDropdownSearchField')),
        matching: find.byType(TextField),
      ),
      'park',
    );
    await tester.pump();

    expect(find.text('Green Park'), findsOneWidget);
    expect(find.text('Central Park Pitch'), findsOneWidget);
    expect(find.text('Oval Maidan'), findsNothing);
  });

  testWidgets('selecting a row calls onChanged and closes the sheet', (
    tester,
  ) async {
    String? changed;
    await tester.pumpWidget(
      harness(
        AppDropdownField<String>(
          label: 'Format',
          value: null,
          options: fewOptions,
          labelBuilder: (v) => v,
          onChanged: (v) => changed = v,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('appDropdownFieldBox')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ODI'));
    await tester.pumpAndSettle();

    expect(changed, 'ODI');
    expect(find.text('ODI'), findsNothing); // sheet closed, no row visible
  });

  testWidgets('the selected value renders on the closed field', (tester) async {
    await tester.pumpWidget(
      harness(
        AppDropdownField<String>(
          label: 'Format',
          value: 'Test',
          options: fewOptions,
          labelBuilder: (v) => v,
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Test'), findsOneWidget);
  });
}
