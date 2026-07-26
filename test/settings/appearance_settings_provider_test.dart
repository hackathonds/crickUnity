import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/design_system/tokens/app_typography.dart';
import 'package:cricunity/settings/appearance_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to following the system for every setting', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final settings = container.read(appearanceSettingsProvider);

    expect(settings.themeOverride, isNull);
    expect(settings.textScaleOverride, isNull);
    expect(settings.reducedMotionOverride, isFalse);
  });

  test('setThemeOverride sets and clears the override', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(appearanceSettingsProvider.notifier);

    notifier.setThemeOverride(AppThemeId.theme3);
    expect(
      container.read(appearanceSettingsProvider).themeOverride,
      AppThemeId.theme3,
    );

    notifier.setThemeOverride(null);
    expect(container.read(appearanceSettingsProvider).themeOverride, isNull);
  });

  test('setTextScale clamps to the app-wide 100%-135% range', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(appearanceSettingsProvider.notifier);

    notifier.setTextScale(2.0);
    expect(
      container.read(appearanceSettingsProvider).textScaleOverride,
      AppTypography.maxTextScaleFactor,
    );

    notifier.setTextScale(0.5);
    expect(container.read(appearanceSettingsProvider).textScaleOverride, 1.0);

    notifier.setTextScale(1.2);
    expect(container.read(appearanceSettingsProvider).textScaleOverride, 1.2);
  });

  test('setReducedMotionOverride toggles independently of other settings', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(appearanceSettingsProvider.notifier);

    notifier.setThemeOverride(AppThemeId.theme2);
    notifier.setReducedMotionOverride(true);

    final settings = container.read(appearanceSettingsProvider);
    expect(settings.reducedMotionOverride, isTrue);
    expect(settings.themeOverride, AppThemeId.theme2);
  });
}
