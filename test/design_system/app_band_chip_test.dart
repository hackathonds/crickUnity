import 'package:cricunity/design_system/components/app_band_chip.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child) =>
      MaterialApp(theme: AppTheme.themes[AppTheme.defaultLight], home: child);

  testWidgets('renders the band label', (tester) async {
    await tester.pumpWidget(
      harness(
        const Scaffold(
          body: AppBandChip(kind: BandKind.trust, label: 'Reliable'),
        ),
      ),
    );

    expect(find.text('Reliable'), findsOneWidget);
  });

  testWidgets('tapping invokes onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      harness(
        Scaffold(
          body: AppBandChip(
            kind: BandKind.sportsmanship,
            label: 'Exemplary',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Exemplary'));
    expect(tapped, isTrue);
  });

  testWidgets(
    'a non-underReview chip and an underReview chip use different border '
    'widths (warning-outline)',
    (tester) async {
      await tester.pumpWidget(
        harness(
          const Scaffold(
            body: Column(
              children: [
                AppBandChip(kind: BandKind.trust, label: 'Reliable'),
                AppBandChip(
                  kind: BandKind.sportsmanship,
                  label: 'Under review',
                  isUnderReview: true,
                ),
              ],
            ),
          ),
        ),
      );

      final containers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.decoration is BoxDecoration)
          .toList();
      final decorations = containers
          .map((c) => c.decoration as BoxDecoration)
          .where((d) => d.borderRadius != null)
          .toList();

      expect(decorations.length, 2);
      final normalBorder = decorations[0].border as Border;
      final warningBorder = decorations[1].border as Border;
      expect(normalBorder.top.width, 1);
      expect(warningBorder.top.width, 1.5);
      expect(normalBorder.top.color, isNot(warningBorder.top.color));
    },
  );
}
