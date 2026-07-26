import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/theme/app_theme.dart';
import '../design_system/tokens/app_typography.dart';

/// E0-09 · DS §7 screen 67 Appearance. Session-scoped only: no persistence
/// package (shared_preferences or similar) exists anywhere in this repo yet,
/// and neither PRD nor DS says whether these choices must survive an app
/// restart -- surfaced as a PR open question rather than guessed at by
/// adding a new dependency here.
class AppearanceSettings {
  /// Null = follow the OS light/dark setting (DS §4: "system light/dark
  /// maps to Themes 1<->4 unless overridden").
  final AppThemeId? themeOverride;

  /// Null = follow the OS text-scale setting (still clamped to
  /// [AppTypography.maxTextScaleFactor] app-wide, as before this story).
  final double? textScaleOverride;

  /// Only ever turns reduced motion ON in addition to the OS setting; it
  /// cannot turn the OS's own reduced-motion setting off.
  final bool reducedMotionOverride;

  const AppearanceSettings({
    this.themeOverride,
    this.textScaleOverride,
    this.reducedMotionOverride = false,
  });

  AppearanceSettings copyWith({
    AppThemeId? themeOverride,
    bool clearThemeOverride = false,
    double? textScaleOverride,
    bool? reducedMotionOverride,
  }) {
    return AppearanceSettings(
      themeOverride: clearThemeOverride
          ? null
          : (themeOverride ?? this.themeOverride),
      textScaleOverride: textScaleOverride ?? this.textScaleOverride,
      reducedMotionOverride:
          reducedMotionOverride ?? this.reducedMotionOverride,
    );
  }
}

class AppearanceSettingsNotifier extends Notifier<AppearanceSettings> {
  @override
  AppearanceSettings build() => const AppearanceSettings();

  /// Pass null to select "System" (follow the OS light/dark setting).
  void setThemeOverride(AppThemeId? id) {
    state = id == null
        ? state.copyWith(clearThemeOverride: true)
        : state.copyWith(themeOverride: id);
  }

  void setTextScale(double scale) {
    state = state.copyWith(
      textScaleOverride: scale.clamp(1.0, AppTypography.maxTextScaleFactor),
    );
  }

  void setReducedMotionOverride(bool value) =>
      state = state.copyWith(reducedMotionOverride: value);
}

final appearanceSettingsProvider =
    NotifierProvider<AppearanceSettingsNotifier, AppearanceSettings>(
      AppearanceSettingsNotifier.new,
    );
