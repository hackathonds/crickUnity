import 'package:cricunity/design_system/components/app_button.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/teams/selection_board_models.dart';
import 'package:cricunity/teams/selection_board_provider.dart';
import 'package:cricunity/teams/selection_board_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness() => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.themes[AppTheme.defaultLight],
      home: const SelectionBoardScreen(),
    ),
  );

  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('renders every pool player and all 12 XI slots', (tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(harness());

    expect(find.text('Rohan Verma'), findsOneWidget);
    for (var i = 0; i < xiSlotCount - 1; i++) {
      expect(find.byKey(ValueKey('xiSlot_$i')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('xiSlot_11')), findsOneWidget);
  });

  testWidgets(
    'AC: the role-balance meter warns when no wicketkeeper is selected, '
    'and clears once one is',
    (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(harness());

      expect(find.text('No wicketkeeper selected'), findsOneWidget);

      final context = tester.element(find.byType(SelectionBoardScreen));
      final container = ProviderScope.containerOf(context);
      final wk = container
          .read(selectionBoardProvider)
          .pool
          .firstWhere((p) => p.name == 'Meera Joshi');
      container.read(selectionBoardProvider.notifier).selectToSlot(wk, 0);
      await tester.pump();

      expect(find.text('Wicketkeeper selected'), findsOneWidget);
    },
  );

  testWidgets('AC: Publish is disabled until all 12 slots are filled', (
    tester,
  ) async {
    useTallViewport(tester);
    await tester.pumpWidget(harness());

    final button = tester.widget<AppButton>(
      find.byKey(const ValueKey('publishLineupButton')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('dragging a pool player onto a slot fills it', (tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(harness());

    final card = find.byKey(const ValueKey('poolCard_Rohan Verma'));
    final slot = find.byKey(const ValueKey('xiSlot_0'));
    await tester.drag(card, tester.getCenter(slot) - tester.getCenter(card));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: slot, matching: find.text('Rohan Verma')),
      findsOneWidget,
    );
  });

  testWidgets('tapping a filled slot removes the player back to the pool', (
    tester,
  ) async {
    useTallViewport(tester);
    await tester.pumpWidget(harness());
    final context = tester.element(find.byType(SelectionBoardScreen));
    final container = ProviderScope.containerOf(context);
    final player = container.read(selectionBoardProvider).pool.first;
    container.read(selectionBoardProvider.notifier).selectToSlot(player, 0);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('xiSlot_0')));
    await tester.pump();

    expect(find.byKey(ValueKey('poolCard_${player.name}')), findsOneWidget);
  });

  testWidgets(
    'AC: after locking, direct slot taps stop working and the replacement '
    'banner appears instead',
    (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(harness());
      final context = tester.element(find.byType(SelectionBoardScreen));
      final container = ProviderScope.containerOf(context);
      final notifier = container.read(selectionBoardProvider.notifier);
      final pool = List.of(container.read(selectionBoardProvider).pool);
      for (var i = 0; i < xiSlotCount; i++) {
        notifier.selectToSlot(pool[i], i);
      }
      notifier.publishLineup();
      notifier.lockAtToss();
      await tester.pump();

      expect(
        find.byKey(const ValueKey('replacementFlowBanner')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('publishLineupButton')), findsNothing);
    },
  );
}
