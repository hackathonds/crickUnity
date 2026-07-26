import 'package:cricunity/design_system/components/app_button.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/onboarding/guardian_contact_screen.dart';
import 'package:cricunity/onboarding/guardian_gate_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(VoidCallback onSent) => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: GuardianContactScreen(onSent: onSent),
    ),
  );

  testWidgets('Send request is disabled until a 10-digit phone is entered', (
    tester,
  ) async {
    await tester.pumpWidget(harness(() {}));

    final button = tester.widget<AppButton>(
      find.byKey(const ValueKey('guardianContactSend')),
    );
    expect(button.onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('appTextFieldInput')),
      '9000000000',
    );
    await tester.pump();

    final enabledButton = tester.widget<AppButton>(
      find.byKey(const ValueKey('guardianContactSend')),
    );
    expect(enabledButton.onPressed, isNotNull);
  });

  testWidgets(
    'Send request stores the guardian phone in the provider and calls onSent',
    (tester) async {
      var sent = false;
      await tester.pumpWidget(harness(() => sent = true));

      await tester.enterText(
        find.byKey(const ValueKey('appTextFieldInput')),
        '9000000000',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('guardianContactSend')));
      await tester.pump();

      expect(sent, isTrue);
      final context = tester.element(find.byType(GuardianContactScreen));
      final container = ProviderScope.containerOf(context);
      expect(container.read(guardianGateProvider).guardianPhone, '9000000000');
    },
  );
}
