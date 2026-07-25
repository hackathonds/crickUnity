import 'package:cricunity/design_system/tokens/app_spacing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('spacing scale matches DS §2.1 exactly', () {
    expect(AppSpacing.scale, [4, 8, 12, 16, 20, 24, 32, 40, 48]);
  });

  test('named tokens map to the right scale step', () {
    expect(AppSpacing.xs, 4);
    expect(AppSpacing.sm, 8);
    expect(AppSpacing.md, 12);
    expect(AppSpacing.lg, 16);
    expect(AppSpacing.xl, 20);
    expect(AppSpacing.xxl, 24);
    expect(AppSpacing.xxxl, 32);
    expect(AppSpacing.huge, 40);
    expect(AppSpacing.massive, 48);
  });
}
