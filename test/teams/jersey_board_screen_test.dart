import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/teams/jersey_board_provider.dart';
import 'package:cricunity/teams/jersey_board_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness({required String viewerName, bool isManager = false}) =>
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.themes[AppTheme.defaultLight],
          home: JerseyBoardScreen(viewerName: viewerName, isManager: isManager),
        ),
      );

  testWidgets(
    'AC: a plain member sees only their own submission section, not the '
    'full sheet',
    (tester) async {
      await tester.pumpWidget(harness(viewerName: 'Priya Nair'));

      expect(
        find.byKey(const ValueKey('memberOwnSubmissionSection')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('managerSheetSection')), findsNothing);
      // Someone else's submission never renders on the member's own view.
      expect(find.textContaining('Arjun Rao'), findsNothing);
    },
  );

  testWidgets('the Manager sees the full sheet with every submission', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(viewerName: 'Kabir Singh', isManager: true),
    );

    expect(find.byKey(const ValueKey('managerSheetSection')), findsOneWidget);
    expect(find.textContaining('Arjun Rao'), findsWidgets);
    expect(find.textContaining('Priya Nair'), findsOneWidget);
  });

  testWidgets('AC: the Manager sees a number-conflict banner with a '
      'resolve action', (tester) async {
    await tester.pumpWidget(
      harness(viewerName: 'Kabir Singh', isManager: true),
    );

    expect(find.byKey(const ValueKey('numberConflict_7')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('resolveConflict_7')));
    await tester.pump();

    expect(find.byKey(const ValueKey('numberConflict_7')), findsNothing);
  });

  testWidgets('the Manager can advance the order status', (tester) async {
    await tester.pumpWidget(
      harness(viewerName: 'Kabir Singh', isManager: true),
    );

    expect(find.text('Collecting sizes'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('advanceOrderStatusButton')));
    await tester.pump();

    expect(find.text('Ordered'), findsOneWidget);
  });

  testWidgets('a member can submit their size and it reaches the provider', (
    tester,
  ) async {
    await tester.pumpWidget(harness(viewerName: 'Farhan Ali'));

    await tester.enterText(find.byKey(const ValueKey('jerseySizeField')), 'L');
    await tester.enterText(
      find.byKey(const ValueKey('jerseyNameField')),
      'ALI',
    );
    await tester.enterText(
      find.byKey(const ValueKey('jerseyNumberField')),
      '9',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('jerseySubmitButton')));
    await tester.pump();

    final context = tester.element(find.byType(JerseyBoardScreen));
    final container = ProviderScope.containerOf(context);
    final submission = container
        .read(jerseyBoardProvider)
        .submissions
        .firstWhere((s) => s.memberName == 'Farhan Ali');
    expect(submission.size, 'L');
    expect(submission.number, 9);
  });
}
