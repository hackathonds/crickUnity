import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/teams/members_roles_screen.dart';
import 'package:cricunity/teams/team_member_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness({required TeamMemberRole actingRole}) => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: MembersRolesScreen(
        actingRole: actingRole,
        actorName: teamMemberRoleLabels[actingRole]!,
      ),
    ),
  );

  testWidgets('renders every roster member with a role chip', (tester) async {
    await tester.pumpWidget(harness(actingRole: TeamMemberRole.owner));

    expect(find.text('Arjun Rao'), findsOneWidget);
    expect(find.text('Captain'), findsOneWidget);
  });

  testWidgets('AC: attempting to remove the Captain as Vice-Captain shows the '
      'denial reason and does not remove the row', (tester) async {
    await tester.pumpWidget(harness(actingRole: TeamMemberRole.viceCaptain));

    await tester.tap(find.byKey(const ValueKey('memberRowMenu_Arjun Rao')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('removeAction_Arjun Rao')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('removeReasonField')),
      'Disagreement',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('confirmRemoveButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('removeMemberError')), findsOneWidget);
    expect(find.byKey(const ValueKey('memberRow_Arjun Rao')), findsOneWidget);
  });

  testWidgets(
    'removing with an empty reason shows an error and keeps the row',
    (tester) async {
      await tester.pumpWidget(harness(actingRole: TeamMemberRole.owner));

      await tester.tap(find.byKey(const ValueKey('memberRowMenu_Farhan Ali')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('removeAction_Farhan Ali')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('confirmRemoveButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('removeMemberError')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('memberRow_Farhan Ali')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'removing with a reason as Owner succeeds and the row disappears',
    (tester) async {
      await tester.pumpWidget(harness(actingRole: TeamMemberRole.owner));

      await tester.tap(find.byKey(const ValueKey('memberRowMenu_Farhan Ali')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('removeAction_Farhan Ali')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('removeReasonField')),
        'Inactive',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('confirmRemoveButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('memberRow_Farhan Ali')), findsNothing);
    },
  );

  testWidgets(
    'AC: the change-role sheet never offers Vice-Captain as an option '
    'when acting as Vice-Captain',
    (tester) async {
      await tester.pumpWidget(harness(actingRole: TeamMemberRole.viceCaptain));

      await tester.tap(find.byKey(const ValueKey('memberRowMenu_Farhan Ali')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('changeRoleAction_Farhan Ali')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('roleOption_viceCaptain')),
        findsNothing,
      );
    },
  );

  testWidgets('changing a role as Owner succeeds and updates the chip', (
    tester,
  ) async {
    await tester.pumpWidget(harness(actingRole: TeamMemberRole.owner));

    await tester.tap(find.byKey(const ValueKey('memberRowMenu_Farhan Ali')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('changeRoleAction_Farhan Ali')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('roleOption_manager')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('memberRow_Farhan Ali')),
        matching: find.text('Manager'),
      ),
      findsOneWidget,
    );
  });
}
