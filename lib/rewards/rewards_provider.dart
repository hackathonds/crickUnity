import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'rewards_models.dart';

class RewardsState {
  final int coinBalance;
  final int xpTotal;
  final List<CeremonyEvent> ceremonyQueue;
  final List<String> log;
  final bool suppressCeremonies;

  const RewardsState({
    this.coinBalance = 0,
    this.xpTotal = 0,
    this.ceremonyQueue = const [],
    this.log = const [],
    this.suppressCeremonies = false,
  });

  int get level => levelForXp(xpTotal);

  RewardsState copyWith({
    int? coinBalance,
    int? xpTotal,
    List<CeremonyEvent>? ceremonyQueue,
    List<String>? log,
    bool? suppressCeremonies,
  }) {
    return RewardsState(
      coinBalance: coinBalance ?? this.coinBalance,
      xpTotal: xpTotal ?? this.xpTotal,
      ceremonyQueue: ceremonyQueue ?? this.ceremonyQueue,
      log: log ?? this.log,
      suppressCeremonies: suppressCeremonies ?? this.suppressCeremonies,
    );
  }
}

/// PRD §13 -- E6-01's coin/XP engine. "All match-derived earnings
/// release only after scorecard confirmation" -- callers only ever
/// invoke [awardActions] from that gated moment (scoring_provider.dart's
/// _maybeFireRipple), never speculatively.
class RewardsNotifier extends Notifier<RewardsState> {
  @override
  RewardsState build() => const RewardsState();

  void awardActions(
    List<EarningAction> actions, {
    required String contextLabel,
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
    _applyCoinsAndXp(coinsGained, xpGained, entries);
  }

  /// Irregular one-off bonuses that don't fit the fixed per-action
  /// earning table -- streak milestones (E6-02), etc.
  void awardBonus(int coins, {required String label}) {
    _applyCoinsAndXp(coins, 0, ['$label: +$coins coins']);
  }

  void _applyCoinsAndXp(int coins, int xp, List<String> logEntries) {
    final beforeLevel = state.level;
    final newXpTotal = state.xpTotal + xp;
    final afterLevel = levelForXp(newXpTotal);
    final newCeremonies = [
      for (var lvl = beforeLevel + 1; lvl <= afterLevel; lvl++)
        CeremonyEvent(type: CeremonyType.levelUp, level: lvl),
    ];
    state = state.copyWith(
      coinBalance: state.coinBalance + coins,
      xpTotal: newXpTotal,
      log: [...state.log, ...logEntries],
      ceremonyQueue: [...state.ceremonyQueue, ...newCeremonies],
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
