import 'package:cricunity/design_system/components/app_band_chip.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/profile/band_breakdown_screen.dart';
import 'package:cricunity/profile/trust_sportsmanship_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const factors = [
    BandFactor(
      label: 'Showed up when confirmed',
      trend: [0.6, 0.7, 0.8],
      howToImprove: 'Mark yourself Busy/Injured early if plans change.',
    ),
  ];

  Widget harness(Widget child) =>
      MaterialApp(theme: AppTheme.themes[AppTheme.defaultLight], home: child);

  testWidgets('renders factor label and how-to-improve text', (tester) async {
    await tester.pumpWidget(
      harness(
        const BandBreakdownScreen(
          kind: BandKind.trust,
          bandLabel: 'Reliable',
          factors: factors,
        ),
      ),
    );

    expect(find.text('Showed up when confirmed'), findsOneWidget);
    expect(
      find.text('Mark yourself Busy/Injured early if plans change.'),
      findsOneWidget,
    );
  });

  testWidgets('AC: no raw numeric trend value is ever rendered as text', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const BandBreakdownScreen(
          kind: BandKind.trust,
          bandLabel: 'Reliable',
          factors: factors,
        ),
      ),
    );

    for (final value in factors.first.trend) {
      expect(find.text(value.toString()), findsNothing);
      expect(find.text('$value'), findsNothing);
    }
  });

  testWidgets(
    'the decay explainer only shows when cleanDaysCount is provided',
    (tester) async {
      await tester.pumpWidget(
        harness(
          const BandBreakdownScreen(
            kind: BandKind.trust,
            bandLabel: 'Reliable',
            factors: factors,
            cleanDaysCount: 46,
          ),
        ),
      );

      expect(find.byKey(const ValueKey('bandDecayExplainer')), findsOneWidget);
      expect(find.textContaining('46 of 90'), findsOneWidget);
    },
  );

  testWidgets('no decay explainer when cleanDaysCount is null', (tester) async {
    await tester.pumpWidget(
      harness(
        const BandBreakdownScreen(
          kind: BandKind.sportsmanship,
          bandLabel: 'Exemplary',
          factors: factors,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('bandDecayExplainer')), findsNothing);
  });

  testWidgets('the appeal button only shows when appealable, and shows an '
      'explainer snackbar on tap', (tester) async {
    await tester.pumpWidget(
      harness(
        const BandBreakdownScreen(
          kind: BandKind.sportsmanship,
          bandLabel: 'Exemplary',
          factors: factors,
          appealable: true,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('bandAppealButton')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bandAppealButton')));
    await tester.pump();

    expect(find.textContaining('dispute review'), findsOneWidget);
  });

  testWidgets('no appeal button when not appealable (Trust)', (tester) async {
    await tester.pumpWidget(
      harness(
        const BandBreakdownScreen(
          kind: BandKind.trust,
          bandLabel: 'Reliable',
          factors: factors,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('bandAppealButton')), findsNothing);
  });
}
