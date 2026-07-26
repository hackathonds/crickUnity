import 'package:cricunity/design_system/components/app_button.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/onboarding/permissions_primer_screen.dart';
import 'package:cricunity/onboarding/permissions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(VoidCallback onContinue) => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: PermissionsPrimerScreen(onContinue: onContinue),
    ),
  );

  testWidgets('Continue is disabled until both permissions are decided', (
    tester,
  ) async {
    await tester.pumpWidget(harness(() {}));

    var button = tester.widget<AppButton>(
      find.byKey(const ValueKey('permissionsPrimerContinue')),
    );
    expect(button.onPressed, isNull);

    await tester.tap(
      find.byKey(const ValueKey('permissionCardAllow_location')),
    );
    await tester.pump();

    button = tester.widget<AppButton>(
      find.byKey(const ValueKey('permissionsPrimerContinue')),
    );
    expect(button.onPressed, isNull);

    await tester.tap(
      find.byKey(const ValueKey('permissionCardLater_notifications')),
    );
    await tester.pump();

    button = tester.widget<AppButton>(
      find.byKey(const ValueKey('permissionsPrimerContinue')),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('Allow/Later write independent statuses to the provider', (
    tester,
  ) async {
    await tester.pumpWidget(harness(() {}));

    await tester.tap(
      find.byKey(const ValueKey('permissionCardAllow_location')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('permissionCardLater_notifications')),
    );
    await tester.pump();

    final context = tester.element(find.byType(PermissionsPrimerScreen));
    final container = ProviderScope.containerOf(context);
    final state = container.read(permissionsProvider);
    expect(state.location, PermissionStatus.granted);
    expect(state.notifications, PermissionStatus.denied);
    expect(find.text('Allowed'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
  });

  testWidgets('Continue fires once both are decided', (tester) async {
    var continued = false;
    await tester.pumpWidget(harness(() => continued = true));

    await tester.tap(
      find.byKey(const ValueKey('permissionCardAllow_location')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('permissionCardAllow_notifications')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('permissionsPrimerContinue')));
    await tester.pump();

    expect(continued, isTrue);
  });
}
