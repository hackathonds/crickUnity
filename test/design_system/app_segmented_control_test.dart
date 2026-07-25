import 'package:cricunity/design_system/components/app_button.dart';
import 'package:cricunity/design_system/components/app_segmented_control.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: Scaffold(body: child),
  );

  testWidgets('2-4 options render the sliding track, not chips', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        AppSegmentedControl<String>(
          options: const ['A', 'B', 'C'],
          value: 'A',
          labelBuilder: (v) => v,
          onChanged: (_) {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('appSegmentedControlTrack')),
      findsOneWidget,
    );
    expect(find.byType(AppChipActionButton), findsNothing);
  });

  testWidgets('tapping a segment calls onChanged with that option', (
    tester,
  ) async {
    String? changed;
    await tester.pumpWidget(
      harness(
        AppSegmentedControl<String>(
          options: const ['A', 'B', 'C'],
          value: 'A',
          labelBuilder: (v) => v,
          onChanged: (v) => changed = v,
        ),
      ),
    );

    await tester.tap(find.text('B'));
    expect(changed, 'B');
  });

  testWidgets('the thumb is positioned under the selected segment', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        AppSegmentedControl<String>(
          options: const ['A', 'B', 'C'],
          value: 'B',
          labelBuilder: (v) => v,
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final trackBox = tester.getRect(
      find.byKey(const ValueKey('appSegmentedControlTrack')),
    );
    final thumbBox = tester.getRect(
      find.byKey(const ValueKey('appSegmentedControlThumb')),
    );

    final segmentWidth = trackBox.width / 3;
    expect(thumbBox.left - trackBox.left, closeTo(segmentWidth * 1, 1.0));
  });

  testWidgets(
    '5+ options render a scrollable chip row with the current value selected',
    (tester) async {
      await tester.pumpWidget(
        harness(
          AppSegmentedControl<String>(
            options: const ['A', 'B', 'C', 'D', 'E'],
            value: 'C',
            labelBuilder: (v) => v,
            onChanged: (_) {},
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('appSegmentedControlChipRow')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('appSegmentedControlTrack')),
        findsNothing,
      );
      expect(find.byType(AppChipActionButton), findsNWidgets(5));

      final chipC = tester.widget<AppChipActionButton>(
        find.widgetWithText(AppChipActionButton, 'C'),
      );
      expect(chipC.selected, isTrue);

      final chipA = tester.widget<AppChipActionButton>(
        find.widgetWithText(AppChipActionButton, 'A'),
      );
      expect(chipA.selected, isFalse);
    },
  );

  testWidgets('tapping a chip in the fallback row calls onChanged', (
    tester,
  ) async {
    String? changed;
    await tester.pumpWidget(
      harness(
        AppSegmentedControl<String>(
          options: const ['A', 'B', 'C', 'D', 'E'],
          value: 'A',
          labelBuilder: (v) => v,
          onChanged: (v) => changed = v,
        ),
      ),
    );

    await tester.tap(find.text('D'));
    expect(changed, 'D');
  });

  test('asserts at least 2 options', () {
    expect(
      () => AppSegmentedControl<String>(
        options: const ['A'],
        value: 'A',
        labelBuilder: (v) => v,
        onChanged: (_) {},
      ),
      throwsAssertionError,
    );
  });
}
