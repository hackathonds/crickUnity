import 'dart:ui' show Brightness, Color, Offset;

import 'package:flutter/material.dart' show Colors;
import 'package:flutter/painting.dart' show BorderSide, BoxShadow;

/// Elevation levels — DS §2.2.
enum AppElevationLevel { e1, e2, e3 }

/// A light-theme shadow spec: offset-y / blur / black opacity.
class AppShadowSpec {
  final double offsetY;
  final double blurRadius;
  final double opacity;

  const AppShadowSpec({
    required this.offsetY,
    required this.blurRadius,
    required this.opacity,
  });

  List<BoxShadow> toBoxShadows() => [
    BoxShadow(
      color: Colors.black.withValues(alpha: opacity),
      offset: Offset(0, offsetY),
      blurRadius: blurRadius,
    ),
  ];
}

/// The resolved visual treatment for a surface at a given elevation level,
/// theme brightness, and money-surface status — DS §2.2's border-vs-elevation
/// rule: light themes use hairline borders; dark themes use surface
/// luminance instead of borders, *except* money surfaces, which always keep
/// a 1px border in every theme (Pillar 4 "banking" cue).
class SurfaceStyle {
  final BorderSide? border;
  final List<BoxShadow> shadows;

  /// Fractional surface luminance increase (e.g. 0.04 = +4%) used by dark
  /// themes in place of a shadow/border. Zero when not applicable.
  final double darkSurfaceLuminanceDelta;

  const SurfaceStyle({
    this.border,
    this.shadows = const [],
    this.darkSurfaceLuminanceDelta = 0,
  });
}

/// Elevation tokens — DS §2.2.
abstract final class AppElevation {
  /// Card.
  static const e1 = AppShadowSpec(offsetY: 2, blurRadius: 8, opacity: 0.06);

  /// Raised (FAB, sticky bar).
  static const e2 = AppShadowSpec(offsetY: 4, blurRadius: 16, opacity: 0.10);

  /// Sheet/dialog.
  static const e3 = AppShadowSpec(offsetY: 8, blurRadius: 32, opacity: 0.16);

  /// Dark-theme surface luminance deltas replacing e1/e2/e3 shadows.
  static const double darkLuminanceE1 = 0.04;
  static const double darkLuminanceE2 = 0.08;
  static const double darkLuminanceE3 = 0.12;

  /// Overlay/scrim opacity, light and dark themes.
  static const double overlayLight = 0.40;
  static const double overlayDark = 0.60;

  static AppShadowSpec specFor(AppElevationLevel level) => switch (level) {
    AppElevationLevel.e1 => e1,
    AppElevationLevel.e2 => e2,
    AppElevationLevel.e3 => e3,
  };

  static double darkLuminanceDeltaFor(AppElevationLevel level) =>
      switch (level) {
        AppElevationLevel.e1 => darkLuminanceE1,
        AppElevationLevel.e2 => darkLuminanceE2,
        AppElevationLevel.e3 => darkLuminanceE3,
      };

  /// Resolves the border/shadow/luminance treatment for a surface.
  ///
  /// Money surfaces always get a 1px border and never rely on luminance-only
  /// elevation, regardless of theme brightness.
  static SurfaceStyle resolveSurfaceStyle({
    required AppElevationLevel level,
    required Brightness brightness,
    required Color borderColor,
    bool isMoneySurface = false,
  }) {
    final isLight = brightness == Brightness.light;
    final hasBorder = isMoneySurface || isLight;
    final usesLuminanceElevation = !isLight && !isMoneySurface;

    return SurfaceStyle(
      border: hasBorder ? BorderSide(color: borderColor, width: 1) : null,
      shadows: isLight ? specFor(level).toBoxShadows() : const [],
      darkSurfaceLuminanceDelta: usesLuminanceElevation
          ? darkLuminanceDeltaFor(level)
          : 0,
    );
  }
}
