import 'package:cricunity/design_system/components/app_badge_tile.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/profile/profile_models.dart';
import 'package:cricunity/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ProviderScope: the self-view ⋮ menu opens a Riverpod-backed
  // Availability sheet (E2-08).
  Widget harness(Widget child) => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: child,
    ),
  );

  PlayerProfile profileWith({
    bool isMinor = false,
    ProfileVisibility visibility = ProfileVisibility.public,
    bool statsVerified = true,
  }) {
    final base = mockPlayerProfile();
    return PlayerProfile(
      name: base.name,
      city: base.city,
      bio: base.bio,
      roleChips: base.roleChips,
      headerStats: ProfileHeaderStats(
        matches: base.headerStats.matches,
        runs: base.headerStats.runs,
        wickets: base.headerStats.wickets,
        rating: base.headerStats.rating,
        verified: statsVerified,
      ),
      pinnedBadges: base.pinnedBadges,
      recentForm: base.recentForm,
      favoriteTeams: base.favoriteTeams,
      endorsements: base.endorsements,
      weaknesses: base.weaknesses,
      isMinor: isMinor,
      visibility: visibility,
    );
  }

  testWidgets('self relation shows Edit/Share/QR, no Follow/Message', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        ProfileScreen(profile: profileWith(), relation: ViewerRelation.self),
      ),
    );

    expect(find.byKey(const ValueKey('profileEditButton')), findsOneWidget);
    expect(find.byKey(const ValueKey('profileShareButton')), findsOneWidget);
    expect(find.byKey(const ValueKey('profileQrButton')), findsOneWidget);
    expect(find.byKey(const ValueKey('profileFollowButton')), findsNothing);
    expect(find.byKey(const ValueKey('profileMessageButton')), findsNothing);
  });

  testWidgets('teammate relation shows Follow, Message, and the menu', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        ProfileScreen(
          profile: profileWith(),
          relation: ViewerRelation.teammate,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('profileFollowButton')), findsOneWidget);
    expect(find.byKey(const ValueKey('profileMessageButton')), findsOneWidget);
    expect(find.byKey(const ValueKey('profileMenuButton')), findsOneWidget);
  });

  testWidgets(
    'follower/public relation shows Follow and the menu but no Message',
    (tester) async {
      await tester.pumpWidget(
        harness(
          ProfileScreen(
            profile: profileWith(),
            relation: ViewerRelation.public,
          ),
        ),
      );

      expect(find.byKey(const ValueKey('profileFollowButton')), findsOneWidget);
      expect(find.byKey(const ValueKey('profileMessageButton')), findsNothing);
    },
  );

  testWidgets(
    'a private profile viewed by a non-follower shows the minimal locked '
    'card + Request Follow (AC)',
    (tester) async {
      var requested = false;
      await tester.pumpWidget(
        harness(
          ProfileScreen(
            profile: profileWith(visibility: ProfileVisibility.private),
            relation: ViewerRelation.public,
            onRequestFollow: () => requested = true,
          ),
        ),
      );

      expect(find.byKey(const ValueKey('profileLockedLabel')), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('profileLockedRequestFollow')),
      );
      expect(requested, isTrue);
      expect(find.byKey(const ValueKey('profileTabBar')), findsNothing);
    },
  );

  testWidgets(
    'an already-approved follower still sees the full private profile',
    (tester) async {
      await tester.pumpWidget(
        harness(
          ProfileScreen(
            profile: profileWith(visibility: ProfileVisibility.private),
            relation: ViewerRelation.follower,
          ),
        ),
      );

      expect(find.byKey(const ValueKey('profileTabBar')), findsOneWidget);
      expect(find.byKey(const ValueKey('profileLockedLabel')), findsNothing);
    },
  );

  testWidgets('a minor profile is forced private even if marked public', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        ProfileScreen(
          profile: profileWith(isMinor: true),
          relation: ViewerRelation.public,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('profileLockedLabel')), findsOneWidget);
  });

  testWidgets('a blocked viewer sees "Profile unavailable" (AC)', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        ProfileScreen(profile: profileWith(), relation: ViewerRelation.blocked),
      ),
    );

    expect(find.byKey(const ValueKey('profileBlockedMessage')), findsOneWidget);
  });

  testWidgets('verified stats render without the unverified dashed treatment', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        ProfileScreen(
          profile: profileWith(statsVerified: true),
          relation: ViewerRelation.self,
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('profileStatHeaderStrip')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('profileStatHeaderUnverified')),
      findsNothing,
    );
  });

  testWidgets('unverified stats render lighter + dashed (Pillar 2, AC)', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        ProfileScreen(
          profile: profileWith(statsVerified: false),
          relation: ViewerRelation.self,
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('profileStatHeaderUnverified')),
      findsOneWidget,
    );
  });

  testWidgets('the pinned badge strip renders every pinned badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        ProfileScreen(profile: profileWith(), relation: ViewerRelation.self),
      ),
    );

    expect(
      find.byKey(const ValueKey('profilePinnedBadgeStrip')),
      findsOneWidget,
    );
    // AppBadgeTile doesn't render its `name` as visible text (only the
    // detail sheet does) -- assert the expected number/colors of tiles
    // instead of searching for label text that was never there.
    final tiles = tester
        .widgetList<AppBadgeTile>(find.byType(AppBadgeTile))
        .toList();
    expect(tiles, hasLength(mockPlayerProfile().pinnedBadges.length));
    for (var i = 0; i < tiles.length; i++) {
      expect(tiles[i].color, mockPlayerProfile().pinnedBadges[i].color);
      expect(tiles[i].earned, isTrue);
    }
  });

  testWidgets('tapping "See all" next to the badge strip opens achievements', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      harness(
        ProfileScreen(
          profile: profileWith(),
          relation: ViewerRelation.self,
          onOpenAchievements: () => opened = true,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('profileSeeAllBadges')));
    await tester.pump();

    expect(opened, isTrue);
  });

  testWidgets('tapping a tab switches the tab content', (tester) async {
    // Unpinned slivers past the pinned stat header aren't laid out (so
    // never even mount) if they fall outside the viewport's cache extent
    // on the default small test surface -- same sliver lazy-build gotcha
    // already hit in E0-02/E0-03 (see app_shell_test.dart's drawer test).
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      harness(
        ProfileScreen(profile: profileWith(), relation: ViewerRelation.self),
      ),
    );

    expect(find.byKey(const ValueKey('profileRecentFormRow')), findsOneWidget);

    await tester.tap(find.text('Stats'));
    await tester.pump();

    expect(find.byKey(const ValueKey('profileRecentFormRow')), findsNothing);
    expect(find.textContaining('E2-03'), findsOneWidget);
  });

  testWidgets('AC: a follower viewing the full profile screen never sees the '
      'weaknesses surface', (tester) async {
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      harness(
        ProfileScreen(
          profile: profileWith(),
          relation: ViewerRelation.follower,
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('profileWeaknessesSection')),
      findsNothing,
    );
  });

  testWidgets(
    'self sees a profile-menu (⋮) that opens the Availability sheet',
    (tester) async {
      await tester.pumpWidget(
        harness(
          ProfileScreen(profile: profileWith(), relation: ViewerRelation.self),
        ),
      );

      expect(
        find.byKey(const ValueKey('profileSelfMenuButton')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('profileSelfMenuButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Availability'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('availabilityOption_available')),
        findsOneWidget,
      );
    },
  );
}
