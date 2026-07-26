import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/profile/availability_models.dart';
import 'package:cricunity/profile/availability_provider.dart';
import 'package:cricunity/profile/availability_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness() => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showAvailabilitySheet(
              context: context,
              now: () => DateTime(2026, 3, 1),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );

  testWidgets('defaults to Available selected', (tester) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Injured'), findsOneWidget);
  });

  testWidgets('tapping Busy until... opens a date picker; picking a date '
      'updates the provider', (tester) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('availabilityOption_busy')));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);

    // Confirm today's pre-selected initial date in the native picker.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(ElevatedButton));
    final container = ProviderScope.containerOf(context);
    expect(
      container.read(availabilityProvider).status,
      AvailabilityStatus.busy,
    );
    expect(container.read(availabilityProvider).busyUntil, isNotNull);
  });

  testWidgets(
    'AC: selecting Injured sets the status and shows the Injury-log stub '
    'note (E16-05 not built yet)',
    (tester) async {
      await tester.pumpWidget(harness());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('availabilityInjuryLogStub')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('availabilityOption_injured')),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('availabilityInjuryLogStub')),
        findsOneWidget,
      );

      final context = tester.element(find.byType(ElevatedButton));
      final container = ProviderScope.containerOf(context);
      expect(
        container.read(availabilityProvider).status,
        AvailabilityStatus.injured,
      );
    },
  );

  testWidgets('switching back to Available clears the injured/busy status', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('availabilityOption_injured')));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('availabilityOption_available')),
    );
    await tester.pump();

    final context = tester.element(find.byType(ElevatedButton));
    final container = ProviderScope.containerOf(context);
    expect(
      container.read(availabilityProvider).status,
      AvailabilityStatus.available,
    );
  });
}
