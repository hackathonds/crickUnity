import 'package:flutter/material.dart';

import 'design_system/theme/app_theme.dart';

void main() {
  runApp(const CricUnityApp());
}

/// Placeholder root widget wiring the design-tokens package into a real
/// [MaterialApp] so the theme assembly is exercised end-to-end. Screens and
/// components land in later E0 stories.
class CricUnityApp extends StatelessWidget {
  const CricUnityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CricUnity',
      theme: AppTheme.themes[AppTheme.defaultLight],
      darkTheme: AppTheme.themes[AppTheme.defaultDark],
      home: const Scaffold(body: SizedBox.shrink()),
    );
  }
}
