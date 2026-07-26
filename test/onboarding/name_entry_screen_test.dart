import 'package:cricunity/design_system/components/app_button.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/onboarding/name_entry_screen.dart';
import 'package:cricunity/onboarding/registration_flow_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(ValueChanged<String> onContinue) => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: NameEntryScreen(onContinue: onContinue),
    ),
  );

  testWidgets('Continue is disabled until a name is entered', (tester) async {
    await tester.pumpWidget(harness((_) {}));

    final button = tester.widget<AppButton>(
      find.byKey(const ValueKey('nameEntryContinue')),
    );
    expect(button.onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('appTextFieldInput')),
      'Priya Nair',
    );
    await tester.pump();

    final enabledButton = tester.widget<AppButton>(
      find.byKey(const ValueKey('nameEntryContinue')),
    );
    expect(enabledButton.onPressed, isNotNull);
  });

  testWidgets('Continue stores the trimmed name and calls onContinue', (
    tester,
  ) async {
    String? continued;
    await tester.pumpWidget(harness((name) => continued = name));

    await tester.enterText(
      find.byKey(const ValueKey('appTextFieldInput')),
      '  Priya Nair  ',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nameEntryContinue')));
    await tester.pump();

    expect(continued, 'Priya Nair');

    final context = tester.element(find.byType(NameEntryScreen));
    final container = ProviderScope.containerOf(context);
    expect(container.read(registrationFlowProvider).name, 'Priya Nair');
  });
}
