import 'package:cricunity/design_system/components/app_pressable.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('tapping fires onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      harness(
        AppPressable(
          onPressed: () => tapped = true,
          tintColor: Colors.blue,
          cornerRadius: 8,
          focusRingColor: Colors.blue,
          child: const SizedBox(width: 100, height: 40),
        ),
      ),
    );

    await tester.tap(find.byType(AppPressable));
    expect(tapped, isTrue);
  });

  testWidgets('long-pressing fires onLongPress', (tester) async {
    var longPressed = false;
    await tester.pumpWidget(
      harness(
        AppPressable(
          onPressed: () {},
          onLongPress: () => longPressed = true,
          tintColor: Colors.blue,
          cornerRadius: 8,
          focusRingColor: Colors.blue,
          child: const SizedBox(width: 100, height: 40),
        ),
      ),
    );

    await tester.longPress(find.byType(AppPressable));
    expect(longPressed, isTrue);
  });

  testWidgets('disabled (no callbacks) does not crash on tap', (tester) async {
    await tester.pumpWidget(
      harness(
        AppPressable(
          onPressed: null,
          tintColor: Colors.blue,
          cornerRadius: 8,
          focusRingColor: Colors.blue,
          child: const SizedBox(width: 100, height: 40),
        ),
      ),
    );

    await tester.tap(find.byType(AppPressable), warnIfMissed: false);
    await tester.pump();
  });

  testWidgets('pressing scales down; releasing returns to normal', (
    tester,
  ) async {
    final childKey = GlobalKey();
    await tester.pumpWidget(
      harness(
        AppPressable(
          onPressed: () {},
          tintColor: Colors.blue,
          cornerRadius: 8,
          focusRingColor: Colors.blue,
          child: SizedBox(key: childKey, width: 100, height: 40),
        ),
      ),
    );

    double scale() => tester
        .widget<Transform>(
          find.ancestor(
            of: find.byKey(childKey),
            matching: find.byType(Transform),
          ),
        )
        .transform
        .entry(0, 0);

    expect(scale(), closeTo(1.0, 0.001));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(childKey)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(scale(), lessThan(0.99));

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(scale(), closeTo(1.0, 0.001));
  });

  testWidgets('keyboard focus shows the ring; losing focus hides it', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        AppPressable(
          onPressed: () {},
          tintColor: Colors.blue,
          cornerRadius: 8,
          focusRingColor: AppColors.theme1.primary,
          child: const SizedBox(width: 100, height: 40),
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
}
