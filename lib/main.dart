import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'design_system/theme/app_theme.dart';
import 'design_system/tokens/app_typography.dart';
import 'guest/guest_live_match_preview_screen.dart';
import 'guest/guest_provider.dart';
import 'navigation/app_router.dart';
import 'onboarding/onboarding_flow.dart';
import 'persistence/local_store.dart';
import 'settings/appearance_settings_provider.dart';

Future<void> main() async {
  // SharedPreferences caches its values in memory after this one async
  // load, so every provider downstream can read/write it synchronously --
  // see local_store.dart's doc comment.
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(
          SharedPreferencesLocalStore(prefs),
        ),
      ],
      child: const CricUnityApp(),
    ),
  );
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
/// once it signals completion. Welcome's "Explore first" (E1-04) instead
/// leads to a guest preview -- the real app shell is a logged-in
/// experience (Home Dashboard, Wallet, Messages, ... all hidden from
/// guests per PRD §2.1), so a guest never lands there directly; picking
/// "Continue with phone" from that preview is what actually reaches it.
/// [startWithOnboardingComplete] is a test-only seam (mirrors [router]'s
/// own test-isolation purpose) for tests that exercise the shell directly
/// rather than walking through onboarding first.
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
  bool _guestPreview = false;
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  void _showSupportStub() => _messengerKey.currentState?.showSnackBar(
    const SnackBar(content: Text('Support is E16-07 — not built yet')),
  );

  void _completeOnboarding() {
    ref.read(guestProvider.notifier).becomeRegistered();
    setState(() => _guestPreview = false);
  }

  @override
  Widget build(BuildContext context) {
    // Persisted (guest_provider.dart) -- a device that has ever completed
    // registration boots straight into the tab shell instead of
    // re-running onboarding every launch. A pure OR, not a provider
    // mutation, so `startWithOnboardingComplete` resolves on the very
    // first build like it always did -- mutating a provider from
    // initState() to fake this instead deadlocks Riverpod's own
    // "no provider writes mid-build" guard (hit and fixed earlier this
    // session for the same reason in my_rewards_screen.dart/
    // admin_console_screen.dart's post-frame sweeps).
    final registered =
        widget.startWithOnboardingComplete || !ref.watch(guestProvider).isGuest;
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

    if (_guestPreview && !registered) {
      return MaterialApp(
        title: 'CricUnity',
        theme: theme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        scaffoldMessengerKey: _messengerKey,
        builder: appBuilder,
        home: Builder(
          builder: (innerContext) => GuestLiveMatchPreviewScreen(
            onContinueWithPhone: () => OnboardingFlow(
              onExploreAsGuest: () {}, // unreachable: already past Welcome
              onContactSupport: _showSupportStub,
              onOnboardingComplete: _completeOnboarding,
            ).pushPhoneEntry(innerContext),
          ),
        ),
      );
    }

    if (!registered) {
      return MaterialApp(
        title: 'CricUnity',
        theme: theme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        scaffoldMessengerKey: _messengerKey,
        builder: appBuilder,
        home: OnboardingFlow(
          onOnboardingComplete: _completeOnboarding,
          onExploreAsGuest: () => setState(() => _guestPreview = true),
          onContactSupport: _showSupportStub,
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
