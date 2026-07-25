import 'package:flutter/material.dart';

import 'design_system/debug/debug_menu_screen.dart';
import 'design_system/theme/app_theme.dart';
import 'design_system/tokens/app_typography.dart';

void main() {
  runApp(const CricUnityApp());
}

/// Root widget wiring the design-tokens package into a real [MaterialApp].
/// `home` points at the debug QA menu since no navigation shell exists yet
/// (that lands in E0-04).
class CricUnityApp extends StatelessWidget {
  const CricUnityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: const DebugMenuScreen(),
    );
  }
}
