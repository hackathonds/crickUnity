import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'design_system/theme/app_theme.dart';
import 'design_system/tokens/app_typography.dart';
import 'navigation/app_router.dart';
import 'onboarding/onboarding_flow.dart';
import 'settings/appearance_settings_provider.dart';

void main() {
  runApp(const ProviderScope(child: CricUnityApp()));
}

/// Root widget wiring the design-tokens package and the E0-04 app shell
/// into a real [MaterialApp]. The debug QA menu (type specimen, icon
/// gallery, shell debug controls) is reachable from the Profile tab now
/// that the shell is the real home.
///
/// [router] defaults to a single production instance created once; tests
/// pass their own `createAppRouter()` so each test gets independent
/// navigation state (see `createAppRouter`'s doc comment).
///
/// E1-01/02/03's onboarding flow is now the real pre-tab stack: the app
/// boots into it and only mounts the tab shell (`MaterialApp.router`)
/// once it signals completion. [startWithOnboardingComplete] is a test-only
/// seam (mirrors [router]'s own test-isolation purpose) for tests that
/// exercise the shell directly rather than walking through onboarding
/// first.
class CricUnityApp extends ConsumerStatefulWidget {
  static final GoRouter _productionRouter = createAppRouter();

  final GoRouter? router;
  final bool startWithOnboardingComplete;

  const CricUnityApp({
    super.key,
    this.router,
    this.startWithOnboardingComplete = false,
  });

  @override
  ConsumerState<CricUnityApp> createState() => _CricUnityAppState();
}

class _CricUnityAppState extends ConsumerState<CricUnityApp> {
  late bool _onboardingComplete = widget.startWithOnboardingComplete;
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appearanceSettingsProvider);
    final themeOverride = settings.themeOverride;
    final theme = AppTheme.themes[themeOverride ?? AppTheme.defaultLight];
    final darkTheme = AppTheme.themes[themeOverride ?? AppTheme.defaultDark];
    final themeMode = themeOverride != null
        ? ThemeMode.light
        : ThemeMode.system;

    Widget appBuilder(BuildContext context, Widget? child) {
      final mediaQuery = MediaQuery.of(context);
      final scale =
          settings.textScaleOverride ?? mediaQuery.textScaler.scale(1);
      final reducedMotion =
          settings.reducedMotionOverride || mediaQuery.disableAnimations;
      return MediaQuery(
        data: mediaQuery.copyWith(
          textScaler: AppTypography.clampTextScaler(TextScaler.linear(scale)),
          disableAnimations: reducedMotion,
        ),
        child: child!,
      );
    }

    if (!_onboardingComplete) {
      return MaterialApp(
        title: 'CricUnity',
        theme: theme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        scaffoldMessengerKey: _messengerKey,
        builder: appBuilder,
        home: OnboardingFlow(
          onOnboardingComplete: () =>
              setState(() => _onboardingComplete = true),
          // Guest mode (E1-04) doesn't exist yet -- treating "Explore
          // first" as onboarding-complete is an interim stand-in so the
          // button leads somewhere rather than dead-ending; it does not
          // apply any real guest restrictions yet.
          onExploreAsGuest: () => setState(() => _onboardingComplete = true),
          onContactSupport: () => _messengerKey.currentState?.showSnackBar(
            const SnackBar(content: Text('Support is E16-07 — not built yet')),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'CricUnity',
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      scaffoldMessengerKey: _messengerKey,
      builder: appBuilder,
      routerConfig: widget.router ?? CricUnityApp._productionRouter,
    );
  }
}
