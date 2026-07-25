import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'design_system/theme/app_theme.dart';
import 'design_system/tokens/app_typography.dart';
import 'navigation/app_router.dart';

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
class CricUnityApp extends StatelessWidget {
  static final GoRouter _productionRouter = createAppRouter();

  final GoRouter? router;

  const CricUnityApp({super.key, this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CricUnity',
      theme: AppTheme.themes[AppTheme.defaultLight],
      darkTheme: AppTheme.themes[AppTheme.defaultDark],
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: AppTypography.clampTextScaler(mediaQuery.textScaler),
          ),
          child: child!,
        );
      },
      routerConfig: router ?? _productionRouter,
    );
  }
}
