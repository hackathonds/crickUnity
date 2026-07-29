/// PRD §8.13-8.14 (Expenses/Revenue): "Organizer ledger: inflows
/// (entry fees, sponsors) / outflows (grounds, officials, prizes,
/// trophies) -- line-itemized. Transparency rule: registered captains
/// see the categorized summary (not sponsor contract values if marked
/// confidential -- but the prize pool total & payout status is always
/// visible). Prize payout tracker: winner confirms receipt; unconfirmed
/// >7d flags Organizer Score."
enum LedgerDirection { inflow, outflow }

enum LedgerCategory {
  entryFees,
  sponsors,
  grounds,
  officials,
  prizes,
  trophies,
}

const Map<LedgerCategory, String> ledgerCategoryLabels = {
  LedgerCategory.entryFees: 'Entry fees',
  LedgerCategory.sponsors: 'Sponsors',
  LedgerCategory.grounds: 'Grounds',
  LedgerCategory.officials: 'Officials',
  LedgerCategory.prizes: 'Prizes',
  LedgerCategory.trophies: 'Trophies',
};

const Map<LedgerCategory, LedgerDirection> ledgerCategoryDirection = {
  LedgerCategory.entryFees: LedgerDirection.inflow,
  LedgerCategory.sponsors: LedgerDirection.inflow,
  LedgerCategory.grounds: LedgerDirection.outflow,
  LedgerCategory.officials: LedgerDirection.outflow,
  LedgerCategory.prizes: LedgerDirection.outflow,
  LedgerCategory.trophies: LedgerDirection.outflow,
};

class LedgerEntry {
  final String id;
  final String tournamentId;
  final LedgerCategory category;
  final int amount;
  final String note;

  /// PRD: "not sponsor contract values if marked confidential" --
  /// only meaningful for [LedgerCategory.sponsors] entries.
  final bool isConfidential;

  const LedgerEntry({
    required this.id,
    required this.tournamentId,
    required this.category,
    required this.amount,
    this.note = '',
    this.isConfidential = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'tournamentId': tournamentId,
    'category': category.name,
    'amount': amount,
    'note': note,
    'isConfidential': isConfidential,
  };

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      id: json['id'] as String,
      tournamentId: json['tournamentId'] as String,
      category: LedgerCategory.values.byName(json['category'] as String),
      amount: json['amount'] as int,
      note: json['note'] as String? ?? '',
      isConfidential: json['isConfidential'] as bool? ?? false,
    );
  }
}

/// PRD: "Prize payout tracker: winner confirms receipt; unconfirmed
/// >7d flags Organizer Score." PRD names no exact grace window beyond
/// "7d," which is exact -- not a judgment call.
const Duration payoutConfirmationGrace = Duration(days: 7);

class PrizePayout {
  final String id;
  final String tournamentId;
  final String winnerRegistrationId;
  final String winnerTeamName;
  final int amount;
  final DateTime awardedAt;
  final DateTime? confirmedAt;

  const PrizePayout({
    required this.id,
    required this.tournamentId,
    required this.winnerRegistrationId,
    required this.winnerTeamName,
    required this.amount,
    required this.awardedAt,
    this.confirmedAt,
  });

  bool get isConfirmed => confirmedAt != null;

  /// PRD: "unconfirmed >7d flags Organizer Score" -- the input signal
  /// this story computes. No broader cross-tournament Organizer Score
  /// aggregate/profile exists yet (flagged, a bigger reputation-system
  /// build than this story's line calls for) -- this is the raw input
  /// that feeds it.
  bool isOverdue(DateTime now) =>
      !isConfirmed && now.difference(awardedAt) > payoutConfirmationGrace;

  PrizePayout copyWith({DateTime? confirmedAt}) {
    return PrizePayout(
      id: id,
      tournamentId: tournamentId,
      winnerRegistrationId: winnerRegistrationId,
      winnerTeamName: winnerTeamName,
      amount: amount,
      awardedAt: awardedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tournamentId': tournamentId,
    'winnerRegistrationId': winnerRegistrationId,
    'winnerTeamName': winnerTeamName,
    'amount': amount,
    'awardedAt': awardedAt.toIso8601String(),
    'confirmedAt': confirmedAt?.toIso8601String(),
  };

  factory PrizePayout.fromJson(Map<String, dynamic> json) {
    return PrizePayout(
      id: json['id'] as String,
      tournamentId: json['tournamentId'] as String,
      winnerRegistrationId: json['winnerRegistrationId'] as String,
      winnerTeamName: json['winnerTeamName'] as String,
      amount: json['amount'] as int,
      awardedAt: DateTime.parse(json['awardedAt'] as String),
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'] as String)
          : null,
    );
  }
}
