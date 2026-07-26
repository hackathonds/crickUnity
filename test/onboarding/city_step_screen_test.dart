import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/onboarding/city_step_screen.dart';
import 'package:cricunity/onboarding/profile_wizard_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(VoidCallback onContinue) => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: CityStepScreen(onContinue: onContinue),
    ),
  );

  testWidgets('selecting a city stores it in the provider', (tester) async {
    await tester.pumpWidget(harness(() {}));

    await tester.tap(find.byKey(const ValueKey('cityStepField')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('appTextFieldInput')),
      'Pune',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pune').last);
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(CityStepScreen));
    final container = ProviderScope.containerOf(context);
    expect(container.read(profileWizardProvider).city, 'Pune');
  });

  testWidgets('Continue is always enabled, even with no city chosen', (
    tester,
  ) async {
    var continued = false;
    await tester.pumpWidget(harness(() => continued = true));

    await tester.tap(find.byKey(const ValueKey('cityStepContinue')));
    await tester.pump();

    expect(continued, isTrue);
  });
}
