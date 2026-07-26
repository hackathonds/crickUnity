import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/teams/season_summary_models.dart';
import 'package:cricunity/teams/season_summary_screen.dart';
import 'package:cricunity/teams/team_member_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _emptyData = SeasonSummaryData(
  matchesPlayed: 0,
  winsCount: 0,
  lossesCount: 0,
  drawsCount: 0,
  championshipsWon: 0,
  topScorerName: '',
  topScorerRuns: 0,
  topWicketTakerName: '',
  topWicketTakerWickets: 0,
  bestWinDescription: '',
  chemistryTrendPercent: 0,
  moneyCollectedRupees: 0,
  moneySpentRupees: 0,
  perHeadCostRupees: 0,
);

void main() {
  Widget harness({
    required TeamMemberRole viewerRole,
    required SeasonSummaryData data,
  }) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: SeasonSummaryScreen(viewerRole: viewerRole, data: data),
  );

  void setTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets(
    'AC: a brand-new team with no matches shows the insufficient-data '
    'state',
    (tester) async {
      setTallViewport(tester);
      await tester.pumpWidget(
        harness(viewerRole: TeamMemberRole.captain, data: _emptyData),
      );

      expect(
        find.byKey(const ValueKey('seasonSummaryInsufficientData')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('wrapCard_record')), findsNothing);
    },
  );

  testWidgets('milestone cards render only for crossed thresholds', (
    tester,
  ) async {
    setTallViewport(tester);
    await tester.pumpWidget(
      harness(viewerRole: TeamMemberRole.captain, data: mockSeasonSummary()),
    );

    expect(
      find.byKey(const ValueKey('milestoneCard_fiftiethWin')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('milestoneCard_hundredthMatch')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('milestoneCard_firstChampionship')),
      findsOneWidget,
    );
  });

  testWidgets('no milestone cards render below every threshold', (
    tester,
  ) async {
    setTallViewport(tester);
    await tester.pumpWidget(
      harness(
        viewerRole: TeamMemberRole.captain,
        data: const SeasonSummaryData(
          matchesPlayed: 5,
          winsCount: 2,
          lossesCount: 2,
          drawsCount: 1,
          championshipsWon: 0,
          topScorerName: 'Rohan Verma',
          topScorerRuns: 120,
          topWicketTakerName: 'Priya Nair',
          topWicketTakerWickets: 6,
          bestWinDescription: 'A close win',
          chemistryTrendPercent: 3,
          moneyCollectedRupees: 2000,
          moneySpentRupees: 1800,
          perHeadCostRupees: 200,
        ),
      ),
    );

    expect(find.textContaining('Milestones'), findsNothing);
    expect(find.byKey(const ValueKey('wrapCard_record')), findsOneWidget);
  });

  testWidgets(
    'AC: Present and public-share preview are structurally absent for '
    'a plain player, not just disabled',
    (tester) async {
      setTallViewport(tester);
      await tester.pumpWidget(
        harness(viewerRole: TeamMemberRole.player, data: mockSeasonSummary()),
      );

      expect(find.byKey(const ValueKey('presentCeremonyButton')), findsNothing);
      expect(
        find.byKey(const ValueKey('previewPublicShareButton')),
        findsNothing,
      );
    },
  );

  testWidgets('AC: the public-share preview never includes the money card', (
    tester,
  ) async {
    setTallViewport(tester);
    await tester.pumpWidget(
      harness(viewerRole: TeamMemberRole.captain, data: mockSeasonSummary()),
    );

    await tester.tap(find.byKey(const ValueKey('previewPublicShareButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('publicShareCard_money')), findsNothing);
    expect(
      find.byKey(const ValueKey('publicShareCard_record')),
      findsOneWidget,
    );
  });

  testWidgets('Present opens a full-screen ceremony that tap-advances through '
      'every wrap card, including money, then exits', (tester) async {
    setTallViewport(tester);
    await tester.pumpWidget(
      harness(viewerRole: TeamMemberRole.captain, data: mockSeasonSummary()),
    );

    await tester.tap(find.byKey(const ValueKey('presentCeremonyButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('ceremonyCard_record')), findsOneWidget);

    for (final typeName in [
      'topPerformers',
      'bestWin',
      'chemistryTrend',
      'money',
    ]) {
      await tester.tap(find.byKey(const ValueKey('ceremonyTapAdvance')));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('ceremonyCard_$typeName')), findsOneWidget);
    }

    // One more tap past the last card exits the ceremony.
    await tester.tap(find.byKey(const ValueKey('ceremonyTapAdvance')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ceremonyTapAdvance')), findsNothing);
    expect(find.byKey(const ValueKey('presentCeremonyButton')), findsOneWidget);
  });
}
