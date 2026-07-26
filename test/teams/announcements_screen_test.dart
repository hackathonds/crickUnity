import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/teams/announcements_screen.dart';
import 'package:cricunity/teams/team_member_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness({
    required TeamMemberRole actingRole,
    required String actorName,
  }) => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: AnnouncementsScreen(
        actingRole: actingRole,
        actorName: actorName,
        totalMembers: 18,
      ),
    ),
  );

  testWidgets(
    'AC: the seen-by count is only visible to the announcement\'s author',
    (tester) async {
      await tester.pumpWidget(
        harness(actingRole: TeamMemberRole.player, actorName: 'Ananya Iyer'),
      );

      expect(find.byKey(const ValueKey('announcementSeenBy')), findsNothing);
    },
  );

  testWidgets('the author sees their own "Seen X/Y" line', (tester) async {
    await tester.pumpWidget(
      harness(actingRole: TeamMemberRole.captain, actorName: 'Arjun Rao'),
    );

    expect(find.byKey(const ValueKey('announcementSeenBy')), findsOneWidget);
    expect(find.textContaining('Seen 2/18'), findsOneWidget);
  });

  testWidgets(
    'AC: the New-announcement action is hidden (not disabled) for a plain '
    'Player',
    (tester) async {
      await tester.pumpWidget(
        harness(actingRole: TeamMemberRole.player, actorName: 'Ananya Iyer'),
      );

      expect(find.byKey(const ValueKey('newAnnouncementButton')), findsNothing);
    },
  );

  testWidgets('the New-announcement action is shown for a Captain', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(actingRole: TeamMemberRole.captain, actorName: 'Arjun Rao'),
    );

    expect(find.byKey(const ValueKey('newAnnouncementButton')), findsOneWidget);
  });

  testWidgets(
    'push-priority announcements are pinned above more recent normal ones',
    (tester) async {
      await tester.pumpWidget(
        harness(actingRole: TeamMemberRole.captain, actorName: 'Arjun Rao'),
      );

      // Post a brand-new normal announcement -- it's now the most recent
      // by timestamp, but the older push-priority ann-1 should still
      // render above it.
      await tester.tap(find.byKey(const ValueKey('newAnnouncementButton')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('announcementBodyField')),
        'Brand new normal update',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('announcementPostButton')));
      await tester.pumpAndSettle();

      final pushPriorityTop = tester
          .getTopLeft(find.byKey(const ValueKey('announcementCard_ann-1')))
          .dy;
      final newNormalTop = tester
          .getTopLeft(find.widgetWithText(Container, 'Brand new normal update'))
          .dy;
      expect(pushPriorityTop, lessThan(newNormalTop));
    },
  );

  testWidgets('the author can toggle comments on an announcement', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(actingRole: TeamMemberRole.captain, actorName: 'Arjun Rao'),
    );

    expect(find.text('Comments on'), findsWidgets);
    await tester.tap(
      find.byKey(const ValueKey('announcementToggleComments_ann-1')),
    );
    await tester.pump();

    expect(find.text('Comments off'), findsOneWidget);
  });

  testWidgets('composing and posting a new announcement adds a card', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(actingRole: TeamMemberRole.captain, actorName: 'Arjun Rao'),
    );

    await tester.tap(find.byKey(const ValueKey('newAnnouncementButton')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('announcementBodyField')),
      'New match scheduled for Sunday',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('announcementPostButton')));
    await tester.pumpAndSettle();

    expect(find.text('New match scheduled for Sunday'), findsOneWidget);
  });

  testWidgets(
    'AC: attempting a 2nd push-priority post within 6h shows a clear error',
    (tester) async {
      await tester.pumpWidget(
        harness(actingRole: TeamMemberRole.captain, actorName: 'Arjun Rao'),
      );

      // Mock ann-1 is already push-priority and only ~2h old.
      await tester.tap(find.byKey(const ValueKey('newAnnouncementButton')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('announcementBodyField')),
        'Another urgent update',
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('announcementPushPrioritySwitch')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('announcementPostButton')));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('announcementComposerError')),
        findsOneWidget,
      );
      // The sheet stays open on denial rather than posting/closing.
      expect(
        find.byKey(const ValueKey('announcementBodyField')),
        findsOneWidget,
      );
    },
  );
}
