import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'premium_provider.dart';
import 'rewards_models.dart';

class RewardsState {
  final List<CoinBatch> coinBatches;
  final int xpTotal;
  final List<CeremonyEvent> ceremonyQueue;
  final List<String> log;
  final bool suppressCeremonies;
  final int coinsEarnedThisMonth;
  final int? coinsEarnedMonthKey;

  const RewardsState({
    this.coinBatches = const [],
    this.xpTotal = 0,
    this.ceremonyQueue = const [],
    this.log = const [],
    this.suppressCeremonies = false,
    this.coinsEarnedThisMonth = 0,
    this.coinsEarnedMonthKey,
  });

  int get level => levelForXp(xpTotal);

  int get coinBalance =>
      coinBatches.fold(0, (sum, batch) => sum + batch.remaining);

  RewardsState copyWith({
    List<CoinBatch>? coinBatches,
    int? xpTotal,
    List<CeremonyEvent>? ceremonyQueue,
    List<String>? log,
    bool? suppressCeremonies,
    int? coinsEarnedThisMonth,
    int? coinsEarnedMonthKey,
  }) {
    return RewardsState(
      coinBatches: coinBatches ?? this.coinBatches,
      xpTotal: xpTotal ?? this.xpTotal,
      ceremonyQueue: ceremonyQueue ?? this.ceremonyQueue,
      log: log ?? this.log,
      suppressCeremonies: suppressCeremonies ?? this.suppressCeremonies,
      coinsEarnedThisMonth: coinsEarnedThisMonth ?? this.coinsEarnedThisMonth,
      coinsEarnedMonthKey: coinsEarnedMonthKey ?? this.coinsEarnedMonthKey,
    );
  }
}

int monthKeyFor(DateTime d) => d.year * 12 + d.month;

/// PRD §13 -- E6-01's coin/XP engine. "All match-derived earnings
/// release only after scorecard confirmation" -- callers only ever
/// invoke [awardActions] from that gated moment (scoring_provider.dart's
/// _maybeFireRipple), never speculatively. E6-05 adds the FIFO coin
/// ledger (expiry) and spend side (marketplace redemption) on top.
class RewardsNotifier extends Notifier<RewardsState> {
  @override
  RewardsState build() => const RewardsState();

  void awardActions(
    List<EarningAction> actions, {
    required String contextLabel,
    DateTime Function() now = DateTime.now,
  }) {
    var coinsGained = 0;
    var xpGained = 0;
    final entries = <String>[];
    for (final action in actions) {
      final reward = earningTable[action]!;
      coinsGained += reward.coins;
      xpGained += reward.xp;
      entries.add(
        '${earningActionLabels[action]} ($contextLabel): '
        '+${reward.coins} coins, +${reward.xp} XP',
      );
    }
    final proBonus = _proBonusFor(coinsGained);
    if (proBonus > 0) {
      entries.add('CricUnity Pro bonus: +$proBonus coins');
    }
    _applyCoinsAndXp(coinsGained + proBonus, xpGained, entries, now: now);
  }

  /// Irregular one-off bonuses that don't fit the fixed per-action
  /// earning table -- streak milestones (E6-02), etc.
  void awardBonus(
    int coins, {
    required String label,
    DateTime Function() now = DateTime.now,
  }) {
    final proBonus = _proBonusFor(coins);
    final entries = [
      '$label: +$coins coins',
      if (proBonus > 0) 'CricUnity Pro bonus: +$proBonus coins',
    ];
    _applyCoinsAndXp(coins + proBonus, 0, entries, now: now);
  }

  /// PRD §13.6: "1.25x coin multiplier (capped)." No cap value is
  /// given -- capping the bonus itself (not the total) at +50 coins per
  /// award is a flagged judgment call. Never applied to refunds
  /// (refundWithApology bypasses this, calling _applyCoinsAndXp
  /// directly) -- multiplying a failed-fulfillment refund would be a
  /// reward for the failure, not an earning.
  int _proBonusFor(int coins) {
    if (coins <= 0 || !ref.read(premiumProvider).isPro) return 0;
    return ((coins * 0.25).round()).clamp(0, 50);
  }

  /// Pure-XP awards (E6-06's spin wheel XP segment) -- no coin batch.
  void awardXp(
    int xp, {
    required String label,
    DateTime Function() now = DateTime.now,
  }) {
    _applyCoinsAndXp(0, xp, ['$label: +$xp XP'], now: now);
  }

  void _applyCoinsAndXp(
    int coins,
    int xp,
    List<String> logEntries, {
    DateTime Function() now = DateTime.now,
  }) {
    final beforeLevel = state.level;
    final newXpTotal = state.xpTotal + xp;
    final afterLevel = levelForXp(newXpTotal);
    final newCeremonies = [
      for (var lvl = beforeLevel + 1; lvl <= afterLevel; lvl++)
        CeremonyEvent(type: CeremonyType.levelUp, level: lvl),
    ];
    final newBatches = coins > 0
        ? [
            ...state.coinBatches,
            CoinBatch(amount: coins, remaining: coins, earnedAt: now()),
          ]
        : state.coinBatches;
    // PRD §13.4's lucky draw: "monthly ticket per 500 coins earned (not
    // spent) that month" -- tracked here, the one funnel every coin
    // award already goes through, rather than wiring every earn call
    // site individually.
    final currentMonthKey = monthKeyFor(now());
    final sameMonth = state.coinsEarnedMonthKey == currentMonthKey;
    final newCoinsEarnedThisMonth = coins > 0
        ? (sameMonth ? state.coinsEarnedThisMonth + coins : coins)
        : (sameMonth ? state.coinsEarnedThisMonth : 0);
    state = state.copyWith(
      coinBatches: newBatches,
      xpTotal: newXpTotal,
      log: [...state.log, ...logEntries],
      ceremonyQueue: [...state.ceremonyQueue, ...newCeremonies],
      coinsEarnedThisMonth: newCoinsEarnedThisMonth,
      coinsEarnedMonthKey: currentMonthKey,
    );
  }

  /// PRD §13.5's redemption "coin deduction" -- FIFO burn (oldest
  /// batches first), same burn order expiry uses. Returns false without
  /// mutating state if the balance can't cover [amount].
  bool spendCoins(int amount, {required String label}) {
    if (state.coinBalance < amount) return false;
    var toSpend = amount;
    final updated = <CoinBatch>[];
    for (final batch in state.coinBatches) {
      if (toSpend <= 0 || batch.remaining == 0) {
        if (batch.remaining > 0) updated.add(batch);
        continue;
      }
      if (batch.remaining <= toSpend) {
        toSpend -= batch.remaining;
      } else {
        updated.add(batch.copyWith(remaining: batch.remaining - toSpend));
        toSpend = 0;
      }
    }
    state = state.copyWith(
      coinBatches: updated,
      log: [...state.log, '$label: -$amount coins'],
    );
    return true;
  }

  /// PRD §13.5's redemption auto-refund: "failed fulfillment auto-
  /// refunds coins with apology bonus (+10)."
  void refundWithApology(int amount, {required String label}) {
    _applyCoinsAndXp(amount + 10, 0, [
      '$label: refunded $amount coins + 10 apology bonus',
    ]);
  }

  /// PRD §13.1: "expire 12 months after earning, FIFO burn." Callers
  /// (debug controls / a real periodic sweep once one exists) invoke
  /// this to burn any batch whose 12-month window has passed.
  void sweepExpiredCoins({DateTime Function() now = DateTime.now}) {
    final n = now();
    final kept = <CoinBatch>[];
    final expiredEntries = <String>[];
    for (final batch in state.coinBatches) {
      if (batch.remaining <= 0) continue;
      if (!n.isBefore(batch.expiresAt)) {
        expiredEntries.add('${batch.remaining} coins expired (FIFO burn)');
      } else {
        kept.add(batch);
      }
    }
    if (expiredEntries.isEmpty) return;
    state = state.copyWith(
      coinBatches: kept,
      log: [...state.log, ...expiredEntries],
    );
  }

  /// Lets other notifiers (e.g. AchievementsNotifier's badge tier-ups)
  /// push into the same shared ceremony queue as level-ups.
  void enqueueCeremony(CeremonyEvent event) {
    state = state.copyWith(ceremonyQueue: [...state.ceremonyQueue, event]);
  }

  /// DS §5.8: "suppressed during Live Scoring & money confirmations,
  /// delivered after." Callers on those specific surfaces toggle this
  /// (e.g. Live Scoring Console in initState/dispose) -- comprehensive
  /// wiring across every money screen is a broader integration than
  /// this one story, flagged rather than silently left undone.
  void setSuppressCeremonies(bool suppressed) {
    state = state.copyWith(suppressCeremonies: suppressed);
  }

  /// DS §5.8: "queues if multiple (never stacks)." Callers pop one at a
  /// time once [RewardsState.suppressCeremonies] is false.
  CeremonyEvent? dequeueNextCeremony() {
    if (state.suppressCeremonies || state.ceremonyQueue.isEmpty) return null;
    final next = state.ceremonyQueue.first;
    state = state.copyWith(ceremonyQueue: state.ceremonyQueue.sublist(1));
    return next;
  }
}

final rewardsProvider = NotifierProvider<RewardsNotifier, RewardsState>(
  RewardsNotifier.new,
);
