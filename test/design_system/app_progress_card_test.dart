import 'package:cricunity/design_system/components/app_arc_ring.dart';
import 'package:cricunity/design_system/components/app_progress_card.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: Scaffold(body: child),
  );

  testWidgets('ring variant renders AppArcRing, not the bar', (tester) async {
    await tester.pumpWidget(
      harness(
        const AppProgressCard(
          title: 'Century Chase',
          rewardLabel: '+50 XP',
          variant: AppProgressCardVariant.ring,
          progress: 0.5,
          progressCaption: '50/100 runs · 9 days left',
        ),
      ),
    );

    expect(find.byType(AppArcRing), findsOneWidget);
    expect(find.byKey(const ValueKey('appProgressCardBar')), findsNothing);
  });

  testWidgets('bar variant renders the linear bar, not AppArcRing', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const AppProgressCard(
          title: 'Weekly Wickets',
          rewardLabel: '+30 XP',
          variant: AppProgressCardVariant.bar,
          progress: 0.4,
          progressCaption: '4/10 wickets · 3 days left',
        ),
      ),
    );

    expect(find.byKey(const ValueKey('appProgressCardBar')), findsOneWidget);
    expect(find.byType(AppArcRing), findsNothing);
  });

  testWidgets('renders the title, reward chip, and caption', (tester) async {
    await tester.pumpWidget(
      harness(
        const AppProgressCard(
          title: 'Century Chase',
          rewardLabel: '+50 XP',
          variant: AppProgressCardVariant.ring,
          progress: 0.5,
          progressCaption: '50/100 runs · 9 days left',
        ),
      ),
    );

    expect(find.text('Century Chase'), findsOneWidget);
    expect(find.text('+50 XP'), findsOneWidget);
    expect(find.text('50/100 runs · 9 days left'), findsOneWidget);
  });

  testWidgets('the pulse plays when progress >= 0.8', (tester) async {
    await tester.pumpWidget(
      harness(
        const AppProgressCard(
          title: 'Century Chase',
          rewardLabel: '+50 XP',
          variant: AppProgressCardVariant.ring,
          progress: 0.85,
          progressCaption: '85/100 runs',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));

    final pulse = tester.widget<AnimatedBuilder>(
      find.byKey(const ValueKey('appProgressCardPulse')),
    );
    expect((pulse.listenable as Animation<double>).value, greaterThan(1.0));
  });

  testWidgets('the pulse does not play when progress < 0.8', (tester) async {
    await tester.pumpWidget(
      harness(
        const AppProgressCard(
          title: 'Century Chase',
          rewardLabel: '+50 XP',
          variant: AppProgressCardVariant.ring,
          progress: 0.5,
          progressCaption: '50/100 runs',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));

    final pulse = tester.widget<AnimatedBuilder>(
      find.byKey(const ValueKey('appProgressCardPulse')),
    );
    expect((pulse.listenable as Animation<double>).value, 1.0);
  });

  testWidgets('the pulse is skipped under reduced motion', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: harness(
          const AppProgressCard(
            title: 'Century Chase',
            rewardLabel: '+50 XP',
            variant: AppProgressCardVariant.ring,
            progress: 0.9,
            progressCaption: '90/100 runs',
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));

    final pulse = tester.widget<AnimatedBuilder>(
      find.byKey(const ValueKey('appProgressCardPulse')),
    );
    expect((pulse.listenable as Animation<double>).value, 1.0);
  });

  testWidgets(
    'failed renders ColorFiltered and shows failedCopy instead of the caption',
    (tester) async {
      await tester.pumpWidget(
        harness(
          const AppProgressCard(
            title: 'Century Chase',
            rewardLabel: '+50 XP',
            variant: AppProgressCardVariant.ring,
            progress: 0.3,
            progressCaption: '30/100 runs',
            failed: true,
            failedCopy: 'Ends 30 Jun — try next month',
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('appProgressCardDesaturated')),
        findsOneWidget,
      );
      expect(find.text('Ends 30 Jun — try next month'), findsOneWidget);
      expect(find.text('30/100 runs'), findsNothing);
    },
  );
}
