import 'package:cricunity/design_system/components/app_swipe_action_row.dart';
import 'package:cricunity/design_system/icons/app_icon_id.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: Scaffold(body: SizedBox(width: 300, height: 80, child: child)),
  );

  testWidgets(
    'dragging right past the 40% threshold and releasing fires the left action',
    (tester) async {
      var triggered = false;
      await tester.pumpWidget(
        harness(
          AppSwipeActionRow(
            leftAction: AppSwipeAction(
              icon: AppIconId.shareArc,
              label: 'Share',
              color: Colors.blue,
              onTrigger: () => triggered = true,
            ),
            child: const ColoredBox(
              color: Colors.white,
              child: SizedBox.expand(),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(
          find.byKey(const ValueKey('appSwipeActionRowContent')),
        ),
      );
      await gesture.moveBy(const Offset(200, 0)); // 200/300 = 67% > 40%
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(triggered, isTrue);
    },
  );

  testWidgets('releasing before the threshold does not fire the action', (
    tester,
  ) async {
    var triggered = false;
    await tester.pumpWidget(
      harness(
        AppSwipeActionRow(
          leftAction: AppSwipeAction(
            icon: AppIconId.shareArc,
            label: 'Share',
            color: Colors.blue,
            onTrigger: () => triggered = true,
          ),
          child: const ColoredBox(
            color: Colors.white,
            child: SizedBox.expand(),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('appSwipeActionRowContent'))),
    );
    await gesture.moveBy(const Offset(50, 0)); // 50/300 = 17% < 40%
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(triggered, isFalse);
  });

  testWidgets('dragging left past the threshold fires the right action', (
    tester,
  ) async {
    var triggered = false;
    await tester.pumpWidget(
      harness(
        AppSwipeActionRow(
          rightAction: AppSwipeAction(
            icon: AppIconId.bookmark,
            label: 'Pin',
            color: Colors.orange,
            onTrigger: () => triggered = true,
          ),
          child: const ColoredBox(
            color: Colors.white,
            child: SizedBox.expand(),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('appSwipeActionRowContent'))),
    );
    await gesture.moveBy(const Offset(-200, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(triggered, isTrue);
  });
}
