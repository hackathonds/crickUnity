import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/theme/app_theme.dart';
import '../design_system/tokens/app_typography.dart';
import '../persistence/persisted_notifier.dart';

/// E0-09 · DS §7 screen 67 Appearance.
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

  Map<String, dynamic> toJson() => {
    'themeOverride': themeOverride?.name,
    'textScaleOverride': textScaleOverride,
    'reducedMotionOverride': reducedMotionOverride,
  };

  factory AppearanceSettings.fromJson(Map<String, dynamic> json) {
    return AppearanceSettings(
      themeOverride: json['themeOverride'] != null
          ? AppThemeId.values.byName(json['themeOverride'] as String)
          : null,
      textScaleOverride: (json['textScaleOverride'] as num?)?.toDouble(),
      reducedMotionOverride: json['reducedMotionOverride'] as bool? ?? false,
    );
  }
}

class AppearanceSettingsNotifier extends PersistedNotifier<AppearanceSettings> {
  @override
  String get persistenceKey => 'appearance_settings_v1';

  @override
  AppearanceSettings seed() => const AppearanceSettings();

  @override
  Map<String, dynamic> toJson(AppearanceSettings value) => value.toJson();

  @override
  AppearanceSettings fromJson(Map<String, dynamic> json) =>
      AppearanceSettings.fromJson(json);

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
