import 'package:cricunity/design_system/components/app_tag_chip.dart';
import 'package:cricunity/design_system/icons/app_icon.dart';
import 'package:cricunity/design_system/icons/app_icon_id.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: Scaffold(body: Center(child: child)),
  );

  Color colorOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style!.color!;

  testWidgets('neutral variant uses textSecondary on surfaceAlt', (
    tester,
  ) async {
    await tester.pumpWidget(harness(const AppTagChip(label: 'Captain')));

    final colors = AppTheme.themes[AppTheme.defaultLight]!
        .extension<AppColors>()!;
    expect(colorOf(tester, 'Captain'), colors.textSecondary);

    final container = tester.widget<Container>(
      find.byKey(const ValueKey('appTagChipSurface')),
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, colors.surfaceAlt);
  });

  for (final entry in {
    AppTagChipVariant.verified: 'verified',
    AppTagChipVariant.success: 'success',
    AppTagChipVariant.warning: 'warning',
    AppTagChipVariant.error: 'error',
  }.entries) {
    testWidgets('${entry.value} variant tints text and background', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(AppTagChip(label: 'Label', variant: entry.key)),
      );

      final colors = AppTheme.themes[AppTheme.defaultLight]!
          .extension<AppColors>()!;
      final expectedForeground = switch (entry.key) {
        AppTagChipVariant.verified => colors.verified,
        AppTagChipVariant.success => colors.success,
        AppTagChipVariant.warning => colors.warning,
        AppTagChipVariant.error => colors.error,
        AppTagChipVariant.neutral => colors.textSecondary,
      };
      expect(colorOf(tester, 'Label'), expectedForeground);

      final container = tester.widget<Container>(
        find.byKey(const ValueKey('appTagChipSurface')),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, expectedForeground.withValues(alpha: 0.12));
    });
  }

  testWidgets('renders a leading icon when provided', (tester) async {
    await tester.pumpWidget(
      harness(
        const AppTagChip(label: 'Sanctioned', icon: AppIconId.verifiedCheck),
      ),
    );

    expect(find.byType(AppIcon), findsOneWidget);
  });

  testWidgets('omits the leading icon when not provided', (tester) async {
    await tester.pumpWidget(harness(const AppTagChip(label: 'Captain')));

    expect(find.byType(AppIcon), findsNothing);
  });

  testWidgets('chip height is 24', (tester) async {
    await tester.pumpWidget(harness(const AppTagChip(label: 'Captain')));

    final rect = tester.getRect(
      find.byKey(const ValueKey('appTagChipSurface')),
    );
    expect(rect.height, 24);
  });

  testWidgets('delta chip renders the up arrow in success color', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const AppDeltaChip(value: '12%', direction: AppDeltaDirection.up),
      ),
    );

    final colors = AppTheme.themes[AppTheme.defaultLight]!
        .extension<AppColors>()!;
    expect(colorOf(tester, '▲'), colors.success);
    expect(colorOf(tester, '12%'), colors.success);
  });

  testWidgets('delta chip renders the down arrow in neutral textTertiary', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const AppDeltaChip(value: '3%', direction: AppDeltaDirection.down),
      ),
    );

    final colors = AppTheme.themes[AppTheme.defaultLight]!
        .extension<AppColors>()!;
    expect(colorOf(tester, '▼'), colors.textTertiary);
    expect(colorOf(tester, '3%'), colors.textTertiary);
  });
}
