import 'package:flutter/painting.dart';

/// Type ramp — DS §2.4. Font families are referenced by name only; the
/// licensed Clash Display asset files are not bundled here (see PR open
/// questions) — the app renders on system fallback until they're added
/// under `assets/fonts/` and declared in `pubspec.yaml`.
abstract final class AppTypography {
  static const String displayFamily = 'ClashDisplay';
  static const String bodyFamily = 'Inter';

  static const TextStyle display = TextStyle(
    fontFamily: displayFamily,
    fontWeight: FontWeight.w600,
    fontSize: 34,
    height: 40 / 34,
    letterSpacing: 34 * -0.005,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: displayFamily,
    fontWeight: FontWeight.w600,
    fontSize: 28,
    height: 34 / 28,
    letterSpacing: 28 * -0.0025,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: bodyFamily,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    height: 26 / 20,
  );

  static const TextStyle title = TextStyle(
    fontFamily: bodyFamily,
    fontWeight: FontWeight.w600,
    fontSize: 17,
    height: 24 / 17,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: bodyFamily,
    fontWeight: FontWeight.w500,
    fontSize: 15,
    height: 22 / 15,
  );

  static const TextStyle body = TextStyle(
    fontFamily: bodyFamily,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 22 / 15,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: bodyFamily,
    fontWeight: FontWeight.w400,
    fontSize: 13,
    height: 18 / 13,
    letterSpacing: 13 * 0.005,
  );

  static const TextStyle label = TextStyle(
    fontFamily: bodyFamily,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 12 * 0.02,
  );

  static const TextStyle button = TextStyle(
    fontFamily: bodyFamily,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 20 / 15,
    letterSpacing: 15 * 0.0025,
  );

  static const TextStyle stat = TextStyle(
    fontFamily: bodyFamily,
    fontWeight: FontWeight.w600,
    fontSize: 22,
    height: 28 / 22,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Money numeral style at its minimum size (17). DS §2.4 gives the size
  /// range 17-28 but no explicit line-height for this row (unlike every
  /// other role); 1.3 is used as a placeholder ratio pending design
  /// sign-off (PR open questions). The 70%-size top-aligned currency
  /// symbol is a composition concern for the component that uses this
  /// style, not the token itself.
  static const TextStyle moneyMin = TextStyle(
    fontFamily: bodyFamily,
    fontWeight: FontWeight.w600,
    fontSize: 17,
    height: 1.3,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Money numeral style at its maximum size (28). See [moneyMin] re: the
  /// unspecified line-height placeholder.
  static const TextStyle moneyMax = TextStyle(
    fontFamily: bodyFamily,
    fontWeight: FontWeight.w600,
    fontSize: 28,
    height: 1.3,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle scoreboard = TextStyle(
    fontFamily: displayFamily,
    fontWeight: FontWeight.w700,
    fontSize: 40,
    height: 44 / 40,
    letterSpacing: 40 * 0.01,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Minimum body size any role may be scaled down to.
  static const double minBodySize = 13;

  /// Dynamic-type ceiling; layouts must reflow (never truncate — money
  /// wraps before it truncates) up to this scale factor.
  static const double maxTextScaleFactor = 1.35;

  /// Clamps an OS/user text scaler to the DS §2.4 dynamic-type ceiling —
  /// applied app-wide so nothing scales past 135% regardless of the
  /// platform's own accessibility text-size setting.
  static TextScaler clampTextScaler(TextScaler scaler) {
    final factor = scaler.scale(1).clamp(1.0, maxTextScaleFactor);
    return TextScaler.linear(factor);
  }
}
