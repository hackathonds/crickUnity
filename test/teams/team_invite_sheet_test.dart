import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/teams/team_invite_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness() => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () =>
                showTeamInviteSheet(context: context, teamName: 'Lions CC'),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );

  testWidgets('defaults to the Link tab, showing a Generate button first', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('teamInviteGenerateLinkButton')),
      findsOneWidget,
    );
  });

  testWidgets(
    'generating a link shows the URL, expiry, copy and revoke actions',
    (tester) async {
      await tester.pumpWidget(harness());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('teamInviteGenerateLinkButton')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('teamInviteLinkText')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('teamInviteCopyLinkButton')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('teamInviteRevokeButton')),
        findsOneWidget,
      );
    },
  );

  testWidgets('revoking a link reverts to the Generate button', (tester) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('teamInviteGenerateLinkButton')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('teamInviteRevokeButton')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('teamInviteGenerateLinkButton')),
      findsOneWidget,
    );
  });

  testWidgets('the QR tab shows a placeholder and an honest gap note', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('QR'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('teamInviteQrPlaceholder')),
      findsOneWidget,
    );
    expect(find.textContaining("isn't available yet"), findsOneWidget);
  });

  testWidgets(
    'the Search tab lets you invite a suggested player, then shows Invited',
    (tester) async {
      await tester.pumpWidget(harness());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      final button = find.byKey(
        const ValueKey('teamInviteSearchInvite_Priya Nair'),
      );
      expect(find.text('Invite'), findsWidgets);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: button, matching: find.text('Invited')),
        findsOneWidget,
      );
    },
  );
}
