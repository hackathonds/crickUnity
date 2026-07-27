import 'dart:math';

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

/// PRD §18: "Level N requires 100xN^1.35 cumulative XP (tunable)." E6-01
/// originally stood in a different judgment-call curve here because
/// this exact formula lives in §18 (XP sources & curve), not §13 where
/// E6-01's research was scoped -- corrected during E6-08 (Ranks) once
/// re-reading §18 surfaced the exact PRD answer. No level-gated content
/// (perk unlocks, ceremonies) depended on the old curve's specific
/// thresholds, only on the derived level number, so this is a
/// same-shape swap, not a breaking change.
int _cumulativeXpForLevel(int level) => (100 * pow(level, 1.35)).round();

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

enum CeremonyType { levelUp, badgeUnlock, seasonRollover }

/// DS §5.8's ceremony overlay spec covers both "Achievement/level"
/// events in one motion spec -- badge unlocks (E6-04) and season
/// rollover (E6-09) reuse this same event/queue/suppression mechanism
/// rather than a third/fourth parallel one.
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
