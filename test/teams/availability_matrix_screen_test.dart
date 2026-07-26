import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/teams/availability_matrix_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixedNow = DateTime(2026, 3, 1, 9);

  Widget harness() => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: AvailabilityMatrixScreen(now: () => fixedNow),
    ),
  );

  testWidgets('renders every member name and event label', (tester) async {
    await tester.pumpWidget(harness());

    expect(find.text('Priya Nair'), findsOneWidget);
    expect(find.text('vs Titans, Sun'), findsOneWidget);
  });

  testWidgets('AC: a cell with no response yet renders blank, not a glyph', (
    tester,
  ) async {
    await tester.pumpWidget(harness());

    // Farhan Ali has no response for evt-1 in the mock data.
    final cell = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('matrixCell_Farhan Ali_evt-1')),
        matching: find.byType(Text),
      ),
    );
    expect(cell.data, isEmpty);
  });

  testWidgets('tapping a cell shows a detail popover with the response', (
    tester,
  ) async {
    await tester.pumpWidget(harness());

    await tester.tap(find.byKey(const ValueKey('matrixCell_Priya Nair_evt-1')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('matrixCellDetailDialog')),
      findsOneWidget,
    );
    expect(find.textContaining('Available'), findsOneWidget);
  });

  testWidgets(
    'AC: the footer summary counts each response type for that event',
    (tester) async {
      await tester.pumpWidget(harness());

      // evt-1 mock: Priya=yes, Kabir=yes, Ananya=maybe, Farhan=(none).
      expect(find.text('2 ✔ · 1 ❓ · 0 ✖'), findsOneWidget);
    },
  );

  testWidgets(
    'AC: the nudge button is enabled until used, then disabled for 12h',
    (tester) async {
      await tester.pumpWidget(harness());

      final before = tester.widget<TextButton>(
        find.byKey(const ValueKey('nudgeButton_evt-1')),
      );
      expect(before.onPressed, isNotNull);

      await tester.tap(find.byKey(const ValueKey('nudgeButton_evt-1')));
      await tester.pump();

      final after = tester.widget<TextButton>(
        find.byKey(const ValueKey('nudgeButton_evt-1')),
      );
      expect(after.onPressed, isNull);
    },
  );

  testWidgets('nudging one event does not disable the other event\'s button', (
    tester,
  ) async {
    await tester.pumpWidget(harness());

    await tester.tap(find.byKey(const ValueKey('nudgeButton_evt-1')));
    await tester.pump();

    final other = tester.widget<TextButton>(
      find.byKey(const ValueKey('nudgeButton_evt-2')),
    );
    expect(other.onPressed, isNotNull);
  });
}
