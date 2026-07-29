import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'expense_models.dart';
import 'expenses_provider.dart';
import 'wallet_payout_models.dart';

class WalletPayoutsState {
  final List<WalletPayoutRequest> requests;

  const WalletPayoutsState({this.requests = const []});

  WalletPayoutsState copyWith({List<WalletPayoutRequest>? requests}) {
    return WalletPayoutsState(requests: requests ?? this.requests);
  }

  Map<String, dynamic> toJson() => {
    'requests': [for (final r in requests) r.toJson()],
  };

  factory WalletPayoutsState.fromJson(Map<String, dynamic> json) {
    return WalletPayoutsState(
      requests: [
        for (final r in json['requests'] as List)
          WalletPayoutRequest.fromJson(r as Map<String, dynamic>),
      ],
    );
  }
}

/// PRD §11.8 -- E5-07's wallet payouts. On completion this genuinely
/// creates an [Expense] (via [expensesProvider]) with the wallet in
/// splitAmong, so the payout correctly decreases the wallet's computed
/// balance through the same ledger every other wallet movement
/// (Ground Fees' "team wallet pays," fines, prize-money-to-wallet) has
/// been flowing through since E5-02/E5-03/E5-06 -- not a separate mock
/// number.
class WalletPayoutsNotifier extends PersistedNotifier<WalletPayoutsState> {
  @override
  String get persistenceKey => 'wallet_payouts_v1';

  @override
  WalletPayoutsState seed() => const WalletPayoutsState();

  @override
  Map<String, dynamic> toJson(WalletPayoutsState value) => value.toJson();

  @override
  WalletPayoutsState fromJson(Map<String, dynamic> json) =>
      WalletPayoutsState.fromJson(json);

  /// Computed from current state rather than a separate incrementing
  /// field -- a plain field would restart at 0 after every app restart
  /// and collide with ids already restored from disk.
  int get _nextId => state.requests.length;

  /// PRD §11.8: "payouts above threshold need dual approval." At or
  /// below the threshold, a payout completes immediately.
  String requestPayout({
    required String purpose,
    required int amount,
    required String createdByName,
  }) {
    final id = 'payout-$_nextId';
    final request = WalletPayoutRequest(
      id: id,
      purpose: purpose,
      amount: amount,
    );
    state = state.copyWith(requests: [...state.requests, request]);
    if (amount <= expenseApprovalThresholdRupees) {
      _complete(id, createdByName: createdByName, createdByIsCaptain: true);
    }
    return id;
  }

  void approvePayout(
    String payoutId, {
    required bool asCaptain,
    required String createdByName,
  }) {
    final matches = state.requests.where((r) => r.id == payoutId);
    if (matches.isEmpty || matches.first.completed) return;
    final current = matches.first;
    final captainApproved = asCaptain || current.captainApproved;
    final managerOrOwnerApproved = !asCaptain || current.managerOrOwnerApproved;
    state = state.copyWith(
      requests: [
        for (final r in state.requests)
          if (r.id == payoutId)
            r.copyWith(
              captainApproved: captainApproved,
              managerOrOwnerApproved: managerOrOwnerApproved,
            )
          else
            r,
      ],
    );
    if (captainApproved && managerOrOwnerApproved) {
      _complete(
        payoutId,
        createdByName: createdByName,
        createdByIsCaptain: true,
      );
    }
  }

  void _complete(
    String payoutId, {
    required String createdByName,
    required bool createdByIsCaptain,
  }) {
    final matches = state.requests.where((r) => r.id == payoutId);
    if (matches.isEmpty) return;
    final request = matches.first;
    final expenseId = ref
        .read(expensesProvider.notifier)
        .addExpense(
          title: 'Wallet payout: ${request.purpose}',
          // No "misc/other" category exists among PRD §11.2's 9 -- this
          // is just the closest generic bucket for a ledger entry that
          // doesn't fit a specific one, flagged rather than inventing a
          // 10th category unrequested by the source docs.
          category: ExpenseCategory.equipmentJersey,
          amount: request.amount,
          paidBy: [PaidByEntry(name: request.purpose, amount: request.amount)],
          splitMethod: SplitMethod.custom,
          splitAmong: [
            SplitShare(name: teamWalletPayerName, amount: request.amount),
          ],
          createdByName: createdByName,
          createdByIsCaptain: createdByIsCaptain,
        );
    state = state.copyWith(
      requests: [
        for (final r in state.requests)
          if (r.id == payoutId)
            r.copyWith(completed: true, expenseId: expenseId)
          else
            r,
      ],
    );
  }
}

final walletPayoutsProvider =
    NotifierProvider<WalletPayoutsNotifier, WalletPayoutsState>(
      WalletPayoutsNotifier.new,
    );
