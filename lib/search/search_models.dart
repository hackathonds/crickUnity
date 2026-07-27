/// PRD §16 (Search): "Global Search (top bar/launcher): single field;
/// results grouped by type (Players, Teams, Tournaments, Grounds,
/// Clubs, Posts, Groups) with 'See all {type}'; typo-tolerant; respects
/// privacy (private profiles show minimal card; blocked users never
/// appear). Zero-state: Recent searches (removable, 'clear all'),
/// Suggestions (people you may know, your grounds), Trending in your
/// city (tournaments, hashtags)."
///
/// No per-profile privacy-setting model exists yet (that's E16-01
/// Privacy Center's job) -- "private profiles show minimal card" is
/// flagged as not yet implementable; the one privacy rule with real
/// state this story enforces is blocked-user exclusion
/// (moderation/moderation_provider.dart's blockedNames, E7-07).
library;

enum SearchResultType { player, team, tournament, ground, club, post, group }

const Map<SearchResultType, String> searchResultTypeLabels = {
  SearchResultType.player: 'Players',
  SearchResultType.team: 'Teams',
  SearchResultType.tournament: 'Tournaments',
  SearchResultType.ground: 'Grounds',
  SearchResultType.club: 'Clubs',
  SearchResultType.post: 'Posts',
  SearchResultType.group: 'Groups',
};

class SearchResult {
  final SearchResultType type;
  final String id;
  final String title;
  final String subtitle;

  const SearchResult({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
  });
}

/// PRD: "typo-tolerant." No exact algorithm is given -- a flagged
/// judgment call: case-insensitive substring match, or (for queries of
/// 4+ characters) a within-1-edit fuzzy match against any word in the
/// target, so a single typo/transposition still surfaces the result.
bool fuzzyMatches(String query, String target) {
  final q = query.trim().toLowerCase();
  final t = target.toLowerCase();
  if (q.isEmpty) return false;
  if (t.contains(q)) return true;
  if (q.length < 4) return false;
  for (final word in t.split(RegExp(r'\s+'))) {
    if (_levenshtein(q, word) <= 1) return true;
  }
  return false;
}

int _levenshtein(String a, String b) {
  final la = a.length, lb = b.length;
  if (la == 0) return lb;
  if (lb == 0) return la;
  var prev = List<int>.generate(lb + 1, (j) => j);
  for (var i = 1; i <= la; i++) {
    final current = List<int>.filled(lb + 1, 0);
    current[0] = i;
    for (var j = 1; j <= lb; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      current[j] = [
        current[j - 1] + 1,
        prev[j] + 1,
        prev[j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
    }
    prev = current;
  }
  return prev[lb];
}
