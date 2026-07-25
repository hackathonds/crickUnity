import 'package:flutter/widgets.dart';

/// Corner radius scale — DS §2.2.
abstract final class AppRadius {
  /// Chips, tags.
  static const double xs = 6;

  /// Buttons, inputs.
  static const double sm = 10;

  /// Cards.
  static const double md = 14;

  /// Sheets, featured cards.
  static const double lg = 20;

  /// Avatars, pills, FAB.
  static const double full = 9999;

  static const BorderRadius xsRadius = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius fullRadius = BorderRadius.all(
    Radius.circular(full),
  );
}
