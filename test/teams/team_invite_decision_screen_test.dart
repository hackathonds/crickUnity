import 'package:cricunity/design_system/components/app_button.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/teams/team_invite_decision_screen.dart';
import 'package:cricunity/teams/team_invite_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixedNow = DateTime(2026, 3, 1);

  Widget harness({required TeamInviteOffer offer, int joinedTeamCount = 0}) =>
      MaterialApp(
        theme: AppTheme.themes[AppTheme.defaultLight],
        home: TeamInviteDecisionScreen(
          offer: offer,
          joinedTeamCount: joinedTeamCount,
          now: () => fixedNow,
        ),
      );

  testWidgets('shows team name and role offered', (tester) async {
    await tester.pumpWidget(
      harness(
        offer: TeamInviteOffer(
          teamName: 'Lions CC',
          roleOffered: 'WK needed',
          expiresAt: fixedNow.add(const Duration(days: 5)),
        ),
      ),
    );

    expect(find.text('Lions CC'), findsOneWidget);
    expect(find.text('Join as: WK needed'), findsOneWidget);
  });

  testWidgets('AC: an invite expiring under 24h is flagged', (tester) async {
    await tester.pumpWidget(
      harness(
        offer: TeamInviteOffer(
          teamName: 'Lions CC',
          roleOffered: 'Player',
          expiresAt: fixedNow.add(const Duration(hours: 5)),
        ),
      ),
    );

    expect(find.text('Expires soon'), findsOneWidget);
  });

  testWidgets('an invite expiring in a few days shows the date, not flagged', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        offer: TeamInviteOffer(
          teamName: 'Lions CC',
          roleOffered: 'Player',
          expiresAt: fixedNow.add(const Duration(days: 5)),
        ),
      ),
    );

    expect(find.text('Expires soon'), findsNothing);
    expect(find.textContaining('Expires 6/3/2026'), findsOneWidget);
  });

  testWidgets('AC: at the 10-team cap, Accept is disabled with a clear error', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        offer: TeamInviteOffer(
          teamName: 'Lions CC',
          roleOffered: 'Player',
          expiresAt: fixedNow.add(const Duration(days: 5)),
        ),
        joinedTeamCount: maxJoinedTeams,
      ),
    );

    expect(
      find.byKey(const ValueKey('teamInviteCapReachedBanner')),
      findsOneWidget,
    );
    final accept = tester.widget<AppButton>(
      find.byKey(const ValueKey('teamInviteAcceptButton')),
    );
    expect(accept.onPressed, isNull);
  });

  testWidgets('accepting under the cap shows the joined outcome', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        offer: TeamInviteOffer(
          teamName: 'Lions CC',
          roleOffered: 'Player',
          expiresAt: fixedNow.add(const Duration(days: 5)),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('teamInviteAcceptButton')));
    await tester.pump();

    expect(find.text('You joined Lions CC.'), findsOneWidget);
  });

  testWidgets('declining shows the declined outcome', (tester) async {
    await tester.pumpWidget(
      harness(
        offer: TeamInviteOffer(
          teamName: 'Lions CC',
          roleOffered: 'Player',
          expiresAt: fixedNow.add(const Duration(days: 5)),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('teamInviteDeclineButton')));
    await tester.pump();

    expect(find.text("You declined Lions CC's invite."), findsOneWidget);
  });
}
