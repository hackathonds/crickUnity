import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/onboarding/otp_screen.dart';
import 'package:cricunity/onboarding/registration_flow_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpHarness(
    WidgetTester tester, {
    required void Function(bool isExistingAccount) onVerified,
    required VoidCallback onContactSupport,
    DateTime Function()? now,
    String phone = '7000000000',
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.themes[AppTheme.defaultLight],
          home: _PhoneSeededOtpScreen(
            phone: phone,
            onVerified: onVerified,
            onContactSupport: onContactSupport,
            now: now,
          ),
        ),
      ),
    );
    // submitPhone is seeded via a microtask (see _PhoneSeededOtpScreen) --
    // give it a frame to land before assertions/interactions.
    await tester.pump();
  }

  Finder cell(int i) => find.byKey(ValueKey('otpCell$i'));

  bool cellHasFocus(WidgetTester tester, int i) {
    final field = tester.widget<TextField>(
      find.descendant(of: cell(i), matching: find.byType(TextField)),
    );
    return field.focusNode!.hasFocus;
  }

  Future<void> typeDigit(WidgetTester tester, int index, String digit) async {
    await tester.enterText(cell(index), digit);
    await tester.pump();
  }

  testWidgets('typing a digit auto-advances focus to the next cell', (
    tester,
  ) async {
    await pumpHarness(tester, onVerified: (_) {}, onContactSupport: () {});

    await typeDigit(tester, 0, '1');

    expect(cellHasFocus(tester, 1), isTrue);
  });

  testWidgets(
    'backspace on an empty cell moves focus back to the previous cell',
    (tester) async {
      await pumpHarness(tester, onVerified: (_) {}, onContactSupport: () {});

      await typeDigit(tester, 0, '1');
      // Cell 1 is now focused and empty; simulate backspace.
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      expect(cellHasFocus(tester, 0), isTrue);
    },
  );

  testWidgets('resend is disabled with a 30s countdown right after sending', (
    tester,
  ) async {
    // codeSentAt is set with the real DateTime.now() inside the provider,
    // so the fake clock has to start near real "now" too -- an arbitrary
    // fixed date would make the elapsed-time diff wildly (and wrongly)
    // negative or huge.
    final fixedNow = DateTime.now();
    await pumpHarness(
      tester,
      onVerified: (_) {},
      onContactSupport: () {},
      now: () => fixedNow,
    );

    expect(find.text('Resend code in 30s'), findsOneWidget);
    final button = tester.widget<TextButton>(
      find.byKey(const ValueKey('otpResendButton')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('resend becomes enabled once 30s have elapsed', (tester) async {
    var fakeNow = DateTime.now();
    await pumpHarness(
      tester,
      onVerified: (_) {},
      onContactSupport: () {},
      now: () => fakeNow,
    );

    fakeNow = fakeNow.add(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 31));

    final button = tester.widget<TextButton>(
      find.byKey(const ValueKey('otpResendButton')),
    );
    expect(button.onPressed, isNotNull);
    expect(find.text('Resend code'), findsOneWidget);
  });

  testWidgets('the correct demo code verifies a new account', (tester) async {
    bool? existingResult;
    await pumpHarness(
      tester,
      onVerified: (isExisting) => existingResult = isExisting,
      onContactSupport: () {},
    );

    for (var i = 0; i < demoCorrectOtp.length; i++) {
      await typeDigit(tester, i, demoCorrectOtp[i]);
    }

    expect(existingResult, isFalse);
  });

  testWidgets('the correct demo code on an existing-account phone reports '
      'isExistingAccount', (tester) async {
    bool? existingResult;
    await pumpHarness(
      tester,
      onVerified: (isExisting) => existingResult = isExisting,
      onContactSupport: () {},
      phone: existingAccountPhones.first,
    );

    for (var i = 0; i < demoCorrectOtp.length; i++) {
      await typeDigit(tester, i, demoCorrectOtp[i]);
    }

    expect(existingResult, isTrue);
  });

  testWidgets('an incorrect code shows an inline error and clears the cells', (
    tester,
  ) async {
    await pumpHarness(tester, onVerified: (_) {}, onContactSupport: () {});

    for (var i = 0; i < 6; i++) {
      await typeDigit(tester, i, '1');
    }

    expect(find.text('Incorrect code, try again.'), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      final textField = tester.widget<TextField>(
        find.descendant(of: cell(i), matching: find.byType(TextField)),
      );
      expect(textField.controller!.text, isEmpty);
    }
  });

  testWidgets('3 incorrect attempts replace the cells with a cooldown notice '
      'and a support link', (tester) async {
    var supportTapped = false;
    await pumpHarness(
      tester,
      onVerified: (_) {},
      onContactSupport: () => supportTapped = true,
    );

    for (var attempt = 0; attempt < 3; attempt++) {
      for (var i = 0; i < 6; i++) {
        await typeDigit(tester, i, '1');
      }
    }

    expect(find.byKey(const ValueKey('otpCooldownNotice')), findsOneWidget);
    expect(find.byKey(const ValueKey('otpCells')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('otpContactSupportButton')));
    expect(supportTapped, isTrue);
  });
}

/// Seeds registrationFlowProvider with a phone (as PhoneEntryScreen would)
/// before mounting [OtpScreen], since the provider's phone/codeSentAt drive
/// the screen's copy and countdown.
class _PhoneSeededOtpScreen extends ConsumerStatefulWidget {
  final String phone;
  final void Function(bool isExistingAccount) onVerified;
  final VoidCallback onContactSupport;
  final DateTime Function()? now;

  const _PhoneSeededOtpScreen({
    required this.phone,
    required this.onVerified,
    required this.onContactSupport,
    this.now,
  });

  @override
  ConsumerState<_PhoneSeededOtpScreen> createState() =>
      _PhoneSeededOtpScreenState();
}

class _PhoneSeededOtpScreenState extends ConsumerState<_PhoneSeededOtpScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () =>
          ref.read(registrationFlowProvider.notifier).submitPhone(widget.phone),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OtpScreen(
      onVerified: widget.onVerified,
      onContactSupport: widget.onContactSupport,
      now: widget.now ?? DateTime.now,
    );
  }
}
