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
    VoidCallback? onOnboardingComplete,
    bool showDebugSimulateApproval = false,
  }) => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: OnboardingFlow(
        onExploreAsGuest: onExploreAsGuest ?? () {},
        onContactSupport: onContactSupport ?? () {},
        onOnboardingComplete: onOnboardingComplete ?? () {},
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

  /// From the Photo step (start of the Profile wizard) through to the
  /// Warm-up screen's Done, skipping every optional field.
  Future<void> walkThroughProfileWizardToDone(WidgetTester tester) async {
    expect(find.text('Add a profile photo'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('photoStepSkip')));
    await tester.pumpAndSettle();

    expect(find.text("What's your city?"), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cityStepContinue')));
    await tester.pumpAndSettle();

    expect(find.text('How do you play?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('playingInfoContinue')));
    await tester.pumpAndSettle();

    expect(find.text('Stay in the loop'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('permissionCardAllow_location')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('permissionCardAllow_notifications')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('permissionsPrimerContinue')));
    await tester.pumpAndSettle();

    expect(find.text('Follow some players'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('warmUpDone')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'an adult walks the whole flow to onOnboardingComplete, skipping the '
    'guardian gate',
    (tester) async {
      var complete = false;
      await tester.pumpWidget(
        harness(onOnboardingComplete: () => complete = true),
      );

      await walkToDobStep(tester);
      expect(find.text("What's your date of birth?"), findsOneWidget);

      final adultYear = (DateTime.now().year - 25).toString();
      await submitDob(tester, day: '15', month: 'June', year: adultYear);

      expect(
        find.text('A parent or guardian needs to approve your account'),
        findsNothing,
      );
      await walkThroughProfileWizardToDone(tester);

      expect(complete, isTrue);
    },
  );

  testWidgets('a minor walks the guardian gate, then the profile wizard, to '
      'onOnboardingComplete', (tester) async {
    var complete = false;
    await tester.pumpWidget(
      harness(
        showDebugSimulateApproval: true,
        onOnboardingComplete: () => complete = true,
      ),
    );

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

    await walkThroughProfileWizardToDone(tester);

    expect(complete, isTrue);
  });

  testWidgets(
    'an existing-account phone skips DOB, Name, and the Profile wizard '
    'straight to Welcome back',
    (tester) async {
      var complete = false;
      await tester.pumpWidget(
        harness(onOnboardingComplete: () => complete = true),
      );

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

      await tester.tap(find.byKey(const ValueKey('registrationCompleteDone')));
      await tester.pump();

      expect(complete, isTrue);
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
}
