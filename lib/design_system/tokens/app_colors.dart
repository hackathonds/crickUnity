import 'package:flutter/material.dart' show Color, ThemeExtension;

/// Semantic color tokens — DS §2.3 role set, concrete values per theme from
/// DS §4. DS §4 gives exact hex only for a subset of roles per theme
/// (primary/accent/bg/surface, and text for Themes 1 & 4); every other role
/// below is a documented computed default (light themes 1/2/3/5 share one
/// neutral ink/border/divider/disabled scale since DS doesn't vary those by
/// brand hue; success/warning/error/info are a shared light-group and
/// dark-group pair; chart ramps are generated stops around each theme's
/// primary/accent). All of these are listed in the PR's Open Questions for
/// design sign-off — see CLAUDE.md's "never guess, flag it" rule.
///
/// `verified`, `coin`, and `live` are the reserved roles (DS §2.3): their
/// values are identical across every theme by construction and must never
/// be used decoratively.
class AppColors extends ThemeExtension<AppColors> {
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color accent;
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color border;
  final Color divider;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color disabledFg;
  final Color disabledBg;
  final Color overlay;

  /// Reserved — identical across all 5 themes, never decorative.
  final Color verified;
  final Color coin;
  final Color live;

  /// Money surfaces always keep a 1px border in every theme (DS §2.2).
  final Color moneyBorder;

  /// Ordered 6-color categorical ramp for charts.
  final List<Color> chartCategorical;

  /// Sequential ramp for heatmaps, light→dark (or dark→bright on Theme 4).
  final List<Color> chartSequential;

  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.accent,
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.divider,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.disabledFg,
    required this.disabledBg,
    required this.overlay,
    required this.verified,
    required this.coin,
    required this.live,
    required this.moneyBorder,
    required this.chartCategorical,
    required this.chartSequential,
  });

  @override
  AppColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? accent,
    Color? bg,
    Color? surface,
    Color? surfaceAlt,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? border,
    Color? divider,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? disabledFg,
    Color? disabledBg,
    Color? overlay,
    Color? verified,
    Color? coin,
    Color? live,
    Color? moneyBorder,
    List<Color>? chartCategorical,
    List<Color>? chartSequential,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      disabledFg: disabledFg ?? this.disabledFg,
      disabledBg: disabledBg ?? this.disabledBg,
      overlay: overlay ?? this.overlay,
      verified: verified ?? this.verified,
      coin: coin ?? this.coin,
      live: live ?? this.live,
      moneyBorder: moneyBorder ?? this.moneyBorder,
      chartCategorical: chartCategorical ?? this.chartCategorical,
      chartSequential: chartSequential ?? this.chartSequential,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    List<Color> cl(List<Color> a, List<Color> b) => [
      for (var i = 0; i < a.length; i++) c(a[i], b[i]),
    ];
    return AppColors(
      primary: c(primary, other.primary),
      onPrimary: c(onPrimary, other.onPrimary),
      secondary: c(secondary, other.secondary),
      accent: c(accent, other.accent),
      bg: c(bg, other.bg),
      surface: c(surface, other.surface),
      surfaceAlt: c(surfaceAlt, other.surfaceAlt),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textTertiary: c(textTertiary, other.textTertiary),
      border: c(border, other.border),
      divider: c(divider, other.divider),
      success: c(success, other.success),
      warning: c(warning, other.warning),
      error: c(error, other.error),
      info: c(info, other.info),
      disabledFg: c(disabledFg, other.disabledFg),
      disabledBg: c(disabledBg, other.disabledBg),
      overlay: c(overlay, other.overlay),
      verified: c(verified, other.verified),
      coin: c(coin, other.coin),
      live: c(live, other.live),
      moneyBorder: c(moneyBorder, other.moneyBorder),
      chartCategorical: cl(chartCategorical, other.chartCategorical),
      chartSequential: cl(chartSequential, other.chartSequential),
    );
  }

  // Reserved roles — identical across all 5 themes (DS §2.3 reservation rule).
  static const Color _verified = Color(0xFF0F6E63);
  static const Color _coin = Color(0xFFD9A441);
  static const Color _live = Color(0xFFE4372B);

  // Shared neutral ink/border/divider/disabled scale for the light themes
  // (1, 2, 3, 5) — DS §4 only gives bespoke text colors for Themes 1 & 4;
  // the others are assumed to share one neutral scale and vary only by
  // brand hue (primary/secondary/accent). Computed default — flagged.
  static const Color _lightTextPrimary = Color(0xFF101613);
  static const Color _lightTextSecondary = Color(0xFF5A665F);
  static const Color _lightTextTertiary = Color(0xFF8A958F);
  static const Color _lightBorder = Color(0xFFE2E5E3);
  static const Color _lightDivider = Color(0xFFEDEFED);
  static const Color _lightDisabledFg = Color(0x61101613); // textPrimary @38%
  static const Color _lightOverlay = Color(0x66000000); // black @40%

  // Shared semantic status colors — computed default, not given per-theme.
  static const Color _lightSuccess = Color(0xFF1E8E5A);
  static const Color _lightWarning = Color(0xFFB7791F);
  static const Color _lightError = Color(0xFFD64545);
  static const Color _lightInfo = Color(0xFF2B6CB0);

  static const Color _darkSuccess = Color(0xFF34D399);
  static const Color _darkWarning = Color(0xFFF5A524);
  static const Color _darkError = Color(0xFFF87171);
  static const Color _darkInfo = Color(0xFF60A5FA);

  /// Theme 1 · Modern Cricket Green (default light).
  static const AppColors theme1 = AppColors(
    primary: Color(0xFF0E7A4A),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF123B2A),
    accent: Color(0xFFF2B824),
    bg: Color(0xFFF7F8F7),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEEF1EF),
    textPrimary: _lightTextPrimary,
    textSecondary: _lightTextSecondary,
    textTertiary: _lightTextTertiary,
    border: _lightBorder,
    divider: _lightDivider,
    success: _lightSuccess,
    warning: _lightWarning,
    error: _lightError,
    info: _lightInfo,
    disabledFg: _lightDisabledFg,
    disabledBg: Color(0xFFEEF1EF),
    overlay: _lightOverlay,
    verified: _verified,
    coin: _coin,
    live: _live,
    moneyBorder: _lightBorder,
    chartCategorical: [
      Color(0xFF0E7A4A),
      Color(0xFFF2B824),
      Color(0xFF123B2A),
      Color(0xFF5A665F),
      Color(0xFF8A958F),
      Color(0xFFC9D0CB),
    ],
    chartSequential: [
      Color(0xFFEAF3EE),
      Color(0xFFC7E3D3),
      Color(0xFF8FCBA8),
      Color(0xFF4FA97A),
      Color(0xFF0E7A4A),
    ],
  );

  /// Theme 2 · Royal Navy Gold.
  static const AppColors theme2 = AppColors(
    primary: Color(0xFF14213D),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF14213D),
    accent: Color(0xFFD4A017),
    bg: Color(0xFFF4F5F8),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFE9EBF1),
    textPrimary: _lightTextPrimary,
    textSecondary: _lightTextSecondary,
    textTertiary: _lightTextTertiary,
    border: _lightBorder,
    divider: _lightDivider,
    success: _lightSuccess,
    warning: _lightWarning,
    error: _lightError,
    info: _lightInfo,
    disabledFg: _lightDisabledFg,
    disabledBg: Color(0xFFE9EBF1),
    overlay: _lightOverlay,
    verified: _verified,
    coin: _coin,
    live: _live,
    moneyBorder: _lightBorder,
    chartCategorical: [
      Color(0xFF14213D),
      Color(0xFFD4A017),
      Color(0xFF3B4A6B),
      Color(0xFF8A94A6),
      Color(0xFFB8C0CC),
      Color(0xFFE4E7EC),
    ],
    chartSequential: [
      Color(0xFFEDEFF4),
      Color(0xFFC7CEDF),
      Color(0xFF97A4C4),
      Color(0xFF5C6F9C),
      Color(0xFF14213D),
    ],
  );

  /// Theme 3 · Electric Blue.
  static const AppColors theme3 = AppColors(
    primary: Color(0xFF1257E0),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF1257E0),
    accent: Color(0xFF37D2C4),
    bg: Color(0xFFF5F8FF),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFE9EEFC),
    textPrimary: _lightTextPrimary,
    textSecondary: _lightTextSecondary,
    textTertiary: _lightTextTertiary,
    border: _lightBorder,
    divider: _lightDivider,
    success: _lightSuccess,
    warning: _lightWarning,
    error: _lightError,
    info: _lightInfo,
    disabledFg: _lightDisabledFg,
    disabledBg: Color(0xFFE9EEFC),
    overlay: _lightOverlay,
    verified: _verified,
    coin: _coin,
    live: _live,
    moneyBorder: _lightBorder,
    chartCategorical: [
      Color(0xFF1257E0),
      Color(0xFF37D2C4),
      Color(0xFF7C5CFF),
      Color(0xFF5A6B8C),
      Color(0xFF9FB0C9),
      Color(0xFFD6E0EF),
    ],
    chartSequential: [
      Color(0xFFEAF0FE),
      Color(0xFFC3D6FC),
      Color(0xFF8DB0F8),
      Color(0xFF4E82EF),
      Color(0xFF1257E0),
    ],
  );

  /// Theme 4 · Dark Graphite Neon (default dark).
  static const AppColors theme4 = AppColors(
    primary: Color(0xFF3DDC84),
    onPrimary: Color(0xFF0E1113),
    secondary: Color(0xFF3DDC84),
    accent: Color(0xFFF2B824),
    bg: Color(0xFF0E1113),
    surface: Color(0xFF171B1E),
    surfaceAlt: Color(0xFF1C2124),
    textPrimary: Color(0xFFF2F4F3),
    textSecondary: Color(0xFF9AA5A0),
    textTertiary: Color(0xFF6B7674),
    border: Color(0xFF2A3237),
    divider: Color(0xFF23282B),
    success: _darkSuccess,
    warning: _darkWarning,
    error: _darkError,
    info: _darkInfo,
    disabledFg: Color(0x61F2F4F3), // textPrimary @38%
    disabledBg: Color(0xFF1C2124),
    overlay: Color(0x99000000), // black @60%
    verified: _verified,
    coin: _coin,
    live: _live,
    moneyBorder: Color(0xFF2A3237),
    chartCategorical: [
      Color(0xFF3DDC84),
      Color(0xFFF2B824),
      Color(0xFF60A5FA),
      Color(0xFF9AA5A0),
      Color(0xFF6B7674),
      Color(0xFFF2F4F3),
    ],
    chartSequential: [
      Color(0xFF171B1E),
      Color(0xFF234030),
      Color(0xFF2E6B49),
      Color(0xFF35A366),
      Color(0xFF3DDC84),
    ],
  );

  /// Theme 5 · Premium White Emerald.
  static const AppColors theme5 = AppColors(
    primary: Color(0xFF0C8F5B),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF0C8F5B),
    accent: Color(0xFF101613),
    bg: Color(0xFFFCFCFC),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEFF3F1),
    textPrimary: _lightTextPrimary,
    textSecondary: _lightTextSecondary,
    textTertiary: _lightTextTertiary,
    border: _lightBorder,
    divider: _lightDivider,
    success: _lightSuccess,
    warning: _lightWarning,
    error: _lightError,
    info: _lightInfo,
    disabledFg: _lightDisabledFg,
    disabledBg: Color(0xFFEFF3F1),
    overlay: _lightOverlay,
    verified: _verified,
    coin: _coin,
    live: _live,
    moneyBorder: _lightBorder,
    chartCategorical: [
      Color(0xFF0C8F5B),
      Color(0xFF101613),
      Color(0xFF4C9C7B),
      Color(0xFF7FA997),
      Color(0xFFB9C7BC),
      Color(0xFFE7ECE9),
    ],
    chartSequential: [
      Color(0xFFF1F7F4),
      Color(0xFFCFE7DB),
      Color(0xFF9FCFB8),
      Color(0xFF61B08C),
      Color(0xFF0C8F5B),
    ],
  );
}
