import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/teams/kit_inventory_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness({required String viewerName}) => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: KitInventoryScreen(viewerName: viewerName),
    ),
  );

  void setTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('the current custodian sees a Hand over button', (tester) async {
    setTallViewport(tester);
    await tester.pumpWidget(harness(viewerName: 'Kabir Singh'));

    expect(find.byKey(const ValueKey('handOverButton_kit-1')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('confirmHandoverButton_kit-1')),
      findsNothing,
    );
  });

  testWidgets('a non-custodian, non-recipient viewer sees no action', (
    tester,
  ) async {
    setTallViewport(tester);
    await tester.pumpWidget(harness(viewerName: 'Sana Iyer'));

    expect(find.byKey(const ValueKey('handOverButton_kit-1')), findsNothing);
    expect(
      find.byKey(const ValueKey('confirmHandoverButton_kit-1')),
      findsNothing,
    );
  });

  testWidgets('hand-over flow: picking a recipient marks the item pending, not '
      'yet transferred', (tester) async {
    setTallViewport(tester);
    await tester.pumpWidget(harness(viewerName: 'Kabir Singh'));

    await tester.tap(find.byKey(const ValueKey('handOverButton_kit-1')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('handoverRecipient_Sana Iyer')),
      findsOneWidget,
    );
    // The custodian is never offered as their own hand-over recipient.
    expect(
      find.byKey(const ValueKey('handoverRecipient_Kabir Singh')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('handoverRecipient_Sana Iyer')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining("Awaiting Sana Iyer's confirmation"),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('handOverButton_kit-1')), findsNothing);
  });

  testWidgets(
    'AC: only the pending recipient sees the Confirm receipt action',
    (tester) async {
      setTallViewport(tester);
      await tester.pumpWidget(harness(viewerName: 'Kabir Singh'));

      await tester.tap(find.byKey(const ValueKey('handOverButton_kit-1')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('handoverRecipient_Sana Iyer')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('confirmHandoverButton_kit-1')),
        findsNothing,
      );

      await tester.pumpWidget(harness(viewerName: 'Sana Iyer'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('confirmHandoverButton_kit-1')),
        findsOneWidget,
      );
    },
  );
}
