/// PRD §13.1: "Earning table (canonical, Super-Admin tunable; values
/// indicative)." Only the match-derived rows are in scope for E6-01 --
/// "release gated on scorecard confirmation" ties this story
/// specifically to match completion; daily logins/missions/practice
/// attendance are E6-02/E6-03's separate stories.
enum EarningAction {
  playVerifiedMatch,
  benchOrTwelfth,
  winBonus,
  fifty,
  century,
  threeWickets,
  fiveWickets,
  mvp,
  scorerMatch,
  scorerZeroDisputes,
  umpireMatch,
  organizeMatch,
  volunteerDuty,
  dailyLogin,
  referral,
}

class EarningReward {
  final int coins;
  final int xp;

  const EarningReward(this.coins, this.xp);
}

const Map<EarningAction, EarningReward> earningTable = {
  EarningAction.playVerifiedMatch: EarningReward(20, 50),
  EarningAction.benchOrTwelfth: EarningReward(10, 25),
  EarningAction.winBonus: EarningReward(10, 20),
  EarningAction.fifty: EarningReward(25, 60),
  EarningAction.century: EarningReward(75, 150),
  EarningAction.threeWickets: EarningReward(25, 60),
  EarningAction.fiveWickets: EarningReward(75, 150),
  EarningAction.mvp: EarningReward(40, 100),
  EarningAction.scorerMatch: EarningReward(30, 60),
  EarningAction.scorerZeroDisputes: EarningReward(10, 0),
  EarningAction.umpireMatch: EarningReward(30, 60),
  EarningAction.organizeMatch: EarningReward(15, 30),
  EarningAction.volunteerDuty: EarningReward(5, 10),
  EarningAction.dailyLogin: EarningReward(2, 2),
  EarningAction.referral: EarningReward(100, 100),
};

const Map<EarningAction, String> earningActionLabels = {
  EarningAction.playVerifiedMatch: 'Played a verified match',
  EarningAction.benchOrTwelfth: 'Bench/12th man',
  EarningAction.winBonus: 'Win bonus',
  EarningAction.fifty: 'Fifty',
  EarningAction.century: 'Century',
  EarningAction.threeWickets: '3-wicket haul',
  EarningAction.fiveWickets: '5-wicket haul',
  EarningAction.mvp: 'MVP',
  EarningAction.scorerMatch: 'Scored the match',
  EarningAction.scorerZeroDisputes: 'Zero-dispute scoring bonus',
  EarningAction.umpireMatch: 'Umpired the match',
  EarningAction.organizeMatch: 'Organized the match',
  EarningAction.volunteerDuty: 'Volunteer duty',
  EarningAction.dailyLogin: 'Daily login',
  EarningAction.referral: 'Referral bonus',
};

/// PRD §13: "Level (1-60, curve steepens)." No exact formula is given
/// (the earning table itself is explicitly "indicative, Super-Admin
/// tunable") -- a standard steepening curve stands in, documented as a
/// judgment call: level n requires n*(n+1)/2*50 cumulative XP (each
/// level costs 50 XP more than the last).
int _cumulativeXpForLevel(int level) => 50 * level * (level + 1) ~/ 2;

const int maxLevel = 60;

int levelForXp(int totalXp) {
  var level = 1;
  while (level < maxLevel && totalXp >= _cumulativeXpForLevel(level + 1)) {
    level++;
  }
  return level;
}

int xpIntoCurrentLevel(int totalXp) {
  final level = levelForXp(totalXp);
  return totalXp - _cumulativeXpForLevel(level);
}

int xpNeededForNextLevel(int totalXp) {
  final level = levelForXp(totalXp);
  if (level >= maxLevel) return 0;
  return _cumulativeXpForLevel(level + 1) - _cumulativeXpForLevel(level);
}

double levelProgress(int totalXp) {
  final needed = xpNeededForNextLevel(totalXp);
  if (needed == 0) return 1.0;
  return xpIntoCurrentLevel(totalXp) / needed;
}

enum CeremonyType { levelUp, badgeUnlock }

/// DS §5.8's ceremony overlay spec covers both "Achievement/level"
/// events in one motion spec -- badge unlocks (E6-04) reuse this same
/// event/queue/suppression mechanism rather than a second parallel one.
class CeremonyEvent {
  final CeremonyType type;
  final int? level;
  final String? badgeName;
  final String? tierLabel;

  const CeremonyEvent({
    required this.type,
    this.level,
    this.badgeName,
    this.tierLabel,
  });
}

/// PRD §13.1: "Coins (spendable; expire 12 months after earning, FIFO
/// burn; expiry warnings at 30/7 days)." Coins are tracked as dated
/// batches rather than one flat int so FIFO burn/expiry is real, not
/// just a balance decrement.
class CoinBatch {
  final int amount;
  final int remaining;
  final DateTime earnedAt;

  const CoinBatch({
    required this.amount,
    required this.remaining,
    required this.earnedAt,
  });

  DateTime get expiresAt =>
      DateTime(earnedAt.year, earnedAt.month + 12, earnedAt.day);

  CoinBatch copyWith({int? remaining}) => CoinBatch(
    amount: amount,
    remaining: remaining ?? this.remaining,
    earnedAt: earnedAt,
  );
}

/// PRD §13.1's "expiry warnings at 30/7 days" -- coins from the
/// earliest (FIFO) batches whose 12-month expiry falls within [days].
int coinsExpiringWithin(
  List<CoinBatch> batches,
  int days, {
  DateTime Function() now = DateTime.now,
}) {
  final cutoff = now().add(Duration(days: days));
  return batches
      .where((b) => b.remaining > 0 && !b.expiresAt.isAfter(cutoff))
      .fold(0, (sum, b) => sum + b.remaining);
}
