import 'package:cricunity/design_system/components/app_button.dart';
import 'package:cricunity/design_system/icons/app_icon_id.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// E16-10 · Non-negotiable #5: "Touch targets >= 44px." DS §10: "New
/// features must compose from §3 components before proposing new ones."
/// Auditing every shipped screen individually for this rule would be
/// hugely redundant -- almost every tappable control in the app is one
/// of these shared primitives. Auditing the primitives once here covers
/// every caller transitively instead.
void main() {
  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: Scaffold(body: Center(child: child)),
  );

  Size sizeOf(WidgetTester tester, Finder finder) =>
      tester.getSize(finder.first);

  testWidgets('AppButton meets the 44px floor in every variant', (
    tester,
  ) async {
    for (final variant in AppButtonVariant.values) {
      await tester.pumpWidget(
        harness(
          AppButton(variant: variant, label: 'Go', onPressed: () {}),
        ),
      );
      final size = sizeOf(tester, find.byKey(const ValueKey('appButtonSurface')));
      expect(
        size.height,
        greaterThanOrEqualTo(44),
        reason: '$variant is only ${size.height}px tall',
      );
    }
  });

  testWidgets('AppIconButton is a full 44x44 tap target', (tester) async {
    await tester.pumpWidget(
      harness(
        AppIconButton(
          icon: AppIconId.home,
          semanticLabel: 'Home',
          onPressed: () {},
        ),
      ),
    );
    final size = sizeOf(tester, find.byType(AppIconButton));
    expect(size.height, greaterThanOrEqualTo(44));
    expect(size.width, greaterThanOrEqualTo(44));
  });

  testWidgets(
    'AppChipActionButton -- 36h visual pill, real 44h tap target '
    '(fixed: this used to be a bare ~36px tap target)',
    (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        harness(
          AppChipActionButton(label: 'Yes', onPressed: () => tapped = true),
        ),
      );

      // The visual pill legitimately stays DS's specified 36h...
      final visual = sizeOf(
        tester,
        find.byKey(const ValueKey('appChipActionSurface')),
      );
      expect(visual.height, 36);

      // ...but the actual tap target is verified by tapping just inside
      // the 44h zone and outside the old 36h zone (an OverflowBox "paint
      // bigger without growing layout" trick was tried first and
      // empirically does not extend hit-testing -- see the component's
      // own doc comment -- so this only trusts a real registered tap).
      final center = tester.getCenter(
        find.byKey(const ValueKey('appChipActionSurface')),
      );
      await tester.tapAt(Offset(center.dx, center.dy - 20));
      await tester.pump();
      expect(tapped, isTrue);
    },
  );

  testWidgets('AppFab is a full 56x56 tap target (well above the floor)', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        AppFab(icon: AppIconId.home, semanticLabel: 'Create', onPressed: () {}),
      ),
    );
    final size = sizeOf(tester, find.byType(AppFab));
    expect(size.height, greaterThanOrEqualTo(44));
    expect(size.width, greaterThanOrEqualTo(44));
  });
}
