/// PRD §13.4 (Luck layer) + DS §7-56/11.14. Backlog: "Scratch mask,
/// spin physics w/ public odds page, chest burst, pity rule, monthly
/// lucky draw card w/ entry-count disclosure."
enum ScratchOutcomeType { coins, voucher, blank }

/// PRD: "reveal coins (10-500 weighted low), vouchers, or 'better luck'
/// (never >2 blanks in a row per user -- pity rule)."
class ScratchOutcome {
  final ScratchOutcomeType type;
  final int coins;
  final String? voucherLabel;

  const ScratchOutcome._(this.type, this.coins, this.voucherLabel);

  const ScratchOutcome.coins(int amount)
    : this._(ScratchOutcomeType.coins, amount, null);

  const ScratchOutcome.voucher(String label)
    : this._(ScratchOutcomeType.voucher, 0, label);

  const ScratchOutcome.blank() : this._(ScratchOutcomeType.blank, 0, null);
}

/// PRD gives ranges/weighting direction ("10-500 weighted low") but no
/// exact bucket table -- these weights are a flagged judgment call, and
/// the overall outcome split (coins/voucher/blank, before the pity
/// rule overrides it) likewise isn't PRD-specified.
const List<(int min, int max, int weight)> scratchCoinBuckets = [
  (10, 30, 50),
  (31, 100, 30),
  (101, 250, 15),
  (251, 500, 5),
];

const int scratchOutcomeCoinsWeight = 60;
const int scratchOutcomeVoucherWeight = 15;
const int scratchOutcomeBlankWeight = 25;

const List<String> mockScratchVouchers = [
  '₹50 food delivery voucher',
  '₹100 sports store voucher',
  '20% ground booking discount',
];

/// PRD: "Spin wheel: 1 free spin/day at Level 5+; segments = small
/// coins, XP, scratch card, rare voucher; odds page publicly viewable
/// (transparency rule)." Weights are a flagged judgment call (PRD names
/// the segment types, not their odds) -- published on the odds screen
/// either way, satisfying the transparency rule regardless of the exact
/// numbers chosen.
enum SpinSegment { smallCoins, xp, scratchCard, rareVoucher }

const Map<SpinSegment, String> spinSegmentLabels = {
  SpinSegment.smallCoins: 'Small coins (+15)',
  SpinSegment.xp: 'XP (+30)',
  SpinSegment.scratchCard: 'Scratch card',
  SpinSegment.rareVoucher: 'Rare voucher',
};

const Map<SpinSegment, int> spinSegmentWeights = {
  SpinSegment.smallCoins: 50,
  SpinSegment.xp: 30,
  SpinSegment.scratchCard: 15,
  SpinSegment.rareVoucher: 5,
};

enum SpinBlockReason { levelLocked, alreadySpunToday }

/// PRD: "Lucky draw: monthly ticket per 500 coins earned (not spent)
/// that month; prizes = partner merchandise; winners announced with
/// entry-count disclosure." No real partner-merchandise inventory or
/// other-player ticket data exists -- totalEntries/winner are mocked,
/// same flagged convention as every other missing-backend gap.
class LuckyDrawResult {
  final int monthKey;
  final int totalEntries;
  final String winnerLabel;
  final String prize;
  final DateTime drawnAt;

  const LuckyDrawResult({
    required this.monthKey,
    required this.totalEntries,
    required this.winnerLabel,
    required this.prize,
    required this.drawnAt,
  });

  Map<String, dynamic> toJson() => {
    'monthKey': monthKey,
    'totalEntries': totalEntries,
    'winnerLabel': winnerLabel,
    'prize': prize,
    'drawnAt': drawnAt.toIso8601String(),
  };

  factory LuckyDrawResult.fromJson(Map<String, dynamic> json) {
    return LuckyDrawResult(
      monthKey: json['monthKey'] as int,
      totalEntries: json['totalEntries'] as int,
      winnerLabel: json['winnerLabel'] as String,
      prize: json['prize'] as String,
      drawnAt: DateTime.parse(json['drawnAt'] as String),
    );
  }
}

const String luckyDrawPrize = 'Partner merchandise hamper';
