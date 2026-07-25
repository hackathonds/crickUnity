import 'package:cricunity/design_system/tokens/app_elevation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const borderColor = Color(0xFF2A3237);

  test('Theme 4 (dark): money surface keeps a 1px border', () {
    final style = AppElevation.resolveSurfaceStyle(
      level: AppElevationLevel.e1,
      brightness: Brightness.dark,
      borderColor: borderColor,
      isMoneySurface: true,
    );
    expect(style.border, isNotNull);
    expect(style.border!.width, 1);
    expect(style.border!.color, borderColor);
    expect(style.darkSurfaceLuminanceDelta, 0);
  });

  test(
    'Theme 4 (dark): non-money surface has no border, uses +lum elevation instead',
    () {
      final style = AppElevation.resolveSurfaceStyle(
        level: AppElevationLevel.e2,
        brightness: Brightness.dark,
        borderColor: borderColor,
        isMoneySurface: false,
      );
      expect(style.border, isNull);
      expect(style.darkSurfaceLuminanceDelta, AppElevation.darkLuminanceE2);
    },
  );

  test('light theme surfaces get a hairline border + shadow, money or not', () {
    final money = AppElevation.resolveSurfaceStyle(
      level: AppElevationLevel.e1,
      brightness: Brightness.light,
      borderColor: borderColor,
      isMoneySurface: true,
    );
    final nonMoney = AppElevation.resolveSurfaceStyle(
      level: AppElevationLevel.e1,
      brightness: Brightness.light,
      borderColor: borderColor,
      isMoneySurface: false,
    );
    expect(money.border!.width, 1);
    expect(nonMoney.border!.width, 1);
    expect(nonMoney.shadows, isNotEmpty);
  });

  test('e1/e2/e3 shadow specs match DS §2.2', () {
    expect(AppElevation.e1.offsetY, 2);
    expect(AppElevation.e1.blurRadius, 8);
    expect(AppElevation.e2.offsetY, 4);
    expect(AppElevation.e2.blurRadius, 16);
    expect(AppElevation.e3.offsetY, 8);
    expect(AppElevation.e3.blurRadius, 32);
  });
}
