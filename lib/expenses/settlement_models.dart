import 'expense_models.dart';

enum SettlementMethod { cash, upi, other }

const Map<SettlementMethod, String> settlementMethodLabels = {
  SettlementMethod.cash: 'Cash',
  SettlementMethod.upi: 'UPI',
  SettlementMethod.other: 'Other',
};

/// PRD §11.6: "counterpart confirms receipt (single tap; auto-confirm
/// 72h with reminder at 48h; declined confirmation opens a mini-
/// dispute)."
enum SettlementStatus { pendingConfirmation, confirmed, declined }

class Settlement {
  final String id;
  final String fromName;
  final String toName;
  final int amount;
  final SettlementMethod method;
  final SettlementStatus status;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final String? disputeReason;
  final Currency currency;

  const Settlement({
    required this.id,
    required this.fromName,
    required this.toName,
    required this.amount,
    required this.method,
    this.status = SettlementStatus.pendingConfirmation,
    required this.createdAt,
    this.confirmedAt,
    this.disputeReason,
    this.currency = homeCurrency,
  });

  Settlement copyWith({
    SettlementStatus? status,
    DateTime? confirmedAt,
    String? disputeReason,
  }) {
    return Settlement(
      id: id,
      fromName: fromName,
      toName: toName,
      amount: amount,
      method: method,
      status: status ?? this.status,
      createdAt: createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      disputeReason: disputeReason ?? this.disputeReason,
      currency: currency,
    );
  }

  bool get isOnTime =>
      confirmedAt != null && confirmedAt!.difference(createdAt).inDays <= 7;

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromName': fromName,
    'toName': toName,
    'amount': amount,
    'method': method.name,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'confirmedAt': confirmedAt?.toIso8601String(),
    'disputeReason': disputeReason,
    'currency': currency.name,
  };

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      id: json['id'] as String,
      fromName: json['fromName'] as String,
      toName: json['toName'] as String,
      amount: json['amount'] as int,
      method: SettlementMethod.values.byName(json['method'] as String),
      status: SettlementStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'] as String)
          : null,
      disputeReason: json['disputeReason'] as String?,
      currency: Currency.values.byName(json['currency'] as String),
    );
  }
}

/// Backlog addendum (E5-10): "one-agreed-currency-per-pair
/// settlements." Whatever currency this pair's first settlement used
/// becomes the agreed currency for every subsequent one between them,
/// regardless of direction (A->B or B->A).
Currency? establishedPairCurrency(
  List<Settlement> settlements,
  String personA,
  String personB,
) {
  final existing = settlements.where(
    (s) =>
        (s.fromName == personA && s.toName == personB) ||
        (s.fromName == personB && s.toName == personA),
  );
  if (existing.isEmpty) return null;
  return existing.first.currency;
}

/// PRD §11.6: "Who Owes Whom: graph-simplified net ledger." Each
/// person's net position: positive = owed to them, negative = they owe.
/// Confirmed settlements adjust the raw expense-derived net -- a
/// settlement from A to B reduces A's debt (or increases A's credit)
/// and correspondingly reduces B's credit.
Map<String, int> netBalancesByPerson(
  List<Expense> expenses,
  List<Settlement> settlements,
  Set<String> people,
) {
  final net = {for (final p in people) p: 0};
  for (final expense in expenses) {
    for (final p in people) {
      net[p] = (net[p] ?? 0) + expense.netFor(p);
    }
  }
  for (final settlement in settlements) {
    if (settlement.status != SettlementStatus.confirmed) continue;
    if (net.containsKey(settlement.fromName)) {
      net[settlement.fromName] = net[settlement.fromName]! + settlement.amount;
    }
    if (net.containsKey(settlement.toName)) {
      net[settlement.toName] = net[settlement.toName]! - settlement.amount;
    }
  }
  return net;
}

class SuggestedSettlement {
  final String fromName;
  final String toName;
  final int amount;

  const SuggestedSettlement({
    required this.fromName,
    required this.toName,
    required this.amount,
  });
}

/// PRD §11.6: "the simplification is suggested, never forced." A
/// standard greedy debt-simplification: repeatedly match the largest
/// debtor with the largest creditor until every balance nets to zero --
/// this is what actually turns "7 payments" into "3."
List<SuggestedSettlement> simplifyDebts(Map<String, int> netBalances) {
  final debtors = <MapEntry<String, int>>[];
  final creditors = <MapEntry<String, int>>[];
  for (final entry in netBalances.entries) {
    if (entry.value < 0) debtors.add(entry);
    if (entry.value > 0) creditors.add(entry);
  }
  debtors.sort((a, b) => a.value.compareTo(b.value));
  creditors.sort((a, b) => b.value.compareTo(a.value));

  var debtorAmounts = [for (final d in debtors) -d.value];
  var creditorAmounts = [for (final c in creditors) c.value];
  final suggestions = <SuggestedSettlement>[];

  var i = 0;
  var j = 0;
  while (i < debtors.length && j < creditors.length) {
    final settled = debtorAmounts[i] < creditorAmounts[j]
        ? debtorAmounts[i]
        : creditorAmounts[j];
    if (settled > 0) {
      suggestions.add(
        SuggestedSettlement(
          fromName: debtors[i].key,
          toName: creditors[j].key,
          amount: settled,
        ),
      );
    }
    debtorAmounts[i] -= settled;
    creditorAmounts[j] -= settled;
    if (debtorAmounts[i] == 0) i++;
    if (creditorAmounts[j] == 0) j++;
  }
  return suggestions;
}
