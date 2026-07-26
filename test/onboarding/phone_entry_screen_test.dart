import 'package:cricunity/design_system/components/app_button.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/onboarding/phone_entry_screen.dart';
import 'package:cricunity/onboarding/registration_flow_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(ValueChanged<String> onContinue) => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: PhoneEntryScreen(onContinue: onContinue),
    ),
  );

  testWidgets('Continue is disabled until a 10-digit phone is entered', (
    tester,
  ) async {
    await tester.pumpWidget(harness((_) {}));

    final button = tester.widget<AppButton>(
      find.byKey(const ValueKey('phoneEntryContinue')),
    );
    expect(button.onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('appTextFieldInput')),
      '9000000000',
    );
    await tester.pump();

    final enabledButton = tester.widget<AppButton>(
      find.byKey(const ValueKey('phoneEntryContinue')),
    );
    expect(enabledButton.onPressed, isNotNull);
  });

  testWidgets(
    'Continue stores the phone in the provider and calls onContinue',
    (tester) async {
      String? continued;
      await tester.pumpWidget(harness((phone) => continued = phone));

      await tester.enterText(
        find.byKey(const ValueKey('appTextFieldInput')),
        '9000000000',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('phoneEntryContinue')));
      await tester.pump();

      expect(continued, '9000000000');

      final context = tester.element(find.byType(PhoneEntryScreen));
      final container = ProviderScope.containerOf(context);
      expect(container.read(registrationFlowProvider).phone, '9000000000');
    },
  );
}
