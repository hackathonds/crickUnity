import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/settings/appearance_settings_provider.dart';
import 'package:cricunity/settings/appearance_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness() => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: const AppearanceSettingsScreen(),
    ),
  );

  testWidgets('System is selected by default; every theme card renders', (
    tester,
  ) async {
    await tester.pumpWidget(harness());

    expect(find.text('System'), findsOneWidget);
    expect(find.text('Modern Cricket Green'), findsOneWidget);
    expect(find.text('Royal Navy Gold'), findsOneWidget);
    expect(find.text('Electric Blue'), findsOneWidget);
    expect(find.text('Dark Graphite Neon'), findsOneWidget);
    expect(find.text('Premium White Emerald'), findsOneWidget);
  });

  testWidgets('tapping a theme card selects it in the provider', (
    tester,
  ) async {
    await tester.pumpWidget(harness());

    await tester.tap(find.byKey(const ValueKey('appearanceThemeCard_theme3')));
    await tester.pump();

    final context = tester.element(find.byType(AppearanceSettingsScreen));
    final container = ProviderScope.containerOf(context);
    expect(
      container.read(appearanceSettingsProvider).themeOverride,
      AppThemeId.theme3,
    );
  });

  testWidgets('tapping System after a theme pick clears the override', (
    tester,
  ) async {
    await tester.pumpWidget(harness());

    await tester.tap(find.byKey(const ValueKey('appearanceThemeCard_theme3')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('appearanceThemeCard_system')));
    await tester.pump();

    final context = tester.element(find.byType(AppearanceSettingsScreen));
    final container = ProviderScope.containerOf(context);
    expect(container.read(appearanceSettingsProvider).themeOverride, isNull);
  });

  testWidgets('dragging the text-size slider updates the provider', (
    tester,
  ) async {
    await tester.pumpWidget(harness());

    final slider = find.byKey(const ValueKey('appearanceTextScaleSlider'));
    await tester.drag(slider, const Offset(1000, 0));
    await tester.pump();

    final context = tester.element(find.byType(AppearanceSettingsScreen));
    final container = ProviderScope.containerOf(context);
    expect(container.read(appearanceSettingsProvider).textScaleOverride, 1.35);
  });

  testWidgets('toggling reduced motion updates the provider', (tester) async {
    await tester.pumpWidget(harness());

    expect(
      ProviderScope.containerOf(
        tester.element(find.byType(AppearanceSettingsScreen)),
      ).read(appearanceSettingsProvider).reducedMotionOverride,
      isFalse,
    );

    await tester.tap(
      find.byKey(const ValueKey('appearanceReducedMotionSwitch')),
    );
    await tester.pump();

    final context = tester.element(find.byType(AppearanceSettingsScreen));
    final container = ProviderScope.containerOf(context);
    expect(
      container.read(appearanceSettingsProvider).reducedMotionOverride,
      isTrue,
    );
  });
}
