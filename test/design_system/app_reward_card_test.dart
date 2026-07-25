import 'package:cricunity/design_system/components/app_reward_card.dart';
import 'package:cricunity/design_system/icons/app_icon.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('renders the reward-type icon', (tester) async {
    await tester.pumpWidget(
      harness(const AppRewardCard(type: AppRewardType.chest)),
    );

    expect(find.byType(AppIcon), findsOneWidget);
  });

  testWidgets('the unclaimed badge only renders when unclaimed is true', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(const AppRewardCard(type: AppRewardType.scratch)),
    );
    expect(
      find.byKey(const ValueKey('appRewardCardUnclaimedBadge')),
      findsNothing,
    );

    await tester.pumpWidget(
      harness(
        const AppRewardCard(type: AppRewardType.scratch, unclaimed: true),
      ),
    );
    expect(
      find.byKey(const ValueKey('appRewardCardUnclaimedBadge')),
      findsOneWidget,
    );
  });

  testWidgets('the stacked-count pill only renders when count > 1', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(const AppRewardCard(type: AppRewardType.spin)),
    );
    expect(find.byKey(const ValueKey('appRewardCardCountPill')), findsNothing);

    await tester.pumpWidget(
      harness(const AppRewardCard(type: AppRewardType.spin, count: 3)),
    );
    expect(
      find.byKey(const ValueKey('appRewardCardCountPill')),
      findsOneWidget,
    );
    expect(find.text('×3'), findsOneWidget);
  });

  testWidgets('tapping the card fires onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      harness(
        AppRewardCard(type: AppRewardType.chest, onTap: () => tapped = true),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('appRewardCardBox')));
    expect(tapped, isTrue);
  });

  testWidgets('the glint sweep stays parked (inert) under reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: harness(const AppRewardCard(type: AppRewardType.chest)),
      ),
    );
    await tester.pump(const Duration(seconds: 3));

    final glint = tester.widget<AnimatedBuilder>(
      find.byKey(const ValueKey('appRewardCardGlint')),
    );
    expect((glint.listenable as AnimationController).value, 0);
  });
}
