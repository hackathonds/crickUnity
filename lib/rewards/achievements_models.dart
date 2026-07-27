/// E6-04 (Badge engine + celebrations). PRD §13.3: "Milestones: career
/// counters (100 matches, 1,000 runs, 100 wickets, 50 matches scored, 25
/// grounds visited) -> permanent badges + coin chest + timeline entry +
/// shareable card." Only 3 of `lib/profile/achievement_models.dart`'s 10
/// mock badges (E2-05) are naturally countable from state this session
/// already tracks -- those 3 get a real tiered engine; the other 7 stay
/// static mock badges (Century Club, Hat-trick Hero, etc. have no
/// counter-producing module yet, same flagged-mock convention as
/// elsewhere).
enum TieredBadgeId { ironPlayer, scorerSupreme, groundCollector }

const Map<TieredBadgeId, String> tieredBadgeNames = {
  TieredBadgeId.ironPlayer: 'Iron Player',
  TieredBadgeId.scorerSupreme: 'Scorer Supreme',
  TieredBadgeId.groundCollector: 'Ground Collector',
};

class BadgeTier {
  final String label;
  final int threshold;

  const BadgeTier(this.label, this.threshold);
}

/// Iron Player: PRD §13.2's exact playing-streak milestone weeks
/// (4/12/26/52), same tiers E6-02's streaks engine already fires chests
/// at -- reused, not reinvented.
/// Scorer Supreme: PRD §2.6's exact "Verified Scorer" badge tiers --
/// Bronze(10)/Silver(50)/Gold(150)/Platinum(500) dispute-free-scored
/// matches.
/// Ground Collector: PRD §13.3 names one milestone number (25 grounds),
/// not a tier ladder -- Bronze/Silver/Gold subdividing it is a judgment
/// call, flagged. No Ground/booking module exists to count real visits
/// from, so this counter only advances via a manual debug control.
const Map<TieredBadgeId, List<BadgeTier>> badgeTiers = {
  TieredBadgeId.ironPlayer: [
    BadgeTier('Bronze', 4),
    BadgeTier('Silver', 12),
    BadgeTier('Gold', 26),
    BadgeTier('Platinum', 52),
  ],
  TieredBadgeId.scorerSupreme: [
    BadgeTier('Bronze', 10),
    BadgeTier('Silver', 50),
    BadgeTier('Gold', 150),
    BadgeTier('Platinum', 500),
  ],
  TieredBadgeId.groundCollector: [
    BadgeTier('Bronze', 5),
    BadgeTier('Silver', 15),
    BadgeTier('Gold', 25),
  ],
};

/// currentTierIndex -1 means no tier earned yet. history keeps every
/// tier-up (never overwritten), so a player's climb from Bronze to
/// Platinum stays visible, not just the latest tier.
class TieredBadgeProgress {
  final int counter;
  final int currentTierIndex;
  final List<String> history;

  const TieredBadgeProgress({
    this.counter = 0,
    this.currentTierIndex = -1,
    this.history = const [],
  });

  BadgeTier? tierAt(TieredBadgeId id) =>
      currentTierIndex < 0 ? null : badgeTiers[id]![currentTierIndex];

  BadgeTier? nextTierFor(TieredBadgeId id) {
    final tiers = badgeTiers[id]!;
    final nextIndex = currentTierIndex + 1;
    return nextIndex >= tiers.length ? null : tiers[nextIndex];
  }
}
