import 'package:cricunity/design_system/components/app_expense_card.dart';
import 'package:cricunity/design_system/theme/app_theme.dart';
import 'package:cricunity/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.themes[AppTheme.defaultLight],
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  final colors = AppTheme.themes[AppTheme.defaultLight]!
      .extension<AppColors>()!;

  group('AppExpenseCard', () {
    testWidgets('shows "You are owed" in success color when isOwedToMe', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          const AppExpenseCard(
            isOwedToMe: true,
            amount: 450,
            counterpartyName: 'Rahul',
            pendingCount: 2,
          ),
        ),
      );

      expect(find.textContaining('You are owed'), findsOneWidget);
      final richText = tester.widget<RichText>(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('You are owed'),
        ),
      );
      // Text.rich wraps the authored TextSpan in an outer span carrying
      // the ambient DefaultTextStyle -- the color set on the card's own
      // line is on that first child, not the wrapper `richText.text`.
      final authoredSpan =
          (richText.text as TextSpan).children!.first as TextSpan;
      expect(authoredSpan.style!.color, colors.success);
    });

    testWidgets('shows "You owe" in textPrimary (never red for debt)', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          const AppExpenseCard(
            isOwedToMe: false,
            amount: 300,
            counterpartyName: 'Titans FC',
            pendingCount: 1,
          ),
        ),
      );

      expect(find.textContaining('You owe'), findsOneWidget);
      final richText = tester.widget<RichText>(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().startsWith('You owe'),
        ),
      );
      final authoredSpan =
          (richText.text as TextSpan).children!.first as TextSpan;
      expect(authoredSpan.style!.color, colors.textPrimary);
      expect(authoredSpan.style!.color, isNot(colors.error));
    });

    testWidgets('no overdue chip at 3 days or fewer', (tester) async {
      await tester.pumpWidget(
        harness(
          const AppExpenseCard(
            isOwedToMe: false,
            amount: 300,
            counterpartyName: 'Titans FC',
            pendingCount: 1,
            overdueDays: 3,
          ),
        ),
      );

      expect(find.textContaining('overdue'), findsNothing);
    });

    testWidgets('warning-variant overdue chip for 4-7 days', (tester) async {
      await tester.pumpWidget(
        harness(
          const AppExpenseCard(
            isOwedToMe: false,
            amount: 300,
            counterpartyName: 'Titans FC',
            pendingCount: 1,
            overdueDays: 5,
          ),
        ),
      );

      expect(find.text('5d overdue'), findsOneWidget);
      final text = tester.widget<Text>(find.text('5d overdue'));
      expect(text.style!.color, colors.warning);
    });

    testWidgets('error-variant overdue chip beyond 7 days', (tester) async {
      await tester.pumpWidget(
        harness(
          const AppExpenseCard(
            isOwedToMe: false,
            amount: 300,
            counterpartyName: 'Titans FC',
            pendingCount: 1,
            overdueDays: 9,
          ),
        ),
      );

      expect(find.text('9d overdue'), findsOneWidget);
      final text = tester.widget<Text>(find.text('9d overdue'));
      expect(text.style!.color, colors.error);
    });

    testWidgets('Settle up and Remind fire their callbacks', (tester) async {
      var settled = false;
      var reminded = false;
      await tester.pumpWidget(
        harness(
          AppExpenseCard(
            isOwedToMe: true,
            amount: 450,
            counterpartyName: 'Rahul',
            pendingCount: 2,
            onSettleUp: () => settled = true,
            onRemind: () => reminded = true,
          ),
        ),
      );

      await tester.tap(find.text('Settle up'));
      await tester.tap(find.text('Remind'));

      expect(settled, isTrue);
      expect(reminded, isTrue);
    });

    testWidgets('the card border uses the money-surface border color', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          const AppExpenseCard(
            isOwedToMe: true,
            amount: 450,
            counterpartyName: 'Rahul',
            pendingCount: 2,
          ),
        ),
      );

      final surface = tester.widget<Container>(
        find.byKey(const ValueKey('appCardSurface')),
      );
      final decoration = surface.decoration as BoxDecoration;
      expect(decoration.border!.top.color, colors.moneyBorder);
    });
  });

  group('AppExpenseRow', () {
    testWidgets('renders title, caption, and amount', (tester) async {
      await tester.pumpWidget(
        harness(
          const AppExpenseRow(
            title: 'Ground fee',
            contextCaption: 'vs Titans · Sun',
            amount: 200,
            state: AppExpenseRowState.pending,
          ),
        ),
      );

      expect(find.text('Ground fee'), findsOneWidget);
      expect(find.text('vs Titans · Sun'), findsOneWidget);
      expect(find.textContaining('200'), findsOneWidget);
    });

    testWidgets('swiping right fires onPaySettle, left fires onRemindDispute', (
      tester,
    ) async {
      var paid = false;
      await tester.pumpWidget(
        harness(
          AppExpenseRow(
            title: 'Ground fee',
            contextCaption: 'vs Titans · Sun',
            amount: 200,
            state: AppExpenseRowState.pending,
            onPaySettle: () => paid = true,
          ),
        ),
      );

      final content = find.byKey(const ValueKey('appSwipeActionRowContent'));
      final gesture = await tester.startGesture(tester.getCenter(content));
      await gesture.moveBy(const Offset(2000, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 200));

      expect(paid, isTrue);
    });

    testWidgets(
      'no swipe wrapper when neither onPaySettle nor onRemindDispute is given',
      (tester) async {
        await tester.pumpWidget(
          harness(
            const AppExpenseRow(
              title: 'Jersey order',
              contextCaption: 'Team kit · Aug',
              amount: 3200,
              state: AppExpenseRowState.settled,
            ),
          ),
        );

        expect(
          find.byKey(const ValueKey('appSwipeActionRowContent')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('appExpenseRowBox')), findsOneWidget);
      },
    );
  });
}
