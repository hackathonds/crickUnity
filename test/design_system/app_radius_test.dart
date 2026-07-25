import 'package:cricunity/design_system/tokens/app_radius.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('radius tokens match DS §2.2', () {
    expect(AppRadius.xs, 6);
    expect(AppRadius.sm, 10);
    expect(AppRadius.md, 14);
    expect(AppRadius.lg, 20);
  });

  test('BorderRadius helpers use matching corner values', () {
    expect(AppRadius.mdRadius.topLeft.x, AppRadius.md);
    expect(AppRadius.lgRadius.topLeft.x, AppRadius.lg);
  });
}
