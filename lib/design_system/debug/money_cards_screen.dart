import 'package:flutter/material.dart';

import '../components/app_expense_card.dart';
import '../icons/app_icon_id.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// QA tool for E0-08 (sub-task 2/12): [AppExpenseCard], [AppExpenseRow].
class MoneyCardsScreen extends StatelessWidget {
  const MoneyCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm,
        top: AppSpacing.xxl,
      ),
      child: Text(
        text,
        style: AppTypography.label.copyWith(color: colors.textTertiary),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Money cards (QA)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label('Expense Card — owed to me'),
            AppExpenseCard(
              isOwedToMe: true,
              amount: 450,
              counterpartyName: 'Rahul',
              pendingCount: 2,
              onSettleUp: () {},
              onRemind: () {},
            ),
            label('Expense Card — you owe, overdue >7d'),
            AppExpenseCard(
              isOwedToMe: false,
              amount: 1300,
              counterpartyName: 'Titans FC',
              pendingCount: 1,
              overdueDays: 9,
              onSettleUp: () {},
              onRemind: () {},
            ),
            label('Expense Row — all 4 states'),
            const AppExpenseRow(
              title: 'Ground fee',
              contextCaption: 'vs Titans · Sun',
              amount: 200,
              state: AppExpenseRowState.pending,
              categoryIcon: AppIconId.receipt,
            ),
            const Divider(height: 1),
            const AppExpenseRow(
              title: 'Umpire fee',
              contextCaption: 'vs Strikers · Sat',
              amount: 500,
              state: AppExpenseRowState.partial,
              categoryIcon: AppIconId.split,
            ),
            const Divider(height: 1),
            const AppExpenseRow(
              title: 'Jersey order',
              contextCaption: 'Team kit · Aug',
              amount: 3200,
              state: AppExpenseRowState.settled,
              categoryIcon: AppIconId.wallet,
            ),
            const Divider(height: 1),
            AppExpenseRow(
              title: 'Ball & kit',
              contextCaption: 'vs Riverside · Fri',
              amount: 850,
              state: AppExpenseRowState.disputed,
              categoryIcon: AppIconId.receipt,
              onPaySettle: () {},
              onRemindDispute: () {},
            ),
          ],
        ),
      ),
    );
  }
}
