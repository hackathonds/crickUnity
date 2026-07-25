import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart' show BuildContext, MediaQuery;

/// Named motion tokens — DS §2.6.
enum AppMotionToken { instant, fast, standard, gentle, ceremony }

/// Motion durations — DS §2.6.
abstract final class AppMotionDuration {
  /// State tints.
  static const Duration instant = Duration(milliseconds: 80);

  /// Chips, toggles.
  static const Duration fast = Duration(milliseconds: 160);

  /// Push/pop, sheet.
  static const Duration standard = Duration(milliseconds: 240);

  /// Card expand.
  static const Duration gentle = Duration(milliseconds: 360);

  /// Unlocks — DS gives a 900-1400ms range; use the low end as the default
  /// and [ceremonyMax] where a scene needs the upper bound.
  static const Duration ceremony = Duration(milliseconds: 900);
  static const Duration ceremonyMax = Duration(milliseconds: 1400);

  /// Reduced-motion setting collapses all movement to a single 120ms fade.
  static const Duration reduced = Duration(milliseconds: 120);

  static Duration forToken(AppMotionToken token) => switch (token) {
    AppMotionToken.instant => instant,
    AppMotionToken.fast => fast,
    AppMotionToken.standard => standard,
    AppMotionToken.gentle => gentle,
    AppMotionToken.ceremony => ceremony,
  };
}

/// Motion easing — DS §2.6.
abstract final class AppMotionCurves {
  /// Standard easing for most transitions.
  static const Curve standard = Cubic(0.2, 0, 0, 1);

  /// Entrances.
  static const Curve decelerate = Curves.decelerate;

  /// Exits.
  static const Curve accelerate = Curves.easeIn;

  /// Reduced-motion replaces every curve with a flat linear fade.
  static const Curve reduced = Curves.linear;

  /// Damping ratio reserved for coin/XP physics only.
  static const double springDampingRatio = 0.8;

  static SpringDescription springFor({
    double mass = 1,
    double stiffness = 180,
  }) {
    final damping = springDampingRatio * 2 * math.sqrt(mass * stiffness);
    return SpringDescription(
      mass: mass,
      stiffness: stiffness,
      damping: damping,
    );
  }
}

/// Resolves motion tokens against the platform's reduced-motion setting —
/// DS §2.6: "nothing is information-only-in-motion."
abstract final class AppMotion {
  static bool isReduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  static Duration resolveDuration(BuildContext context, AppMotionToken token) {
    if (isReduced(context)) return AppMotionDuration.reduced;
    return AppMotionDuration.forToken(token);
  }

  static Curve resolveCurve(BuildContext context, Curve curve) {
    return isReduced(context) ? AppMotionCurves.reduced : curve;
  }
}
