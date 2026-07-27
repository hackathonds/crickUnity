import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../clubs/club_provider.dart';
import '../grounds/grounds_provider.dart';
import '../moderation/moderation_provider.dart';
import '../social/feed_provider.dart';
import '../social/groups_provider.dart';
import '../teams/selection_board_models.dart';
import '../tournaments/tournament_models.dart';
import '../tournaments/tournaments_provider.dart';
import 'search_models.dart';

/// No multi-team directory provider exists anywhere in lib/teams/
/// (confirmed by survey) -- a small named list stands in, same
/// flagged-mock convention as every other missing-directory gap this
/// session, reusing team names already seeded elsewhere (clubs/
/// club_provider.dart's linkedTeamNames/memberClubNames).
const List<String> _mockTeamDirectory = [
  'Strikers CC',
  'Riverside Warriors',
  'City Titans',
];

class SearchState {
  final List<String> recentSearches;

  const SearchState({this.recentSearches = const []});

  SearchState copyWith({List<String>? recentSearches}) =>
      SearchState(recentSearches: recentSearches ?? this.recentSearches);
}

/// Backlog E12-01 -- Global search engine. See search_models.dart's
/// top-of-file note for the exact PRD §16 quote this implements.
class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  void addRecentSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(
      recentSearches: [
        trimmed,
        for (final q in state.recentSearches)
          if (q.toLowerCase() != trimmed.toLowerCase()) q,
      ].take(10).toList(),
    );
  }

  void removeRecentSearch(String query) {
    state = state.copyWith(
      recentSearches: state.recentSearches.where((q) => q != query).toList(),
    );
  }

  void clearRecentSearches() {
    state = state.copyWith(recentSearches: const []);
  }

  /// PRD: "results grouped by type ... respects privacy (blocked users
  /// never appear)." Aggregates across every real module built this
  /// session rather than a mocked combined index.
  List<SearchResult> performSearch(String query) {
    if (query.trim().isEmpty) return const [];
    final blocked = ref.read(moderationProvider).blockedNames;

    final results = <SearchResult>[];

    for (final player in mockSelectionPool()) {
      if (blocked.contains(player.name)) continue;
      if (fuzzyMatches(query, player.name)) {
        results.add(
          SearchResult(
            type: SearchResultType.player,
            id: player.name,
            title: player.name,
            subtitle: 'Player',
          ),
        );
      }
    }

    for (final team in _mockTeamDirectory) {
      if (fuzzyMatches(query, team)) {
        results.add(
          SearchResult(
            type: SearchResultType.team,
            id: team,
            title: team,
            subtitle: 'Team',
          ),
        );
      }
    }

    for (final tournament in ref.read(tournamentsProvider).tournaments) {
      if (tournament.status != TournamentStatus.published) continue;
      if (fuzzyMatches(query, tournament.name)) {
        results.add(
          SearchResult(
            type: SearchResultType.tournament,
            id: tournament.id,
            title: tournament.name,
            subtitle: tournament.city,
          ),
        );
      }
    }

    for (final ground in ref.read(groundsProvider).grounds) {
      if (fuzzyMatches(query, ground.name) ||
          fuzzyMatches(query, ground.city)) {
        results.add(
          SearchResult(
            type: SearchResultType.ground,
            id: ground.id,
            title: ground.name,
            subtitle: ground.city,
          ),
        );
      }
    }

    final club = ref.read(clubProvider).club;
    if (fuzzyMatches(query, club.name)) {
      results.add(
        SearchResult(
          type: SearchResultType.club,
          id: club.id,
          title: club.name,
          subtitle: 'Club',
        ),
      );
    }

    for (final post in ref.read(feedProvider).posts) {
      if (blocked.contains(post.authorName)) continue;
      if (post.deletedAt != null) continue;
      if (fuzzyMatches(query, post.contentText) ||
          fuzzyMatches(query, post.authorName)) {
        results.add(
          SearchResult(
            type: SearchResultType.post,
            id: post.id,
            title: post.contentText.length > 60
                ? '${post.contentText.substring(0, 60)}...'
                : post.contentText,
            subtitle: post.authorName,
          ),
        );
      }
    }

    for (final group in ref.read(groupsProvider).groups) {
      if (fuzzyMatches(query, group.name)) {
        results.add(
          SearchResult(
            type: SearchResultType.group,
            id: group.id,
            title: group.name,
            subtitle: 'Group',
          ),
        );
      }
    }

    return results;
  }
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(
  SearchNotifier.new,
);
