/// PRD §14: "Year in Review: auto-generated December story-format
/// recap: matches, runs/wickets, favorite ground, longest streak, best
/// performance, props received, money fair-share stat ('settled 100%
/// on time'), badges earned -- swipeable, music, one-tap share; every
/// stat card individually excludable before sharing." PRD §18: "<5
/// activities: 'light year' variant."
enum YearInReviewCardType {
  matches,
  runsWickets,
  favoriteGround,
  longestStreak,
  bestPerformance,
  propsReceived,
  moneyFairShare,
  badgesEarned,
}

const Map<YearInReviewCardType, String> yearInReviewCardTitles = {
  YearInReviewCardType.matches: 'Matches played',
  YearInReviewCardType.runsWickets: 'Runs & wickets',
  YearInReviewCardType.favoriteGround: 'Favorite ground',
  YearInReviewCardType.longestStreak: 'Longest streak',
  YearInReviewCardType.bestPerformance: 'Best performance',
  YearInReviewCardType.propsReceived: 'Props received',
  YearInReviewCardType.moneyFairShare: 'Money fair-share',
  YearInReviewCardType.badgesEarned: 'Badges earned',
};

class YearInReviewCard {
  final YearInReviewCardType type;
  final String value;
  final bool isMocked;
  final bool excluded;

  const YearInReviewCard({
    required this.type,
    required this.value,
    this.isMocked = false,
    this.excluded = false,
  });

  YearInReviewCard copyWith({bool? excluded}) {
    return YearInReviewCard(
      type: type,
      value: value,
      isMocked: isMocked,
      excluded: excluded ?? this.excluded,
    );
  }
}
