import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/teams/team_home_screen.dart';
import 'package:cricunity/teams/team_models.dart';
import 'package:cricunity/teams/team_viewer_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness({required TeamViewerRole role, bool isArchived = false}) {
    final base = mockTeam();
    return MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: TeamHomeScreen(
        team: Team(
          name: base.name,
          city: base.city,
          homeGround: base.homeGround,
          formatFocus: base.formatFocus,
          joinPolicy: base.joinPolicy,
          primaryColor: base.primaryColor,
          secondaryColor: base.secondaryColor,
          followerCount: base.followerCount,
          memberCount: base.memberCount,
          isArchived: isArchived,
        ),
        viewerRole: role,
      ),
    );
  }

  testWidgets('AC: Money and Manage tabs are structurally absent for a plain '
      'follower/player, not just disabled', (tester) async {
    for (final role in [
      TeamViewerRole.public,
      TeamViewerRole.follower,
      TeamViewerRole.player,
    ]) {
      await tester.pumpWidget(harness(role: role));

      expect(
        find.byKey(const ValueKey('teamTab_Money')),
        findsNothing,
        reason: 'Money tab leaked for role $role',
      );
      expect(
        find.byKey(const ValueKey('teamTab_Manage')),
        findsNothing,
        reason: 'Manage tab leaked for role $role',
      );
      for (final label in ['Feed', 'Matches', 'Members', 'Stats', 'Media']) {
        expect(
          find.byKey(ValueKey('teamTab_$label')),
          findsOneWidget,
          reason: 'base tab $label missing for role $role',
        );
      }
    }
  });

  testWidgets('Manager sees Money but not Manage', (tester) async {
    await tester.pumpWidget(harness(role: TeamViewerRole.manager));

    expect(find.byKey(const ValueKey('teamTab_Money')), findsOneWidget);
    expect(find.byKey(const ValueKey('teamTab_Manage')), findsNothing);
  });

  testWidgets('Vice-Captain, Captain, and Owner see both Money and Manage', (
    tester,
  ) async {
    for (final role in [
      TeamViewerRole.viceCaptain,
      TeamViewerRole.captain,
      TeamViewerRole.owner,
    ]) {
      await tester.pumpWidget(harness(role: role));

      expect(
        find.byKey(const ValueKey('teamTab_Money')),
        findsOneWidget,
        reason: 'Money tab missing for role $role',
      );
      expect(
        find.byKey(const ValueKey('teamTab_Manage')),
        findsOneWidget,
        reason: 'Manage tab missing for role $role',
      );
    }
  });

  testWidgets('AC: the archived banner only shows for archived teams', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(role: TeamViewerRole.owner, isArchived: false),
    );
    expect(find.byKey(const ValueKey('teamArchivedBanner')), findsNothing);

    await tester.pumpWidget(
      harness(role: TeamViewerRole.owner, isArchived: true),
    );
    expect(find.byKey(const ValueKey('teamArchivedBanner')), findsOneWidget);
    expect(find.textContaining('read-only'), findsOneWidget);
  });

  testWidgets('tapping a tab switches the placeholder content', (tester) async {
    await tester.pumpWidget(harness(role: TeamViewerRole.owner));

    expect(find.textContaining('E3-05'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('teamTab_Members')));
    await tester.pumpAndSettle();

    expect(find.textContaining('E3-04'), findsOneWidget);
    expect(find.textContaining('E3-05'), findsNothing);
  });

  testWidgets('shows follower and member counts', (tester) async {
    await tester.pumpWidget(harness(role: TeamViewerRole.owner));

    expect(find.textContaining('members'), findsOneWidget);
    expect(find.textContaining('followers'), findsOneWidget);
  });
}
