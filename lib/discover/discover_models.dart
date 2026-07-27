/// DS §11.12 (Discover lane & Gear marketplace): "Discover: editorial
/// cards (tip/rules/news templates), tip cards carry [Add drill] chip
/// deep-linking Drill Library; strictly separate scroll from Feed (PRD
/// rule), sponsored-education label style per 11.9."
/// Backlog cites this story against "G.6" -- no Appendix G exists
/// anywhere in the frozen PRD (only A and B are real, established
/// earlier this session), flagged rather than guessed at.
library;

enum DiscoverCardType { tip, rules, news }

const Map<DiscoverCardType, String> discoverCardTypeLabels = {
  DiscoverCardType.tip: 'Tip',
  DiscoverCardType.rules: 'Rules',
  DiscoverCardType.news: 'News',
};

class DiscoverCard {
  final DiscoverCardType type;
  final String title;
  final String body;

  /// Only tip cards deep-link to a drill -- null for rules/news
  /// templates.
  final String? linkedDrillId;

  final bool sponsored;
  final String? sponsorName;

  const DiscoverCard({
    required this.type,
    required this.title,
    required this.body,
    this.linkedDrillId,
    this.sponsored = false,
    this.sponsorName,
  });
}
