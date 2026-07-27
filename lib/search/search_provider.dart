import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../clubs/club_provider.dart';
import '../grounds/ground_models.dart' show FacilityAvailability;
import '../grounds/grounds_provider.dart';
import '../moderation/moderation_provider.dart';
import '../social/feed_provider.dart';
import '../social/groups_provider.dart';
import '../teams/selection_board_models.dart';
import '../tournaments/tournament_models.dart';
import '../tournaments/tournaments_provider.dart';
import 'search_filter_models.dart';
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
  final List<SavedFilterSet> savedFilterSets;

  const SearchState({
    this.recentSearches = const [],
    this.savedFilterSets = const [],
  });

  SearchState copyWith({
    List<String>? recentSearches,
    List<SavedFilterSet>? savedFilterSets,
  }) => SearchState(
    recentSearches: recentSearches ?? this.recentSearches,
    savedFilterSets: savedFilterSets ?? this.savedFilterSets,
  );
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
  /// session rather than a mocked combined index. Backlog E12-02:
  /// "Advanced per-type filters" -- each optional filter narrows its
  /// type's results using real fields on the underlying model (see
  /// search_filter_models.dart's top-of-file note for which PRD-named
  /// fields have no backing data yet).
  List<SearchResult> performSearch(
    String query, {
    PlayerFilter? playerFilter,
    TournamentFilter? tournamentFilter,
    GroundFilter? groundFilter,
    PostFilter? postFilter,
  }) {
    if (query.trim().isEmpty) return const [];
    final blocked = ref.read(moderationProvider).blockedNames;

    final results = <SearchResult>[];

    for (final player in mockSelectionPool()) {
      if (blocked.contains(player.name)) continue;
      if (!fuzzyMatches(query, player.name)) continue;
      if (playerFilter?.role != null && player.role != playerFilter!.role) {
        continue;
      }
      results.add(
        SearchResult(
          type: SearchResultType.player,
          id: player.name,
          title: player.name,
          subtitle: 'Player',
        ),
      );
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
      if (!fuzzyMatches(query, tournament.name)) continue;
      if (tournamentFilter != null) {
        if (tournamentFilter.city != null &&
            tournament.city != tournamentFilter.city) {
          continue;
        }
        if (tournamentFilter.format != null &&
            tournament.format != tournamentFilter.format) {
          continue;
        }
        if (tournamentFilter.ballType != null &&
            tournament.ballType != tournamentFilter.ballType) {
          continue;
        }
        if (tournamentFilter.maxEntryFee != null &&
            tournament.entryFee > tournamentFilter.maxEntryFee!) {
          continue;
        }
        if (tournamentFilter.registrationOpenOnly) {
          final deadlinePassed =
              tournament.registrationDeadline != null &&
              DateTime.now().isAfter(tournament.registrationDeadline!);
          if (tournament.registrationMode != RegistrationMode.open ||
              deadlinePassed) {
            continue;
          }
        }
      }
      results.add(
        SearchResult(
          type: SearchResultType.tournament,
          id: tournament.id,
          title: tournament.name,
          subtitle: tournament.city,
        ),
      );
    }

    for (final ground in ref.read(groundsProvider).grounds) {
      if (!fuzzyMatches(query, ground.name) &&
          !fuzzyMatches(query, ground.city)) {
        continue;
      }
      if (groundFilter != null) {
        if (groundFilter.maxDistanceKm != null &&
            ground.distanceKm > groundFilter.maxDistanceKm!) {
          continue;
        }
        if (groundFilter.maxPrice != null &&
            ground.pricePerHour > groundFilter.maxPrice!) {
          continue;
        }
        if (groundFilter.pitchType != null &&
            !ground.pitchTypes.contains(groundFilter.pitchType)) {
          continue;
        }
        if (groundFilter.minRating != null &&
            ground.rating < groundFilter.minRating!) {
          continue;
        }
        if (groundFilter.facilities.isNotEmpty &&
            !groundFilter.facilities.every(
              (f) =>
                  ground.facilities[f] != null &&
                  ground.facilities[f] != FacilityAvailability.no,
            )) {
          continue;
        }
      }
      results.add(
        SearchResult(
          type: SearchResultType.ground,
          id: ground.id,
          title: ground.name,
          subtitle: ground.city,
        ),
      );
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
      if (!fuzzyMatches(query, post.contentText) &&
          !fuzzyMatches(query, post.authorName)) {
        continue;
      }
      if (postFilter != null) {
        if (postFilter.author != null && post.authorName != postFilter.author) {
          continue;
        }
        if (postFilter.hashtag != null &&
            !post.contentText.toLowerCase().contains(
              postFilter.hashtag!.toLowerCase(),
            )) {
          continue;
        }
        if (postFilter.attachedObjectType != null &&
            post.attachedObject?.type != postFilter.attachedObjectType) {
          continue;
        }
        if (postFilter.afterDate != null &&
            post.timestamp.isBefore(postFilter.afterDate!)) {
          continue;
        }
      }
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

  /// Backlog E12-02: "saved filter sets."
  void saveFilterSet(SavedFilterSet filterSet) {
    state = state.copyWith(
      savedFilterSets: [...state.savedFilterSets, filterSet],
    );
  }

  void removeFilterSet(String id) {
    state = state.copyWith(
      savedFilterSets: state.savedFilterSets.where((f) => f.id != id).toList(),
    );
  }
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(
  SearchNotifier.new,
);
