import 'package:cricunity/design_system/components/app_button.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/teams/recruitment_board_screen.dart';
import 'package:cricunity/teams/team_member_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness({
    required String viewerName,
    required TeamMemberRole viewerRole,
    DateTime Function() now = DateTime.now,
  }) => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: RecruitmentBoardScreen(
        viewerName: viewerName,
        viewerRole: viewerRole,
        now: now,
      ),
    ),
  );

  void setTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('AC: a manager sees the Pipeline tab and Post-listing action, '
      'structurally', (tester) async {
    setTallViewport(tester);
    await tester.pumpWidget(
      harness(viewerName: 'Rohan Kapoor', viewerRole: TeamMemberRole.captain),
    );

    expect(find.byKey(const ValueKey('recruitmentTabControl')), findsOneWidget);
    expect(find.byKey(const ValueKey('postListingFab')), findsOneWidget);
  });

  testWidgets('AC: a plain player never sees the Pipeline tab or Post-listing '
      'action, not just disabled', (tester) async {
    setTallViewport(tester);
    await tester.pumpWidget(
      harness(viewerName: 'Neha Rao', viewerRole: TeamMemberRole.player),
    );

    expect(find.byKey(const ValueKey('recruitmentTabControl')), findsNothing);
    expect(find.byKey(const ValueKey('postListingFab')), findsNothing);
  });

  testWidgets('a free agent can apply to an open listing', (tester) async {
    setTallViewport(tester);
    await tester.pumpWidget(
      harness(viewerName: 'Neha Rao', viewerRole: TeamMemberRole.player),
    );

    await tester.tap(find.byKey(const ValueKey('applyButton_listing-1')));
    await tester.pump();

    final button = tester.widget<Text>(find.text('Applied'));
    expect(button.data, 'Applied');
  });

  testWidgets(
    'AC: an expired listing shows the Expired badge and disables Apply',
    (tester) async {
      setTallViewport(tester);
      final farFuture = DateTime.now().add(const Duration(days: 40));
      await tester.pumpWidget(
        harness(
          viewerName: 'Neha Rao',
          viewerRole: TeamMemberRole.player,
          now: () => farFuture,
        ),
      );

      expect(find.byKey(const ValueKey('expiredBadge')), findsOneWidget);
      final button = tester.widget<AppButton>(
        find.byKey(const ValueKey('applyButton_listing-1')),
      );
      expect(button.onPressed, isNull);
    },
  );

  testWidgets(
    'AC: dragging an applicant card to another column prompts a confirm '
    'dialog, and confirming moves the stage',
    (tester) async {
      setTallViewport(tester);
      await tester.pumpWidget(
        harness(viewerName: 'Rohan Kapoor', viewerRole: TeamMemberRole.captain),
      );

      await tester.tap(find.text('Pipeline'));
      await tester.pumpAndSettle();

      final card = find.byKey(const ValueKey('applicantCard_applicant-1'));
      final targetColumn = find.byKey(
        const ValueKey('pipelineColumn_trialInvited'),
      );
      await tester.drag(
        card,
        tester.getCenter(targetColumn) - tester.getCenter(card),
      );
      await tester.pumpAndSettle();

      expect(find.text('Move Karan Bhatt?'), findsOneWidget);
      await tester.tap(find.text('Move'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: targetColumn,
          matching: find.byKey(const ValueKey('applicantCard_applicant-1')),
        ),
        findsOneWidget,
      );
    },
  );
}
