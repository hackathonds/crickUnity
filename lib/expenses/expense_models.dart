import 'package:flutter/material.dart';

import '../design_system/components/app_expense_card.dart';

/// PRD §11.2: each category is meant to become "a first-class type, not
/// a mere label" -- but that per-category behavior (ground-fee
/// auto-draft, ball-purchase losing-team-pays toggle, itemized food,
/// equipment amortization, fine charts, prize-money distribution
/// math...) is explicitly E5-02's separate story. Here the category is
/// just the grid selector DS §7-49 opens the form with.
enum ExpenseCategory {
  groundFees,
  ballPurchase,
  umpireScorerFees,
  travel,
  food,
  equipmentJersey,
  tournamentEntry,
  penaltyFine,
  prizeMoney,
}

const Map<ExpenseCategory, String> expenseCategoryLabels = {
  ExpenseCategory.groundFees: 'Ground fees',
  ExpenseCategory.ballPurchase: 'Ball purchase',
  ExpenseCategory.umpireScorerFees: 'Umpire/scorer fees',
  ExpenseCategory.travel: 'Travel',
  ExpenseCategory.food: 'Food',
  ExpenseCategory.equipmentJersey: 'Equipment/jersey',
  ExpenseCategory.tournamentEntry: 'Tournament entry',
  ExpenseCategory.penaltyFine: 'Penalty/fine',
  ExpenseCategory.prizeMoney: 'Prize money',
};

/// No custom vector glyphs exist for these categories yet (only the
/// generic receipt/split/wallet glyphs from the icon-glyph library) --
/// plain Material icons stand in, same treatment as every other
/// missing-asset gap this session.
const Map<ExpenseCategory, IconData> expenseCategoryIcons = {
  ExpenseCategory.groundFees: Icons.landscape_outlined,
  ExpenseCategory.ballPurchase: Icons.sports_cricket_outlined,
  ExpenseCategory.umpireScorerFees: Icons.sports_outlined,
  ExpenseCategory.travel: Icons.directions_car_outlined,
  ExpenseCategory.food: Icons.restaurant_outlined,
  ExpenseCategory.equipmentJersey: Icons.checkroom_outlined,
  ExpenseCategory.tournamentEntry: Icons.emoji_events_outlined,
  ExpenseCategory.penaltyFine: Icons.gavel_outlined,
  ExpenseCategory.prizeMoney: Icons.card_giftcard_outlined,
};

/// DS §7-49: "method segmented (Equal/Custom/Shares/%/Items/
/// Attendance)." PRD §11.3 additionally names a 7th method,
/// Role-based ("guests pay double, scorer exempt") -- not in DS's
/// literal segmented control, and functionally just a per-person
/// weight, so it folds into [shares] rather than getting its own
/// segment; flagged as a judgment call, not a silent drop.
enum SplitMethod {
  equal,
  custom,
  shares,
  percentages,
  itemized,
  attendanceBased,
}

const Map<SplitMethod, String> splitMethodLabels = {
  SplitMethod.equal: 'Equal',
  SplitMethod.custom: 'Custom',
  SplitMethod.shares: 'Shares',
  SplitMethod.percentages: '%',
  SplitMethod.itemized: 'Items',
  SplitMethod.attendanceBased: 'Attendance',
};

enum ExpenseApprovalState { none, pendingApproval, approved }

class PaidByEntry {
  final String name;
  final int amount;

  const PaidByEntry({required this.name, required this.amount});
}

class SplitShare {
  final String name;
  final int amount;

  const SplitShare({required this.name, required this.amount});
}

/// PRD §11.3: "Validation: parts must total exactly; rounding remainder
/// assigned to payer by default." [payerName], when present in
/// [people], absorbs the integer-division remainder so the parts
/// always reconcile to the cent (rupee).
List<SplitShare> equalSplit(
  int amount,
  List<String> people, {
  String? payerName,
}) {
  if (people.isEmpty) return const [];
  final base = amount ~/ people.length;
  final remainder = amount % people.length;
  final payerIndex = payerName != null ? people.indexOf(payerName) : -1;
  final remainderIndex = payerIndex >= 0 ? payerIndex : 0;
  return [
    for (var i = 0; i < people.length; i++)
      SplitShare(
        name: people[i],
        amount: base + (i == remainderIndex ? remainder : 0),
      ),
  ];
}

/// Proportional split by weight (shares or percentages -- percentages
/// are just shares that must sum to 100, validated separately by the
/// caller). Remainder from integer rounding goes to the payer, same
/// convention as [equalSplit].
List<SplitShare> weightedSplit(
  int amount,
  Map<String, int> weights, {
  String? payerName,
}) {
  final names = weights.keys.toList();
  final totalWeight = weights.values.fold(0, (a, b) => a + b);
  if (names.isEmpty || totalWeight == 0) {
    return [for (final n in names) SplitShare(name: n, amount: 0)];
  }
  final amounts = <int>[];
  var allocated = 0;
  for (final n in names) {
    final share = (amount * weights[n]! / totalWeight).floor();
    amounts.add(share);
    allocated += share;
  }
  final remainder = amount - allocated;
  final payerIndex = payerName != null ? names.indexOf(payerName) : -1;
  final remainderIndex = payerIndex >= 0 ? payerIndex : 0;
  amounts[remainderIndex] += remainder;
  return [
    for (var i = 0; i < names.length; i++)
      SplitShare(name: names[i], amount: amounts[i]),
  ];
}

class Expense {
  final String id;
  final String title;
  final ExpenseCategory category;
  final int amount;
  final List<PaidByEntry> paidBy;
  final SplitMethod splitMethod;
  final List<SplitShare> splitAmong;
  final String? contextMatchId;
  final DateTime date;
  final bool hasProof;
  final String? notes;
  final ExpenseApprovalState approvalState;
  final String createdByName;
  final Map<String, AppExpenseRowState> settlementStates;

  const Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.paidBy,
    required this.splitMethod,
    required this.splitAmong,
    this.contextMatchId,
    required this.date,
    this.hasProof = false,
    this.notes,
    this.approvalState = ExpenseApprovalState.none,
    required this.createdByName,
    this.settlementStates = const {},
  });

  int get splitTotal => splitAmong.fold(0, (sum, s) => sum + s.amount);
  int get splitRemainder => amount - splitTotal;

  int get paidTotal => paidBy.fold(0, (sum, p) => sum + p.amount);
  int get paidRemainder => amount - paidTotal;

  /// PRD §11.6/net computation for [viewerName]: positive means the
  /// viewer is owed, negative means the viewer owes.
  int netFor(String viewerName) {
    final paid = paidBy
        .where((p) => p.name == viewerName)
        .fold(0, (sum, p) => sum + p.amount);
    final owed = splitAmong
        .where((s) => s.name == viewerName)
        .fold(0, (sum, s) => sum + s.amount);
    return paid - owed;
  }

  Expense copyWith({ExpenseApprovalState? approvalState}) {
    return Expense(
      id: id,
      title: title,
      category: category,
      amount: amount,
      paidBy: paidBy,
      splitMethod: splitMethod,
      splitAmong: splitAmong,
      contextMatchId: contextMatchId,
      date: date,
      hasProof: hasProof,
      notes: notes,
      approvalState: approvalState ?? this.approvalState,
      createdByName: createdByName,
      settlementStates: settlementStates,
    );
  }
}

/// PRD §11.7: "team threshold (default ₹1,000)."
const int expenseApprovalThresholdRupees = 1000;

/// PRD §11.7: "self-created captain expenses above threshold -> VC/
/// Owner approves (no self-approval)." No real team-role hierarchy
/// (Vice-Captain/Owner assignment) is wired into this module yet -- a
/// mock stand-in name, same convention as every other missing-backend
/// mock this session.
const String mockVcOrOwnerName = 'Vikram Shah';

/// Mock squad for the debug demo, matching the same 4-name roster used
/// throughout the Matches module's own mocks -- no real team-roster
/// lookup is wired into this module yet either.
List<String> mockExpenseParticipants() => const [
  'Kabir Singh',
  'Priya Nair',
  'Arjun Mehta',
  'Sana Iyer',
];
