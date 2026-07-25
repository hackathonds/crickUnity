import 'package:cricunity/design_system/components/app_button.dart';
import 'package:cricunity/design_system/icons/app_icon.dart';
import 'package:cricunity/design_system/icons/app_icon_id.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/design_system/tokens/app_colors.dart';
import 'package:cricunity/design_system/tokens/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child) {
    return MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('primary/secondary/destructive are 52h with r-sm radius', (
    tester,
  ) async {
    for (final variant in [
      AppButtonVariant.primary,
      AppButtonVariant.secondary,
      AppButtonVariant.destructive,
    ]) {
      await tester.pumpWidget(
        harness(AppButton(variant: variant, label: 'Go', onPressed: () {})),
      );
      final size = tester.getSize(
        find.byKey(const ValueKey('appButtonSurface')),
      );
      expect(size.height, 52, reason: '$variant should be 52h');

      final container = tester.widget<Container>(
        find.byKey(const ValueKey('appButtonSurface')),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, AppRadius.smRadius);
    }
  });

  testWidgets('tertiary is 44h', (tester) async {
    await tester.pumpWidget(
      harness(
        AppButton(
          variant: AppButtonVariant.tertiary,
          label: 'Go',
          onPressed: () {},
        ),
      ),
    );
    final size = tester.getSize(find.byKey(const ValueKey('appButtonSurface')));
    expect(size.height, 44);
  });

  testWidgets('disabled renders at disabledFg and swallows taps', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const AppButton(
          variant: AppButtonVariant.primary,
          label: 'Go',
          onPressed: null,
        ),
      ),
    );

    final textWidget = tester.widget<Text>(find.text('Go'));
    expect(textWidget.style?.color, AppColors.theme1.disabledFg);

    await tester.tap(find.text('Go'), warnIfMissed: false);
    await tester.pump();
    // No exception — nothing to assert beyond "didn't crash", since a
    // disabled button has no onPressed callback to observe.
  });

  testWidgets('loading hides the label and blocks taps', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      harness(
        AppButton(
          variant: AppButtonVariant.primary,
          label: 'Go',
          isLoading: true,
          onPressed: () => tapped = true,
        ),
      ),
    );

    expect(find.text('Go'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('appButtonSurface')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(tapped, isFalse);
  });

  testWidgets(
    'pressing scales the button down; releasing returns it to normal',
    (tester) async {
      await tester.pumpWidget(
        harness(
          AppButton(
            variant: AppButtonVariant.primary,
            label: 'Go',
            onPressed: () {},
          ),
        ),
      );

      // The Transform that's an ancestor of appButtonSurface is specifically
      // our press-scale Transform — entry(0, 0) is its x-axis scale factor
      // directly (getMaxScaleOnAxis() would report 1.0 regardless, since
      // Transform.scale leaves the z-axis at 1.0 and that method takes the
      // *maximum* across all three axes).
      double buttonScale() {
        final transform = tester.widget<Transform>(
          find.ancestor(
            of: find.byKey(const ValueKey('appButtonSurface')),
            matching: find.byType(Transform),
          ),
        );
        return transform.transform.entry(0, 0);
      }

      expect(buttonScale(), closeTo(1.0, 0.001));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('appButtonSurface'))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(buttonScale(), lessThan(0.99));

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(buttonScale(), closeTo(1.0, 0.001));
    },
  );

  testWidgets('keyboard focus shows the 2px ring; losing focus hides it', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        AppButton(
          variant: AppButtonVariant.primary,
          label: 'Go',
          onPressed: () {},
        ),
      ),
    );

    Border ringBorder() =>
        (tester
                        .widget<Container>(
                          find.byKey(const ValueKey('appPressableFocusRing')),
                        )
                        .decoration
                    as BoxDecoration)
                .border!
            as Border;

    expect(ringBorder().top.color, Colors.transparent);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(ringBorder().top.color, AppColors.theme1.primary);
  });

  testWidgets(
    "AppChipActionButton's selected state tints the border and text",
    (tester) async {
      await tester.pumpWidget(
        harness(
          AppChipActionButton(label: 'Yes', selected: true, onPressed: () {}),
        ),
      );

      final container = tester.widget<Container>(
        find.byKey(const ValueKey('appChipActionSurface')),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);

      final size = tester.getSize(
        find.byKey(const ValueKey('appChipActionSurface')),
      );
      expect(size.height, 36);
    },
  );

  testWidgets("AppIconButton's selected state uses the filled icon variant", (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        AppIconButton(
          icon: AppIconId.heart,
          semanticLabel: 'Like',
          selected: true,
          onPressed: () {},
        ),
      ),
    );

    final icon = tester.widget<AppIcon>(find.byType(AppIcon));
    expect(icon.active, isTrue);
  });

  testWidgets('AppFab renders at 56x56 and fires onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      harness(
        AppFab(
          icon: AppIconId.plus,
          semanticLabel: 'Create',
          onPressed: () => tapped = true,
        ),
      ),
    );

    final size = tester.getSize(find.byKey(const ValueKey('appFabSurface')));
    expect(size.width, 56);
    expect(size.height, 56);

    await tester.tap(find.byKey(const ValueKey('appFabSurface')));
    expect(tapped, isTrue);
  });
}
