/// Spacing scale — DS §2.1. 8pt base, 4pt half-step. Nothing off this scale.
abstract final class AppSpacing {
  /// Icon↔label gap, chip internals.
  static const double xs = 4;

  /// Intra-card element gap.
  static const double sm = 8;

  /// List-row internal vertical rhythm, gutters.
  static const double md = 12;

  /// Screen side margins, card padding.
  static const double lg = 16;

  /// Featured-card padding.
  static const double xl = 20;

  /// Section gaps.
  static const double xxl = 24;

  /// Between major sections.
  static const double xxxl = 32;

  /// Hero headers, empty-state breathing room.
  static const double huge = 40;

  /// Hero headers, empty-state breathing room (largest step).
  static const double massive = 48;

  /// The full scale, ascending — for validating an arbitrary value is on-scale.
  static const List<double> scale = [
    xs,
    sm,
    md,
    lg,
    xl,
    xxl,
    xxxl,
    huge,
    massive,
  ];
}
