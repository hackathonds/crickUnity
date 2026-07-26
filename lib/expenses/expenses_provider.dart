import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_expense_card.dart';
import 'expense_models.dart';

class ExpensesState {
  final List<Expense> expenses;

  const ExpensesState({this.expenses = const []});

  ExpensesState copyWith({List<Expense>? expenses}) {
    return ExpensesState(expenses: expenses ?? this.expenses);
  }
}

/// PRD §11.1-11.3/11.7 -- E5-01's expense object + Add/Edit. No
/// backend/persistence exists yet; this is the in-memory ledger every
/// screen in this module reads from.
class ExpensesNotifier extends Notifier<ExpensesState> {
  int _nextId = 0;

  @override
  ExpensesState build() => const ExpensesState();

  /// PRD §11.7: "Approval: team threshold (default ₹1,000) -> Captain
  /// approve before shares go live; self-created captain expenses above
  /// threshold -> VC/Owner approves (no self-approval)."
  String addExpense({
    required String title,
    required ExpenseCategory category,
    required int amount,
    required List<PaidByEntry> paidBy,
    required SplitMethod splitMethod,
    required List<SplitShare> splitAmong,
    String? contextMatchId,
    bool hasProof = false,
    String? notes,
    required String createdByName,
    required bool createdByIsCaptain,
    bool isIncome = false,
    DateTime Function() now = DateTime.now,
  }) {
    final id = 'expense-${now().millisecondsSinceEpoch}-${_nextId++}';
    final needsApproval = amount > expenseApprovalThresholdRupees;
    state = state.copyWith(
      expenses: [
        Expense(
          id: id,
          title: title,
          category: category,
          amount: amount,
          paidBy: paidBy,
          splitMethod: splitMethod,
          splitAmong: splitAmong,
          contextMatchId: contextMatchId,
          date: now(),
          hasProof: hasProof,
          notes: notes,
          approvalState: needsApproval
              ? ExpenseApprovalState.pendingApproval
              : ExpenseApprovalState.none,
          createdByName: createdByName,
          settlementStates: {
            for (final share in splitAmong)
              share.name: AppExpenseRowState.pending,
          },
          isIncome: isIncome,
        ),
        ...state.expenses,
      ],
    );
    return id;
  }

  void approveExpense(String expenseId) {
    state = state.copyWith(
      expenses: [
        for (final e in state.expenses)
          if (e.id == expenseId)
            e.copyWith(approvalState: ExpenseApprovalState.approved)
          else
            e,
      ],
    );
  }
}

final expensesProvider = NotifierProvider<ExpensesNotifier, ExpensesState>(
  ExpensesNotifier.new,
);
