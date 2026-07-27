/// PRD §13.2: "Season rewards: end-of-season tier (Bronze->Legend by
/// season XP) with exclusive profile frames." PRD names only the two
/// endpoints (Bronze, Legend) -- the intermediate tiers and their XP
/// thresholds are a flagged judgment call.
enum SeasonTier { bronze, silver, gold, platinum, diamond, legend }

const Map<SeasonTier, String> seasonTierLabels = {
  SeasonTier.bronze: 'Bronze',
  SeasonTier.silver: 'Silver',
  SeasonTier.gold: 'Gold',
  SeasonTier.platinum: 'Platinum',
  SeasonTier.diamond: 'Diamond',
  SeasonTier.legend: 'Legend',
};

const Map<SeasonTier, String> seasonTierFrames = {
  SeasonTier.bronze: 'Bronze Laurel frame',
  SeasonTier.silver: 'Silver Laurel frame',
  SeasonTier.gold: 'Gold Laurel frame',
  SeasonTier.platinum: 'Platinum Arc frame',
  SeasonTier.diamond: 'Diamond Arc frame',
  SeasonTier.legend: 'Legend Crest frame',
};

const List<(SeasonTier, int)> seasonTierThresholds = [
  (SeasonTier.legend, 5000),
  (SeasonTier.diamond, 3000),
  (SeasonTier.platinum, 1800),
  (SeasonTier.gold, 900),
  (SeasonTier.silver, 400),
  (SeasonTier.bronze, 0),
];

SeasonTier seasonTierForXp(int seasonXp) {
  for (final (tier, threshold) in seasonTierThresholds) {
    if (seasonXp >= threshold) return tier;
  }
  return SeasonTier.bronze;
}

SeasonTier? nextSeasonTierAfter(SeasonTier tier) {
  final tiers = SeasonTier.values;
  final index = tiers.indexOf(tier);
  return index >= tiers.length - 1 ? null : tiers[index + 1];
}

int thresholdFor(SeasonTier tier) =>
    seasonTierThresholds.firstWhere((e) => e.$1 == tier).$2;
