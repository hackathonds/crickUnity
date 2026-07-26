import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/teams/permission_matrix_screen.dart';
import 'package:cricunity/teams/team_member_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness({required TeamMemberRole viewerRole}) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: PermissionMatrixScreen(viewerRole: viewerRole),
  );

  testWidgets('renders every action row and role column', (tester) async {
    await tester.pumpWidget(harness(viewerRole: TeamMemberRole.player));

    for (final row in permissionMatrixRows) {
      expect(
        find.byKey(ValueKey('permissionRow_${row.action}')),
        findsOneWidget,
      );
    }
    for (final role in TeamMemberRole.values) {
      expect(find.text(teamMemberRoleLabels[role]!), findsOneWidget);
    }
  });

  testWidgets(
    'AC: a non-Owner sees the configurable cells as read-only checkmarks, '
    'not switches',
    (tester) async {
      await tester.pumpWidget(harness(viewerRole: TeamMemberRole.captain));

      for (final cell in configurablePermissionCells) {
        expect(
          find.byKey(ValueKey('configurableCellSwitch_${cell.label}')),
          findsNothing,
        );
      }
    },
  );

  testWidgets('the Owner sees the configurable cells as toggleable switches', (
    tester,
  ) async {
    await tester.pumpWidget(harness(viewerRole: TeamMemberRole.owner));

    for (final cell in configurablePermissionCells) {
      expect(
        find.byKey(ValueKey('configurableCellSwitch_${cell.label}')),
        findsOneWidget,
      );
    }
  });

  testWidgets('the Owner can toggle a configurable cell', (tester) async {
    await tester.pumpWidget(harness(viewerRole: TeamMemberRole.owner));
    final cellLabel = configurablePermissionCells.first.label;
    final switchKey = ValueKey('configurableCellSwitch_$cellLabel');

    final before = tester.widget<Switch>(find.byKey(switchKey)).value;
    await tester.tap(find.byKey(switchKey));
    await tester.pump();
    final after = tester.widget<Switch>(find.byKey(switchKey)).value;

    expect(after, isNot(before));
  });
}
