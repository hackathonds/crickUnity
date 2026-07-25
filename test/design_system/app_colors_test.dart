import 'package:cricunity/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final allThemes = [
    AppColors.theme1,
    AppColors.theme2,
    AppColors.theme3,
    AppColors.theme4,
    AppColors.theme5,
  ];

  test('theme hex values match DS §4 exactly where DS gives one', () {
    expect(AppColors.theme1.primary, const Color(0xFF0E7A4A));
    expect(AppColors.theme1.secondary, const Color(0xFF123B2A));
    expect(AppColors.theme1.accent, const Color(0xFFF2B824));
    expect(AppColors.theme1.bg, const Color(0xFFF7F8F7));
    expect(AppColors.theme1.surface, const Color(0xFFFFFFFF));

    expect(AppColors.theme2.primary, const Color(0xFF14213D));
    expect(AppColors.theme2.accent, const Color(0xFFD4A017));
    expect(AppColors.theme2.bg, const Color(0xFFF4F5F8));

    expect(AppColors.theme3.primary, const Color(0xFF1257E0));
    expect(AppColors.theme3.accent, const Color(0xFF37D2C4));
    expect(AppColors.theme3.bg, const Color(0xFFF5F8FF));

    expect(AppColors.theme4.bg, const Color(0xFF0E1113));
    expect(AppColors.theme4.surface, const Color(0xFF171B1E));
    expect(AppColors.theme4.primary, const Color(0xFF3DDC84));
    expect(AppColors.theme4.accent, const Color(0xFFF2B824));
    expect(AppColors.theme4.moneyBorder, const Color(0xFF2A3237));
    expect(AppColors.theme4.textPrimary, const Color(0xFFF2F4F3));
    expect(AppColors.theme4.textSecondary, const Color(0xFF9AA5A0));

    expect(AppColors.theme5.bg, const Color(0xFFFCFCFC));
    expect(AppColors.theme5.primary, const Color(0xFF0C8F5B));
    expect(AppColors.theme5.accent, const Color(0xFF101613));
  });

  test(
    'reserved colors (verified/coin/live) are identical across all 5 themes',
    () {
      for (final theme in allThemes) {
        expect(theme.verified, allThemes.first.verified);
        expect(theme.coin, allThemes.first.coin);
        expect(theme.live, allThemes.first.live);
      }
    },
  );

  test(
    'every theme exposes a 6-color categorical ramp and a sequential ramp',
    () {
      for (final theme in allThemes) {
        expect(theme.chartCategorical, hasLength(6));
        expect(theme.chartSequential, isNotEmpty);
      }
    },
  );
}
