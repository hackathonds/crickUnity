import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';

/// The 5 themes — DS §4. Themes change tokens only, never layout; `live`
/// and `coin` stay constant across all of them (recognition constancy).
enum AppThemeId { theme1, theme2, theme3, theme4, theme5 }

abstract final class AppTheme {
  /// Modern Cricket Green — default light.
  static const AppThemeId defaultLight = AppThemeId.theme1;

  /// Dark Graphite Neon — default dark.
  static const AppThemeId defaultDark = AppThemeId.theme4;

  static final Map<AppThemeId, ThemeData> themes = {
    AppThemeId.theme1: _build(AppColors.theme1, Brightness.light),
    AppThemeId.theme2: _build(AppColors.theme2, Brightness.light),
    AppThemeId.theme3: _build(AppColors.theme3, Brightness.light),
    AppThemeId.theme4: _build(AppColors.theme4, Brightness.dark),
    AppThemeId.theme5: _build(AppColors.theme5, Brightness.light),
  };

  static ThemeData _build(AppColors colors, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      secondary: colors.secondary,
      onSecondary: colors.onPrimary,
      error: colors.error,
      onError: colors.onPrimary,
      surface: colors.surface,
      onSurface: colors.textPrimary,
    );

    final textTheme = TextTheme(
      displayLarge: AppTypography.display,
      headlineLarge: AppTypography.h1,
      titleLarge: AppTypography.h2,
      titleMedium: AppTypography.title,
      titleSmall: AppTypography.subtitle,
      bodyMedium: AppTypography.body,
      bodySmall: AppTypography.caption,
      labelSmall: AppTypography.label,
      labelLarge: AppTypography.button,
    ).apply(bodyColor: colors.textPrimary, displayColor: colors.textPrimary);

    return ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.bg,
      fontFamily: AppTypography.bodyFamily,
      textTheme: textTheme,
      dividerColor: colors.divider,
      disabledColor: colors.disabledFg,
      extensions: [colors],
    );
  }
}
