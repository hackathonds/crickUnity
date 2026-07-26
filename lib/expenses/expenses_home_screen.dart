import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_expense_card.dart';
import '../design_system/icons/app_icon_id.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_money_text.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../matches/matches_provider.dart';
import 'add_edit_expense_screen.dart';
import 'expense_models.dart';
import 'expenses_provider.dart';

enum _ExpensesTab { iOwe, owed, all }

/// DS §7-48 (Expenses Home): "Net header Display ('You're owed ₹450')
/// -> tabs I-owe/Owed/All -> rows §3.2.6 -> {Add} FAB-less: sticky
/// [Add expense]. All-square state: calm tick illustration." The net
/// header here is a flat viewer-level total across every expense --
/// the "3 payments instead of 7" per-counterparty netting graph is
/// E5-04's separate scope.
class ExpensesHomeScreen extends ConsumerStatefulWidget {
  final String viewerName;
  final bool viewerIsCaptain;

  const ExpensesHomeScreen({
    super.key,
    required this.viewerName,
    required this.viewerIsCaptain,
  });

  @override
  ConsumerState<ExpensesHomeScreen> createState() => _ExpensesHomeScreenState();
}

class _ExpensesHomeScreenState extends ConsumerState<ExpensesHomeScreen> {
  _ExpensesTab _tab = _ExpensesTab.all;

  String _contextCaption(Expense expense) {
    if (expense.contextMatchId == null) {
      return expenseCategoryLabels[expense.category]!;
    }
    final matches = ref
        .read(matchesProvider)
        .matches
        .where((m) => m.id == expense.contextMatchId);
    if (matches.isEmpty) return expenseCategoryLabels[expense.category]!;
    return 'vs ${matches.first.draft.opponentTeamName}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final expenses = ref.watch(expensesProvider).expenses;
    final notifier = ref.read(expensesProvider.notifier);

    final net = expenses.fold(0, (sum, e) => sum + e.netFor(widget.viewerName));

    final filtered = [
      for (final e in expenses)
        if (_tab == _ExpensesTab.all ||
            (_tab == _ExpensesTab.iOwe && e.netFor(widget.viewerName) < 0) ||
            (_tab == _ExpensesTab.owed && e.netFor(widget.viewerName) > 0))
          e,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: net == 0
                ? Column(
                    key: const ValueKey('allSquareState'),
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: colors.success,
                        size: 40,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'All square',
                        style: AppTypography.h2.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  )
                : Text.rich(
                    key: const ValueKey('netHeader'),
                    TextSpan(
                      style: AppTypography.display.copyWith(
                        color: net > 0 ? colors.success : colors.textPrimary,
                      ),
                      children: [
                        TextSpan(text: net > 0 ? "You're owed " : 'You owe '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: AppMoneyText(
                            symbol: '₹',
                            amount: '${net.abs()}',
                            numeralStyle: AppTypography.display.copyWith(
                              color: net > 0
                                  ? colors.success
                                  : colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                for (final tab in _ExpensesTab.values)
                  Expanded(
                    child: GestureDetector(
                      key: ValueKey('expensesTab_${tab.name}'),
                      onTap: () => setState(() => _tab = tab),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _tab == tab
                                  ? colors.primary
                                  : colors.border,
                              width: _tab == tab ? 2 : 1,
                            ),
                          ),
                        ),
                        child: Text(
                          switch (tab) {
                            _ExpensesTab.iOwe => 'I owe',
                            _ExpensesTab.owed => 'Owed',
                            _ExpensesTab.all => 'All',
                          },
                          textAlign: TextAlign.center,
                          style: AppTypography.body.copyWith(
                            color: _tab == tab
                                ? colors.primary
                                : colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      key: const ValueKey('expensesEmptyState'),
                      'No expenses here yet.',
                      style: AppTypography.body.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  )
                : ListView(
                    key: const ValueKey('expensesList'),
                    children: [
                      for (final expense in filtered)
                        Column(
                          key: ValueKey('expenseRow_${expense.id}'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppExpenseRow(
                              title: expense.title,
                              contextCaption: _contextCaption(expense),
                              amount: expense.amount,
                              state:
                                  expense.settlementStates[widget.viewerName] ??
                                  AppExpenseRowState.pending,
                              categoryIcon: AppIconId.receipt,
                            ),
                            if (expense.approvalState ==
                                ExpenseApprovalState.pendingApproval)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Awaiting approval',
                                        style: AppTypography.caption.copyWith(
                                          color: colors.warning,
                                        ),
                                      ),
                                    ),
                                    if (widget.viewerIsCaptain)
                                      AppButton(
                                        key: ValueKey(
                                          'approveExpenseButton_${expense.id}',
                                        ),
                                        variant: AppButtonVariant.secondary,
                                        label: 'Approve',
                                        onPressed: () =>
                                            notifier.approveExpense(expense.id),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppButton(
              key: const ValueKey('addExpenseButton'),
              variant: AppButtonVariant.primary,
              label: 'Add expense',
              fullWidth: true,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddEditExpenseScreen(
                    viewerName: widget.viewerName,
                    viewerIsCaptain: widget.viewerIsCaptain,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
