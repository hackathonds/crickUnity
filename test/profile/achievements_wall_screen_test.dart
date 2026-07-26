import 'package:cricunity/design_system/components/app_badge_tile.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/profile/achievement_models.dart';
import 'package:cricunity/profile/achievements_wall_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(List<AchievementBadge> badges) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: AchievementsWallScreen(badges: badges),
  );

  // The grid (and the >4-option category chip row) only lazily builds
  // items within the viewport's cache extent -- same sliver lazy-build
  // gotcha hit repeatedly elsewhere this session (E0-02/E0-03,
  // profile_screen_test.dart). A tall, wide surface keeps every badge
  // tile and every filter chip actually mounted.
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('renders every badge as a tile, earned and locked alike', (
    tester,
  ) async {
    useTallViewport(tester);
    final badges = mockAchievementBadges();
    await tester.pumpWidget(harness(badges));

    expect(find.byType(AppBadgeTile), findsNWidgets(badges.length));
    final tiles = tester.widgetList<AppBadgeTile>(find.byType(AppBadgeTile));
    expect(
      tiles.where((t) => t.earned).length,
      badges.where((b) => b.earned).length,
    );
    expect(
      tiles.where((t) => !t.earned).length,
      badges.where((b) => !b.earned).length,
    );
  });

  testWidgets('filtering by category shows only that category\'s badges', (
    tester,
  ) async {
    useTallViewport(tester);
    final badges = mockAchievementBadges();
    await tester.pumpWidget(harness(badges));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Service'));
    await tester.pumpAndSettle();

    final expectedCount = badges
        .where((b) => b.category == BadgeCategory.service)
        .length;
    expect(find.byType(AppBadgeTile), findsNWidgets(expectedCount));
  });

  testWidgets('AC: an empty category filter shows the Empty state with a '
      'way back to All', (tester) async {
    useTallViewport(tester);
    final badges = mockAchievementBadges();
    final emptyCategory = BadgeCategory.values.firstWhere(
      (c) => !badges.any((b) => b.category == c),
      orElse: () => BadgeCategory.special,
    );
    final noneOfThatCategory = badges
        .where((b) => b.category != emptyCategory)
        .toList();

    await tester.pumpWidget(harness(noneOfThatCategory));
    await tester.pumpAndSettle();
    await tester.tap(find.text(badgeCategoryLabels[emptyCategory]!));
    await tester.pumpAndSettle();

    expect(find.byType(AppBadgeTile), findsNothing);
    expect(find.text('View all badges'), findsOneWidget);

    await tester.tap(find.text('View all badges'));
    await tester.pumpAndSettle();

    expect(find.byType(AppBadgeTile), findsNWidgets(noneOfThatCategory.length));
  });

  testWidgets('tapping an earned badge opens its detail sheet with criteria, '
      'rarity, friends and earn date', (tester) async {
    useTallViewport(tester);
    final badges = mockAchievementBadges();
    final earned = badges.firstWhere(
      (b) => b.earned && b.friendsWhoHold.isNotEmpty,
    );
    await tester.pumpWidget(harness(badges));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(ValueKey('achievementBadgeTile_${earned.name}')),
    );
    await tester.pumpAndSettle();

    expect(find.text(earned.criteria), findsOneWidget);
    expect(
      find.text('Rarity: ${earned.rarityPercent}% of players'),
      findsOneWidget,
    );
    expect(find.text(earned.earnDateAndProvenance!), findsOneWidget);
    for (final friend in earned.friendsWhoHold) {
      expect(find.text(friend), findsNothing); // avatars, not name text
    }
  });

  testWidgets(
    'tapping a locked badge still opens its detail sheet, showing criteria '
    'and a "not yet earned" state instead of an earn date',
    (tester) async {
      useTallViewport(tester);
      final badges = mockAchievementBadges();
      final locked = badges.firstWhere((b) => !b.earned);
      await tester.pumpWidget(harness(badges));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(ValueKey('achievementBadgeTile_${locked.name}')),
      );
      await tester.pumpAndSettle();

      expect(find.text(locked.criteria), findsOneWidget);
      expect(find.text('Not yet earned'), findsOneWidget);
    },
  );
}
