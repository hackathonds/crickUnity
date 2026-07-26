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
  }) => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: OnboardingFlow(
        onExploreAsGuest: onExploreAsGuest ?? () {},
        onContactSupport: onContactSupport ?? () {},
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

  testWidgets(
    'a new account walks Welcome -> Phone -> OTP -> Name -> Welcome-all-set',
    (tester) async {
      await tester.pumpWidget(harness());

      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
      expect(find.text("What's your phone number?"), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('appTextFieldInput')),
        '7000000000',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('phoneEntryContinue')));
      await tester.pumpAndSettle();
      expect(find.text('Enter the code'), findsOneWidget);

      await enterAndSubmitOtp(tester);
      await tester.pumpAndSettle();
      expect(find.text("What's your name?"), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('appTextFieldInput')),
        'Priya Nair',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('nameEntryContinue')));
      await tester.pumpAndSettle();

      expect(find.text("You're all set, Priya Nair!"), findsOneWidget);
    },
  );

  testWidgets(
    'an existing-account phone skips the Name step straight to Welcome back',
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

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('appTextFieldInput')),
      '7000000000',
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

    await tester.tap(find.byKey(const ValueKey('registrationCompleteDone')));
    await tester.pumpAndSettle();

    expect(find.text('Your career, verified'), findsOneWidget);
  });
}
