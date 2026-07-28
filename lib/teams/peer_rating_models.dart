/// PRD §6.27: "Internal post-match peer ratings (optional, anonymous, 1-5
/// stars + tags) roll into a private 'coach's view' for Captain; individual
/// raters never revealed; visible to rated player only as aggregate after
/// >=3 raters (anti-identification rule)."
/// PRD §7.20: "Peer ratings window opens 1h post-match for 48h."
library;

/// Anti-identification rule: below this many raters, nothing but the count
/// itself may be shown.
const int peerRatingAnonymityThreshold = 3;

/// No canonical tag vocabulary is given anywhere in the frozen docs (PRD
/// only says "1-5 stars + tags") -- a small illustrative set, same
/// open-question treatment as style tags (E2-04's `availableStyleTags`).
const List<String> peerRatingTags = [
  'Great communicator',
  'Reliable',
  'Team player',
  'Clutch under pressure',
  'Brings energy',
];

class PeerRatingWindow {
  final DateTime opensAt;
  final DateTime closesAt;

  const PeerRatingWindow({required this.opensAt, required this.closesAt});

  bool isOpenAt(DateTime now) => now.isAfter(opensAt) && now.isBefore(closesAt);

  bool hasClosedAt(DateTime now) => now.isAfter(closesAt);
}

/// PRD §7.20: window opens 1h post-scorecard, stays open 48h.
PeerRatingWindow peerRatingWindowFor(DateTime scorecardPostedAt) {
  final opensAt = scorecardPostedAt.add(const Duration(hours: 1));
  return PeerRatingWindow(
    opensAt: opensAt,
    closesAt: opensAt.add(const Duration(hours: 48)),
  );
}

/// One rater's private ballot for one teammate. [raterName] is kept only to
/// make submission idempotent and to count toward the anonymity threshold --
/// it must never surface in any UI or aggregate (PRD's anti-identification
/// rule): no screen in this feature may read this field back out.
class PeerRating {
  final String raterName;
  final String ratedPlayerName;
  final int stars;
  final List<String> tags;

  const PeerRating({
    required this.raterName,
    required this.ratedPlayerName,
    required this.stars,
    this.tags = const [],
  });
}

/// What a rated player (or their captain) is allowed to see. Below
/// [peerRatingAnonymityThreshold] raters, only [ratersCount] is exposed --
/// no average, no tags, and never a rater name.
class AggregatedPlayerRating {
  final String playerName;
  final int ratersCount;
  final double? averageStars;
  final List<String> topTags;

  const AggregatedPlayerRating({
    required this.playerName,
    required this.ratersCount,
    this.averageStars,
    this.topTags = const [],
  });

  bool get isRevealed => ratersCount >= peerRatingAnonymityThreshold;
}

/// Pure aggregation -- never returns anything that lets a caller trace a
/// rating back to its rater.
AggregatedPlayerRating aggregateRatingsFor(
  String playerName,
  List<PeerRating> allRatings,
) {
  final forPlayer = allRatings
      .where((r) => r.ratedPlayerName == playerName)
      .toList();

  if (forPlayer.length < peerRatingAnonymityThreshold) {
    return AggregatedPlayerRating(
      playerName: playerName,
      ratersCount: forPlayer.length,
    );
  }

  final average =
      forPlayer.map((r) => r.stars).reduce((a, b) => a + b) / forPlayer.length;

  final tagCounts = <String, int>{};
  for (final rating in forPlayer) {
    for (final tag in rating.tags) {
      tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
    }
  }
  final sortedTags = tagCounts.keys.toList()
    ..sort((a, b) => tagCounts[b]!.compareTo(tagCounts[a]!));

  return AggregatedPlayerRating(
    playerName: playerName,
    ratersCount: forPlayer.length,
    averageStars: average,
    topTags: sortedTags.take(3).toList(),
  );
}
