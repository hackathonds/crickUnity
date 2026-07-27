import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'expense_models.dart';
import 'settlement_models.dart';

class SettlementsState {
  final List<Settlement> settlements;

  const SettlementsState({this.settlements = const []});

  SettlementsState copyWith({List<Settlement>? settlements}) {
    return SettlementsState(settlements: settlements ?? this.settlements);
  }
}

/// PRD §11.6 -- E5-04's settle-up flow. No backend/persistence exists
/// yet; this is the in-memory settlement ledger both sides read from,
/// same convention as [ExpensesNotifier].
class SettlementsNotifier extends Notifier<SettlementsState> {
  int _nextId = 0;

  @override
  SettlementsState build() => const SettlementsState();

  /// PRD §11.6: "Settle flow: pick counterpart -> amount (full/partial/
  /// custom) -> method note ... -> counterpart confirms receipt."
  /// Returns null (no-op) if [currency] conflicts with this pair's
  /// already-established settlement currency (backlog addendum E5-10:
  /// "one-agreed-currency-per-pair settlements").
  String? proposeSettlement({
    required String fromName,
    required String toName,
    required int amount,
    required SettlementMethod method,
    Currency currency = homeCurrency,
    DateTime Function() now = DateTime.now,
  }) {
    final established = establishedPairCurrency(
      state.settlements,
      fromName,
      toName,
    );
    if (established != null && established != currency) return null;

    final id = 'settlement-${now().millisecondsSinceEpoch}-${_nextId++}';
    state = state.copyWith(
      settlements: [
        Settlement(
          id: id,
          fromName: fromName,
          toName: toName,
          amount: amount,
          method: method,
          createdAt: now(),
          currency: currency,
        ),
        ...state.settlements,
      ],
    );
    return id;
  }

  /// "single tap" confirm. "On-time settler" streak credit is judged
  /// against the settlement's own creation time here -- a Settlement
  /// isn't always traceable back to one originating expense (it can
  /// net several), so "within 7 days of the expense" is approximated as
  /// "confirmed within 7 days of being proposed," flagged as a
  /// simplification.
  void confirmSettlement(
    String settlementId, {
    DateTime Function() now = DateTime.now,
  }) {
    state = state.copyWith(
      settlements: [
        for (final s in state.settlements)
          if (s.id == settlementId)
            s.copyWith(status: SettlementStatus.confirmed, confirmedAt: now())
          else
            s,
      ],
    );
  }

  /// "declined confirmation opens a mini-dispute." Full dispute
  /// resolution (escalation, freeze, etc.) is E5-06's separate scope --
  /// this just records the decline + reason.
  void declineSettlement(String settlementId, String reason) {
    state = state.copyWith(
      settlements: [
        for (final s in state.settlements)
          if (s.id == settlementId)
            s.copyWith(status: SettlementStatus.declined, disputeReason: reason)
          else
            s,
      ],
    );
  }

  /// PRD §11.6: "auto-confirm 72h with reminder at 48h." The reminder
  /// itself is a notification-surface concern (E5-05's separate scope,
  /// "Reminders & pending views") -- this handles the auto-confirm edge.
  void checkAutoConfirm(
    String settlementId, {
    DateTime Function() now = DateTime.now,
  }) {
    final matches = state.settlements.where((s) => s.id == settlementId);
    if (matches.isEmpty) return;
    final settlement = matches.first;
    if (settlement.status != SettlementStatus.pendingConfirmation) return;
    if (now().difference(settlement.createdAt).inHours < 72) return;
    confirmSettlement(settlementId, now: now);
  }
}

final settlementsProvider =
    NotifierProvider<SettlementsNotifier, SettlementsState>(
      SettlementsNotifier.new,
    );
