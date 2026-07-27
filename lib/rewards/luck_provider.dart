import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'luck_models.dart';
import 'rewards_provider.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class LuckState {
  final int scratchCardsAvailable;
  final int consecutiveBlanks;
  final DateTime? lastSpinDate;
  final int ticketsClaimedThisMonth;
  final int? ticketsClaimedMonthKey;
  final List<String> log;
  final List<LuckyDrawResult> pastDraws;

  const LuckState({
    this.scratchCardsAvailable = 0,
    this.consecutiveBlanks = 0,
    this.lastSpinDate,
    this.ticketsClaimedThisMonth = 0,
    this.ticketsClaimedMonthKey,
    this.log = const [],
    this.pastDraws = const [],
  });

  LuckState copyWith({
    int? scratchCardsAvailable,
    int? consecutiveBlanks,
    DateTime? lastSpinDate,
    int? ticketsClaimedThisMonth,
    int? ticketsClaimedMonthKey,
    List<String>? log,
    List<LuckyDrawResult>? pastDraws,
  }) {
    return LuckState(
      scratchCardsAvailable:
          scratchCardsAvailable ?? this.scratchCardsAvailable,
      consecutiveBlanks: consecutiveBlanks ?? this.consecutiveBlanks,
      lastSpinDate: lastSpinDate ?? this.lastSpinDate,
      ticketsClaimedThisMonth:
          ticketsClaimedThisMonth ?? this.ticketsClaimedThisMonth,
      ticketsClaimedMonthKey:
          ticketsClaimedMonthKey ?? this.ticketsClaimedMonthKey,
      log: log ?? this.log,
      pastDraws: pastDraws ?? this.pastDraws,
    );
  }
}

/// PRD §13.1: "500 coins earned (not spent) that month" -> 1 ticket.
int ticketsEarnedThisMonth(RewardsState rewards) =>
    rewards.coinsEarnedThisMonth ~/ 500;

/// PRD §13.4 -- E6-06's Luck Layer engine.
class LuckLayerNotifier extends Notifier<LuckState> {
  final Random _random = Random();

  @override
  LuckState build() => const LuckState();

  /// Wired from streaks_provider.dart's day-30 login streak milestone
  /// (previously a flagged "mock -- Luck Layer/E6-06 not built yet"
  /// log line) and from the spin wheel's scratchCard segment.
  void grantScratchCard({int count = 1, String label = 'Scratch card earned'}) {
    state = state.copyWith(
      scratchCardsAvailable: state.scratchCardsAvailable + count,
      log: [...state.log, '$label (x$count)'],
    );
  }

  int _rollWeightedCoins() {
    final totalWeight = scratchCoinBuckets.fold(
      0,
      (sum, bucket) => sum + bucket.$3,
    );
    var roll = _random.nextInt(totalWeight);
    for (final bucket in scratchCoinBuckets) {
      if (roll < bucket.$3) {
        return bucket.$1 + _random.nextInt(bucket.$2 - bucket.$1 + 1);
      }
      roll -= bucket.$3;
    }
    return scratchCoinBuckets.first.$1;
  }

  String _rollVoucher() =>
      mockScratchVouchers[_random.nextInt(mockScratchVouchers.length)];

  /// PRD's pity rule: "never >2 blanks in a row per user." Returns null
  /// if no scratch card is available.
  ScratchOutcome? scratchCard() {
    if (state.scratchCardsAvailable <= 0) return null;

    final forcedNonBlank = state.consecutiveBlanks >= 2;
    ScratchOutcome outcome;
    if (forcedNonBlank) {
      final roll = _random.nextInt(
        scratchOutcomeCoinsWeight + scratchOutcomeVoucherWeight,
      );
      outcome = roll < scratchOutcomeCoinsWeight
          ? ScratchOutcome.coins(_rollWeightedCoins())
          : ScratchOutcome.voucher(_rollVoucher());
    } else {
      final totalWeight =
          scratchOutcomeCoinsWeight +
          scratchOutcomeVoucherWeight +
          scratchOutcomeBlankWeight;
      final roll = _random.nextInt(totalWeight);
      if (roll < scratchOutcomeCoinsWeight) {
        outcome = ScratchOutcome.coins(_rollWeightedCoins());
      } else if (roll <
          scratchOutcomeCoinsWeight + scratchOutcomeVoucherWeight) {
        outcome = ScratchOutcome.voucher(_rollVoucher());
      } else {
        outcome = const ScratchOutcome.blank();
      }
    }

    final entry = switch (outcome.type) {
      ScratchOutcomeType.coins => 'Scratch card: +${outcome.coins} coins',
      ScratchOutcomeType.voucher => 'Scratch card: won ${outcome.voucherLabel}',
      ScratchOutcomeType.blank => 'Scratch card: better luck next time',
    };
    if (outcome.type == ScratchOutcomeType.coins) {
      ref
          .read(rewardsProvider.notifier)
          .awardBonus(outcome.coins, label: 'Scratch card');
    }

    state = state.copyWith(
      scratchCardsAvailable: state.scratchCardsAvailable - 1,
      consecutiveBlanks: outcome.type == ScratchOutcomeType.blank
          ? state.consecutiveBlanks + 1
          : 0,
      log: [...state.log, entry],
    );
    return outcome;
  }

  SpinBlockReason? spinBlockReason({
    required int viewerLevel,
    DateTime Function() now = DateTime.now,
  }) {
    if (viewerLevel < 5) return SpinBlockReason.levelLocked;
    final today = _dateOnly(now());
    if (state.lastSpinDate != null && _dateOnly(state.lastSpinDate!) == today) {
      return SpinBlockReason.alreadySpunToday;
    }
    return null;
  }

  /// Callers must check [spinBlockReason] first -- this always spins.
  SpinSegment spinWheel({DateTime Function() now = DateTime.now}) {
    final totalWeight = spinSegmentWeights.values.fold(0, (s, w) => s + w);
    var roll = _random.nextInt(totalWeight);
    var segment = SpinSegment.smallCoins;
    for (final entry in spinSegmentWeights.entries) {
      if (roll < entry.value) {
        segment = entry.key;
        break;
      }
      roll -= entry.value;
    }

    switch (segment) {
      case SpinSegment.smallCoins:
        ref.read(rewardsProvider.notifier).awardBonus(15, label: 'Spin wheel');
      case SpinSegment.xp:
        ref.read(rewardsProvider.notifier).awardXp(30, label: 'Spin wheel');
      case SpinSegment.scratchCard:
        grantScratchCard(label: 'Spin wheel');
      case SpinSegment.rareVoucher:
        break;
    }
    state = state.copyWith(
      lastSpinDate: _dateOnly(now()),
      log: [...state.log, 'Spin wheel: ${spinSegmentLabels[segment]}'],
    );
    return segment;
  }

  int claimableTickets(
    RewardsState rewards, {
    DateTime Function() now = DateTime.now,
  }) {
    final currentMonthKey = monthKeyFor(now());
    final earned = rewards.coinsEarnedMonthKey == currentMonthKey
        ? ticketsEarnedThisMonth(rewards)
        : 0;
    final claimed = state.ticketsClaimedMonthKey == currentMonthKey
        ? state.ticketsClaimedThisMonth
        : 0;
    final remaining = earned - claimed;
    return remaining > 0 ? remaining : 0;
  }

  bool enterLuckyDraw(
    RewardsState rewards, {
    DateTime Function() now = DateTime.now,
  }) {
    if (claimableTickets(rewards, now: now) <= 0) return false;
    final currentMonthKey = monthKeyFor(now());
    final claimedSoFar = state.ticketsClaimedMonthKey == currentMonthKey
        ? state.ticketsClaimedThisMonth
        : 0;
    final newClaimed = claimedSoFar + 1;
    state = state.copyWith(
      ticketsClaimedThisMonth: newClaimed,
      ticketsClaimedMonthKey: currentMonthKey,
      log: [...state.log, 'Entered lucky draw (ticket $newClaimed this month)'],
    );
    return true;
  }

  /// No real cron/other-player ticket pool exists -- a debug control
  /// triggers the draw so the "draw-day result state" is reachable.
  void runMonthlyDraw({
    required String viewerName,
    DateTime Function() now = DateTime.now,
  }) {
    final n = now();
    final currentMonthKey = monthKeyFor(n);
    final myEntries = state.ticketsClaimedMonthKey == currentMonthKey
        ? state.ticketsClaimedThisMonth
        : 0;
    final otherEntries = 40 + _random.nextInt(80);
    final totalEntries = myEntries + otherEntries;
    final iWon = myEntries > 0 && _random.nextInt(totalEntries) < myEntries;
    final result = LuckyDrawResult(
      monthKey: currentMonthKey,
      totalEntries: totalEntries,
      winnerLabel: iWon ? viewerName : 'Another CricUnity player',
      prize: luckyDrawPrize,
      drawnAt: n,
    );
    state = state.copyWith(
      pastDraws: [...state.pastDraws, result],
      log: [
        ...state.log,
        'Lucky draw: ${result.winnerLabel} won (of $totalEntries entries)',
      ],
    );
  }
}

final luckLayerProvider = NotifierProvider<LuckLayerNotifier, LuckState>(
  LuckLayerNotifier.new,
);
