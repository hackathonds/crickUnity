import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/teams/duty_roster_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness({required String viewerName}) => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: DutyRosterScreen(viewerName: viewerName),
    ),
  );

  testWidgets('a claimed slot shows the claimant, not a Claim button', (
    tester,
  ) async {
    await tester.pumpWidget(harness(viewerName: 'Kabir Singh'));

    expect(find.text('Priya Nair'), findsOneWidget);
    expect(find.byKey(const ValueKey('claimDutyButton_duty-1')), findsNothing);
  });

  testWidgets('an open slot shows a Claim button', (tester) async {
    await tester.pumpWidget(harness(viewerName: 'Kabir Singh'));

    expect(
      find.byKey(const ValueKey('claimDutyButton_duty-2')),
      findsOneWidget,
    );
  });

  testWidgets('claiming a slot replaces the button with the claimant', (
    tester,
  ) async {
    await tester.pumpWidget(harness(viewerName: 'Kabir Singh'));

    await tester.tap(find.byKey(const ValueKey('claimDutyButton_duty-2')));
    await tester.pump();

    expect(find.byKey(const ValueKey('claimDutyButton_duty-2')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('dutySlot_duty-2')),
        matching: find.text('Kabir Singh'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'AC: only the viewer who claimed a slot sees the Unclaim action',
    (tester) async {
      await tester.pumpWidget(harness(viewerName: 'Priya Nair'));
      expect(
        find.byKey(const ValueKey('unclaimDutyButton_duty-1')),
        findsOneWidget,
      );

      await tester.pumpWidget(harness(viewerName: 'Kabir Singh'));
      expect(
        find.byKey(const ValueKey('unclaimDutyButton_duty-1')),
        findsNothing,
      );
    },
  );
}
