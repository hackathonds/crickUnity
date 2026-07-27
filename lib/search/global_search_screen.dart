import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_search_bar.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../grounds/ground_models.dart';
import '../grounds/grounds_provider.dart';
import '../onboarding/profile_wizard_provider.dart' show PrimaryRole;
import '../social/feed_models.dart'
    show AttachedObjectType, attachedObjectTypeLabels;
import '../teams/selection_board_models.dart';
import '../tournaments/tournament_models.dart';
import '../tournaments/tournaments_provider.dart';
import 'qr_scanner_screen.dart';
import 'search_filter_models.dart';
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
  PlayerFilter? _playerFilter;
  TournamentFilter? _tournamentFilter;
  GroundFilter? _groundFilter;
  PostFilter? _postFilter;

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

  /// Backlog E12-02: "filter sheet per type." One sheet, a type
  /// selector at top, only the fields with real backing data enabled
  /// per type (see search_filter_models.dart's top-of-file note).
  void _showAdvancedFiltersSheet(BuildContext context) {
    SearchResultType selectedType = SearchResultType.tournament;
    PlayerFilter draftPlayer = _playerFilter ?? const PlayerFilter();
    TournamentFilter draftTournament =
        _tournamentFilter ?? const TournamentFilter();
    GroundFilter draftGround = _groundFilter ?? const GroundFilter();
    PostFilter draftPost = _postFilter ?? const PostFilter();
    final nameController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Advanced filters', style: AppTypography.h2),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final type in [
                      SearchResultType.player,
                      SearchResultType.team,
                      SearchResultType.tournament,
                      SearchResultType.ground,
                      SearchResultType.club,
                      SearchResultType.post,
                    ])
                      ChoiceChip(
                        key: ValueKey('filterTypeChip_${type.name}'),
                        label: Text(searchResultTypeLabels[type]!),
                        selected: selectedType == type,
                        onSelected: (_) =>
                            setSheetState(() => selectedType = type),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (selectedType == SearchResultType.player) ...[
                  Text('Role', style: AppTypography.label),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      for (final role in PrimaryRole.values)
                        ChoiceChip(
                          label: Text(role.name),
                          selected: draftPlayer.role == role,
                          onSelected: (_) => setSheetState(
                            () => draftPlayer = PlayerFilter(
                              role: draftPlayer.role == role ? null : role,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Text(
                    'Batting/bowling style, city+radius, age band, rating range, '
                    'Trust band, free-agent, and availability-day filters await a '
                    'real player-profile model (not yet built).',
                  ),
                ] else if (selectedType == SearchResultType.team)
                  const Text(
                    'No team directory exists yet beyond names (flagged) -- '
                    'city/format/recruiting-now/activity-level/follower-count '
                    'filters are not yet available.',
                  )
                else if (selectedType == SearchResultType.tournament) ...[
                  Text('Format', style: AppTypography.label),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      for (final format in TournamentFormat.values)
                        ChoiceChip(
                          label: Text(tournamentFormatLabels[format]!),
                          selected: draftTournament.format == format,
                          onSelected: (_) => setSheetState(
                            () => draftTournament = TournamentFilter(
                              city: draftTournament.city,
                              format: draftTournament.format == format
                                  ? null
                                  : format,
                              ballType: draftTournament.ballType,
                              maxEntryFee: draftTournament.maxEntryFee,
                              registrationOpenOnly:
                                  draftTournament.registrationOpenOnly,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text('Ball', style: AppTypography.label),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      for (final ball in TournamentBallType.values)
                        ChoiceChip(
                          label: Text(tournamentBallTypeLabels[ball]!),
                          selected: draftTournament.ballType == ball,
                          onSelected: (_) => setSheetState(
                            () => draftTournament = TournamentFilter(
                              city: draftTournament.city,
                              format: draftTournament.format,
                              ballType: draftTournament.ballType == ball
                                  ? null
                                  : ball,
                              maxEntryFee: draftTournament.maxEntryFee,
                              registrationOpenOnly:
                                  draftTournament.registrationOpenOnly,
                            ),
                          ),
                        ),
                    ],
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Registration open only'),
                    value: draftTournament.registrationOpenOnly,
                    onChanged: (v) => setSheetState(
                      () => draftTournament = TournamentFilter(
                        city: draftTournament.city,
                        format: draftTournament.format,
                        ballType: draftTournament.ballType,
                        maxEntryFee: draftTournament.maxEntryFee,
                        registrationOpenOnly: v ?? false,
                      ),
                    ),
                  ),
                  const Text(
                    'City filter and organizer-score filter await richer real data -- flagged.',
                  ),
                ] else if (selectedType == SearchResultType.ground) ...[
                  Text('Pitch type', style: AppTypography.label),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      for (final pitch in PitchType.values)
                        ChoiceChip(
                          label: Text(pitchTypeLabels[pitch]!),
                          selected: draftGround.pitchType == pitch,
                          onSelected: (_) => setSheetState(
                            () => draftGround = GroundFilter(
                              maxDistanceKm: draftGround.maxDistanceKm,
                              maxPrice: draftGround.maxPrice,
                              pitchType: draftGround.pitchType == pitch
                                  ? null
                                  : pitch,
                              facilities: draftGround.facilities,
                              minRating: draftGround.minRating,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text('Facilities', style: AppTypography.label),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      for (final facility in Facility.values)
                        FilterChip(
                          label: Text(facilityLabels[facility]!),
                          selected: draftGround.facilities.contains(facility),
                          onSelected: (_) => setSheetState(() {
                            final updated = {...draftGround.facilities};
                            if (!updated.add(facility)) {
                              updated.remove(facility);
                            }
                            draftGround = GroundFilter(
                              maxDistanceKm: draftGround.maxDistanceKm,
                              maxPrice: draftGround.maxPrice,
                              pitchType: draftGround.pitchType,
                              facilities: updated,
                              minRating: draftGround.minRating,
                            );
                          }),
                        ),
                    ],
                  ),
                ] else if (selectedType == SearchResultType.club)
                  const Text(
                    'Club has no city/membership-open/teams-count field yet '
                    '(flagged) -- no club filters are available.',
                  )
                else if (selectedType == SearchResultType.post) ...[
                  Text('Attached object type', style: AppTypography.label),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      for (final type in AttachedObjectType.values)
                        ChoiceChip(
                          label: Text(attachedObjectTypeLabels[type]!),
                          selected: draftPost.attachedObjectType == type,
                          onSelected: (_) => setSheetState(
                            () => draftPost = PostFilter(
                              author: draftPost.author,
                              hashtag: draftPost.hashtag,
                              attachedObjectType:
                                  draftPost.attachedObjectType == type
                                  ? null
                                  : type,
                              afterDate: draftPost.afterDate,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Text(
                    'Author/hashtag/date filters use the same search field -- author/date pickers await a future pass.',
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Save this filter set as...',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        variant: AppButtonVariant.secondary,
                        label: 'Save',
                        fullWidth: true,
                        onPressed: nameController.text.trim().isEmpty
                            ? null
                            : () {
                                ref
                                    .read(searchProvider.notifier)
                                    .saveFilterSet(
                                      SavedFilterSet(
                                        id: 'filterset-${DateTime.now().microsecondsSinceEpoch}',
                                        name: nameController.text.trim(),
                                        playerFilter:
                                            selectedType ==
                                                SearchResultType.player
                                            ? draftPlayer
                                            : null,
                                        tournamentFilter:
                                            selectedType ==
                                                SearchResultType.tournament
                                            ? draftTournament
                                            : null,
                                        groundFilter:
                                            selectedType ==
                                                SearchResultType.ground
                                            ? draftGround
                                            : null,
                                        postFilter:
                                            selectedType ==
                                                SearchResultType.post
                                            ? draftPost
                                            : null,
                                      ),
                                    );
                              },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        key: const ValueKey('applyFiltersButton'),
                        variant: AppButtonVariant.primary,
                        label: 'Apply',
                        fullWidth: true,
                        onPressed: () {
                          setState(() {
                            _playerFilter = draftPlayer;
                            _tournamentFilter = draftTournament;
                            _groundFilter = draftGround;
                            _postFilter = draftPost;
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final searchState = ref.watch(searchProvider);
    final notifier = ref.read(searchProvider.notifier);
    final results = _query.isEmpty
        ? const <SearchResult>[]
        : notifier.performSearch(
            _query,
            playerFilter: _playerFilter,
            tournamentFilter: _tournamentFilter,
            groundFilter: _groundFilter,
            postFilter: _postFilter,
          );
    final grouped = <SearchResultType, List<SearchResult>>{};
    for (final r in results) {
      grouped.putIfAbsent(r.type, () => []).add(r);
    }
    final hasActiveFilters =
        (_playerFilter?.isEmpty == false) ||
        (_tournamentFilter?.isEmpty == false) ||
        (_groundFilter?.isEmpty == false) ||
        (_postFilter?.isEmpty == false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        actions: [
          IconButton(
            key: const ValueKey('advancedFiltersButton'),
            icon: Icon(
              hasActiveFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
            tooltip: 'Advanced filters',
            onPressed: () => _showAdvancedFiltersSheet(context),
          ),
        ],
      ),
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
              onQrTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QrScannerScreen()),
              ),
            ),
            if (searchState.savedFilterSets.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final saved in searchState.savedFilterSets)
                    InputChip(
                      key: ValueKey('savedFilterSetChip_${saved.id}'),
                      label: Text(saved.name),
                      onPressed: () => setState(() {
                        _playerFilter = saved.playerFilter ?? _playerFilter;
                        _tournamentFilter =
                            saved.tournamentFilter ?? _tournamentFilter;
                        _groundFilter = saved.groundFilter ?? _groundFilter;
                        _postFilter = saved.postFilter ?? _postFilter;
                      }),
                      onDeleted: () => ref
                          .read(searchProvider.notifier)
                          .removeFilterSet(saved.id),
                    ),
                ],
              ),
            ],
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
