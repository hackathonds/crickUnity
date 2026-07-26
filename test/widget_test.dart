import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/design_system/tokens/app_colors.dart';
import 'package:cricunity/design_system/tokens/app_motion.dart';
import 'package:cricunity/main.dart';
import 'package:cricunity/navigation/app_router.dart';
import 'package:cricunity/navigation/app_shell.dart';
import 'package:cricunity/settings/appearance_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots with the default light theme applied', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CricUnityApp(startWithOnboardingComplete: true),
      ),
    );
    await tester.pump();

    expect(find.byType(CricUnityApp), findsOneWidget);
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets(
    'app-wide text scale is clamped to 135% even if the OS reports more',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(3.0)),
            child: CricUnityApp(startWithOnboardingComplete: true),
          ),
        ),
      );
      await tester.pump();

      final context = tester.element(find.byType(AppShell));
      final effectiveScaler = MediaQuery.of(context).textScaler;
      expect(
        effectiveScaler.scale(100),
        const TextScaler.linear(1.35).scale(100),
      );
    },
  );

  testWidgets(
    'an explicit theme override wins over the system brightness (E0-09)',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(platformBrightness: Brightness.dark),
            child: CricUnityApp(
              router: createAppRouter(),
              startWithOnboardingComplete: true,
            ),
          ),
        ),
      );
      await tester.pump();

      final context = tester.element(find.byType(AppShell));
      final container = ProviderScope.containerOf(context);
      container
          .read(appearanceSettingsProvider.notifier)
          .setThemeOverride(AppThemeId.theme5);
      // MaterialApp wraps content in an implicit AnimatedTheme, so a
      // zero-duration pump() still reports the pre-change theme mid-fade --
      // pumpAndSettle lets that transition finish.
      await tester.pumpAndSettle();

      final resolvedContext = tester.element(find.byType(AppShell));
      final colors = Theme.of(resolvedContext).extension<AppColors>()!;
      expect(colors.primary, AppColors.theme5.primary);
      expect(colors.bg, AppColors.theme5.bg);
    },
  );

  testWidgets(
    'the reduced-motion override forces AppMotion.isReduced even when the '
    'OS setting is off (E0-09)',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: CricUnityApp(
            router: createAppRouter(),
            startWithOnboardingComplete: true,
          ),
        ),
      );
      await tester.pump();

      final context = tester.element(find.byType(AppShell));
      expect(AppMotion.isReduced(context), isFalse);

      final container = ProviderScope.containerOf(context);
      container
          .read(appearanceSettingsProvider.notifier)
          .setReducedMotionOverride(true);
      await tester.pump();

      final resolvedContext = tester.element(find.byType(AppShell));
      expect(AppMotion.isReduced(resolvedContext), isTrue);
    },
  );

  testWidgets('the app boots into onboarding by default (E1-03)', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: CricUnityApp()));
    await tester.pump();

    expect(find.text('Your career, verified'), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
  });

  testWidgets(
    'Explore first leads to the guest preview, not the logged-in shell '
    '(E1-04)',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: CricUnityApp()));
      await tester.pump();

      await tester.tap(find.text('Explore first'));
      await tester.pumpAndSettle();

      expect(find.text('Viewing as guest · Sign up'), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
    },
  );
}
