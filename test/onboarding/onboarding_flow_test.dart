import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/onboarding/onboarding_flow.dart';
import 'package:cricunity/onboarding/registration_flow_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness({
    VoidCallback? onExploreAsGuest,
    VoidCallback? onContactSupport,
    bool showDebugSimulateApproval = false,
  }) => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: OnboardingFlow(
        onExploreAsGuest: onExploreAsGuest ?? () {},
        onContactSupport: onContactSupport ?? () {},
        showDebugSimulateApproval: showDebugSimulateApproval,
      ),
    ),
  );

  Future<void> enterAndSubmitOtp(WidgetTester tester) async {
    for (var i = 0; i < demoCorrectOtp.length; i++) {
      await tester.enterText(
        find.byKey(ValueKey('otpCell$i')),
        demoCorrectOtp[i],
      );
      await tester.pump();
    }
  }

  Future<void> selectDropdown(
    WidgetTester tester,
    Key fieldKey,
    String optionText,
  ) async {
    await tester.tap(find.byKey(fieldKey));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('appTextFieldInput')),
      optionText,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(optionText).last);
    await tester.pumpAndSettle();
  }

  Future<void> submitDob(
    WidgetTester tester, {
    required String day,
    required String month,
    required String year,
  }) async {
    await selectDropdown(tester, const ValueKey('dobDayField'), day);
    await selectDropdown(tester, const ValueKey('dobMonthField'), month);
    await selectDropdown(tester, const ValueKey('dobYearField'), year);
    await tester.tap(find.byKey(const ValueKey('dobStepContinue')));
    await tester.pumpAndSettle();
  }

  Future<void> walkToDobStep(
    WidgetTester tester, {
    String phone = '7000000000',
  }) async {
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('appTextFieldInput')),
      phone,
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('phoneEntryContinue')));
    await tester.pumpAndSettle();
    await enterAndSubmitOtp(tester);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('appTextFieldInput')),
      'Priya Nair',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nameEntryContinue')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'an adult walks Welcome -> Phone -> OTP -> Name -> DOB -> completion, '
    'skipping the guardian gate',
    (tester) async {
      await tester.pumpWidget(harness());

      await walkToDobStep(tester);
      expect(find.text("What's your date of birth?"), findsOneWidget);

      final adultYear = (DateTime.now().year - 25).toString();
      await submitDob(tester, day: '15', month: 'June', year: adultYear);

      expect(find.text("You're all set, Priya Nair!"), findsOneWidget);
      expect(
        find.text('A parent or guardian needs to approve your account'),
        findsNothing,
      );
    },
  );

  testWidgets('a minor walks the guardian gate to a Private+ completion', (
    tester,
  ) async {
    await tester.pumpWidget(harness(showDebugSimulateApproval: true));

    await walkToDobStep(tester);
    final minorYear = (DateTime.now().year - 12).toString();
    await submitDob(tester, day: '15', month: 'June', year: minorYear);

    expect(
      find.text('A parent or guardian needs to approve your account'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('guardianExplainerContinue')));
    await tester.pumpAndSettle();

    expect(find.text("What's your guardian's phone number?"), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('appTextFieldInput')),
      '9000000000',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('guardianContactSend')));
    await tester.pumpAndSettle();

    expect(find.text('Waiting for guardian approval'), findsOneWidget);

    // AC: no other screen is reachable while consent is pending.
    final popScope = tester.widget<PopScope>(find.byType(PopScope));
    expect(popScope.canPop, isFalse);

    await tester.tap(
      find.byKey(const ValueKey('guardianWaitingSimulateApproval')),
    );
    await tester.pumpAndSettle();

    expect(find.text("You're all set, Priya Nair!"), findsOneWidget);
    expect(
      find.textContaining("we've set your profile to Private+"),
      findsOneWidget,
    );
  });

  testWidgets(
    'an existing-account phone skips DOB and the Name step straight to '
    'Welcome back',
    (tester) async {
      await tester.pumpWidget(harness());

      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('appTextFieldInput')),
        existingAccountPhones.first,
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('phoneEntryContinue')));
      await tester.pumpAndSettle();

      await enterAndSubmitOtp(tester);
      await tester.pumpAndSettle();

      expect(find.text('Welcome back!'), findsOneWidget);
      expect(find.text("What's your name?"), findsNothing);
      expect(find.text("What's your date of birth?"), findsNothing);
    },
  );

  testWidgets('Explore first invokes onExploreAsGuest from the Welcome step', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(harness(onExploreAsGuest: () => tapped = true));

    await tester.tap(find.text('Explore first'));

    expect(tapped, isTrue);
  });

  testWidgets('Done on the completion screen pops back to the flow root', (
    tester,
  ) async {
    await tester.pumpWidget(harness());

    await walkToDobStep(tester);
    final adultYear = (DateTime.now().year - 25).toString();
    await submitDob(tester, day: '15', month: 'June', year: adultYear);

    await tester.tap(find.byKey(const ValueKey('registrationCompleteDone')));
    await tester.pumpAndSettle();

    expect(find.text('Your career, verified'), findsOneWidget);
  });
}
