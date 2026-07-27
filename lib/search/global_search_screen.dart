import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_search_bar.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../grounds/grounds_provider.dart';
import '../teams/selection_board_models.dart';
import '../tournaments/tournament_models.dart';
import '../tournaments/tournaments_provider.dart';
import 'search_models.dart';
import 'search_provider.dart';

/// PRD §16 (Search): Global Search with grouped results + zero-state.
/// See search_models.dart's top-of-file note for the exact quote and
/// the flagged private-profile gap. Reuses the existing AppSearchBar
/// component (built ahead of this epic, its own doc comment already
/// anticipates E12) for the field itself.
class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  String _query = '';
  final Set<SearchResultType> _expanded = {};

  // PRD zero-state: "Trending in your city (tournaments, hashtags)."
  // No real hashtag-trending computation exists (flagged, same
  // convention as every other missing-analytics-pipeline gap) --
  // tournaments reuse the real tournamentsProvider list; hashtags are
  // a small flagged mock.
  static const _trendingHashtags = [
    '#MonsoonCup',
    '#SundayLeague',
    '#NetSessions',
  ];

  void _runSearch(String query) {
    setState(() => _query = query);
    ref.read(searchProvider.notifier).addRecentSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final searchState = ref.watch(searchProvider);
    final notifier = ref.read(searchProvider.notifier);
    final results = _query.isEmpty
        ? const <SearchResult>[]
        : notifier.performSearch(_query);
    final grouped = <SearchResultType, List<SearchResult>>{};
    for (final r in results) {
      grouped.putIfAbsent(r.type, () => []).add(r);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSearchBar(
              hintText: 'Search players, teams, tournaments...',
              recentSearches: searchState.recentSearches,
              onSubmit: _runSearch,
              onRecentTap: _runSearch,
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: _query.isEmpty
                  ? _ZeroState(
                      recentSearches: searchState.recentSearches,
                      trendingHashtags: _trendingHashtags,
                      colors: colors,
                      onRecentTap: _runSearch,
                      onRemoveRecent: notifier.removeRecentSearch,
                      onClearAll: notifier.clearRecentSearches,
                    )
                  : results.isEmpty
                  ? Center(
                      child: Text(
                        'No results for "$_query".',
                        style: AppTypography.body.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    )
                  : ListView(
                      children: [
                        for (final type in SearchResultType.values)
                          if (grouped[type] != null)
                            _ResultGroup(
                              key: ValueKey('resultGroup_${type.name}'),
                              type: type,
                              results: grouped[type]!,
                              expanded: _expanded.contains(type),
                              onToggleExpand: () => setState(() {
                                if (!_expanded.add(type)) {
                                  _expanded.remove(type);
                                }
                              }),
                              colors: colors,
                            ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultGroup extends StatelessWidget {
  final SearchResultType type;
  final List<SearchResult> results;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final AppColors colors;

  const _ResultGroup({
    super.key,
    required this.type,
    required this.results,
    required this.expanded,
    required this.onToggleExpand,
    required this.colors,
  });

  static const int _collapsedCount = 3;

  @override
  Widget build(BuildContext context) {
    final shown = expanded ? results : results.take(_collapsedCount).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${searchResultTypeLabels[type]} (${results.length})',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final result in shown)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.title,
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    result.subtitle,
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          if (results.length > _collapsedCount)
            TextButton(
              key: ValueKey('seeAllButton_${type.name}'),
              onPressed: onToggleExpand,
              child: Text(
                expanded
                    ? 'Show less'
                    : 'See all ${searchResultTypeLabels[type]}',
              ),
            ),
        ],
      ),
    );
  }
}

class _ZeroState extends ConsumerWidget {
  final List<String> recentSearches;
  final List<String> trendingHashtags;
  final AppColors colors;
  final ValueChanged<String> onRecentTap;
  final ValueChanged<String> onRemoveRecent;
  final VoidCallback onClearAll;

  const _ZeroState({
    required this.recentSearches,
    required this.trendingHashtags,
    required this.colors,
    required this.onRecentTap,
    required this.onRemoveRecent,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myGrounds = [...ref.watch(groundsProvider).grounds]
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    final suggestedPeople = mockSelectionPool().take(3).toList();
    final trendingTournaments = ref
        .watch(tournamentsProvider)
        .tournaments
        .where((t) => t.status == TournamentStatus.published)
        .take(3)
        .toList();

    return ListView(
      children: [
        if (recentSearches.isNotEmpty) ...[
          Row(
            children: [
              Expanded(child: Text('Recent searches', style: AppTypography.h2)),
              TextButton(
                key: const ValueKey('clearAllRecentSearchesButton'),
                onPressed: onClearAll,
                child: const Text('Clear all'),
              ),
            ],
          ),
          for (final recent in recentSearches)
            ListTile(
              key: ValueKey('recentSearchRow_$recent'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history),
              title: Text(recent),
              trailing: IconButton(
                key: ValueKey('removeRecentSearchButton_$recent'),
                icon: const Icon(Icons.close),
                onPressed: () => onRemoveRecent(recent),
              ),
              onTap: () => onRecentTap(recent),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text('Suggestions', style: AppTypography.h2),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'People you may know',
          style: AppTypography.label.copyWith(color: colors.textTertiary),
        ),
        for (final person in suggestedPeople)
          Text(
            person.name,
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Your grounds',
          style: AppTypography.label.copyWith(color: colors.textTertiary),
        ),
        for (final ground in myGrounds.take(2))
          Text(
            '${ground.name} · ${ground.distanceKm.toStringAsFixed(1)} km',
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
        const SizedBox(height: AppSpacing.lg),
        Text('Trending in your city', style: AppTypography.h2),
        const SizedBox(height: AppSpacing.xs),
        for (final tournament in trendingTournaments)
          Text(
            tournament.name,
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final tag in trendingHashtags) Chip(label: Text(tag)),
          ],
        ),
      ],
    );
  }
}
