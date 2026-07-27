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
    String? recurrenceSeriesId,
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
          recurrenceSeriesId: recurrenceSeriesId,
        ),
        ...state.expenses,
      ],
    );
    return id;
  }

  /// DS §11.13 Recently Deleted: "30-day list, rows show deleted-by +
  /// countdown, [Restore] per row." Soft-delete only -- rows still
  /// exist, just excluded from the normal ledger views.
  void deleteExpense(
    String expenseId,
    String deletedByName, {
    DateTime Function() now = DateTime.now,
  }) {
    _updateExpense(
      expenseId,
      (e) => e.copyWith(deletedAt: now(), deletedByName: deletedByName),
    );
  }

  /// "restore re-notifies participants." No real notification channel
  /// exists (Epic 15, unbuilt) -- this is a no-op beyond restoring, same
  /// flagged-mock convention as every other missing-notification-
  /// channel gap this session (e.g. E5-05's reminders).
  void restoreExpense(String expenseId) {
    _updateExpense(expenseId, (e) => e.copyWith(clearDeleted: true));
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

  /// PRD §11.7: "any participant disputes a line (reason mandatory) ->
  /// expense freezes for that person." A no-op if this disputer already
  /// has an active (unresolved) dispute on this expense.
  void disputeExpense(
    String expenseId,
    String disputerName,
    String reason, {
    DateTime Function() now = DateTime.now,
  }) {
    _updateExpense(expenseId, (e) {
      if (e.disputes.any(
        (d) => d.disputerName == disputerName && !d.resolved,
      )) {
        return e;
      }
      return e.copyWith(
        disputes: [
          ...e.disputes,
          ExpenseDispute(
            disputerName: disputerName,
            reason: reason,
            createdAt: now(),
          ),
        ],
      );
    });
  }

  /// PRD §11.7: "resolution: creator amends." Rescales the split
  /// proportionally to [newAmount] (see [rescaleSplit]) and resolves
  /// every currently-active dispute at once, since an amendment is a
  /// factual correction that applies to everyone, not just whoever
  /// happened to raise it first.
  void amendExpense(String expenseId, int newAmount) {
    _updateExpense(
      expenseId,
      (e) => e.copyWith(
        amount: newAmount,
        splitAmong: rescaleSplit(e.splitAmong, newAmount),
        disputes: [
          for (final d in e.disputes)
            if (!d.resolved)
              d.copyWith(resolved: true, resolution: 'amended')
            else
              d,
        ],
      ),
    );
  }

  /// PRD §11.7: "resolution: ... creator+captain uphold." Both must
  /// sign off (same dual-actor convention used throughout this
  /// session, e.g. E4-09's handover approval) before the dispute
  /// resolves; only then does it ding the creator's Trust -- no Trust
  /// system exists yet (flagged), so that's logged, not enacted.
  void upholdDispute(
    String expenseId,
    String disputerName, {
    required bool asCreator,
  }) {
    _updateExpense(expenseId, (e) {
      return e.copyWith(
        disputes: [
          for (final d in e.disputes)
            if (d.disputerName == disputerName && !d.resolved)
              _applyUphold(d, asCreator: asCreator)
            else
              d,
        ],
      );
    });
  }

  ExpenseDispute _applyUphold(ExpenseDispute d, {required bool asCreator}) {
    final creatorUpheld = asCreator || d.creatorUpheld;
    final captainUpheld = !asCreator || d.captainUpheld;
    if (creatorUpheld && captainUpheld) {
      return d.copyWith(
        resolved: true,
        resolution: 'upheld',
        creatorUpheld: true,
        captainUpheld: true,
      );
    }
    return d.copyWith(
      creatorUpheld: creatorUpheld,
      captainUpheld: captainUpheld,
    );
  }

  /// PRD §11.7: "disputer may escalate to Admin after 7d." No real
  /// Admin/Moderation queue exists yet (Epic 16, unbuilt) -- flagged;
  /// this only records the escalation flag.
  void escalateDispute(
    String expenseId,
    String disputerName, {
    DateTime Function() now = DateTime.now,
  }) {
    _updateExpense(expenseId, (e) {
      final dispute = e.disputes.where(
        (d) => d.disputerName == disputerName && !d.resolved,
      );
      if (dispute.isEmpty) return e;
      if (now().difference(dispute.first.createdAt).inDays < 7) return e;
      return e.copyWith(
        disputes: [
          for (final d in e.disputes)
            if (d.disputerName == disputerName && !d.resolved)
              d.copyWith(escalatedToAdmin: true)
            else
              d,
        ],
      );
    });
  }

  void _updateExpense(String expenseId, Expense Function(Expense) f) {
    state = state.copyWith(
      expenses: [
        for (final e in state.expenses)
          if (e.id == expenseId) f(e) else e,
      ],
    );
  }
}

final expensesProvider = NotifierProvider<ExpensesNotifier, ExpensesState>(
  ExpensesNotifier.new,
);
