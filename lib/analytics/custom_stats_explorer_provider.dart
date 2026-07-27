import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'custom_stats_explorer_models.dart';

class CustomStatsExplorerState {
  final List<SavedQuery> savedQueries;
  final List<SavedQuery> pinnedWidgets;

  const CustomStatsExplorerState({
    this.savedQueries = const [],
    this.pinnedWidgets = const [],
  });

  CustomStatsExplorerState copyWith({
    List<SavedQuery>? savedQueries,
    List<SavedQuery>? pinnedWidgets,
  }) {
    return CustomStatsExplorerState(
      savedQueries: savedQueries ?? this.savedQueries,
      pinnedWidgets: pinnedWidgets ?? this.pinnedWidgets,
    );
  }
}

/// DS §7.10 screen 68: "[Save query][Pin as widget]." Saved queries and
/// pinned widgets are session-local state (no backend query-storage
/// service exists) -- same convention as every other missing-persistence
/// gap this session.
class CustomStatsExplorerNotifier extends Notifier<CustomStatsExplorerState> {
  @override
  CustomStatsExplorerState build() => const CustomStatsExplorerState();

  void saveQuery(
    String name,
    StatsDiscipline discipline,
    StatsQueryFilters filters,
  ) {
    final query = SavedQuery(
      id: 'query-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      discipline: discipline,
      filters: filters,
    );
    state = state.copyWith(savedQueries: [query, ...state.savedQueries]);
  }

  void pinAsWidget(
    String name,
    StatsDiscipline discipline,
    StatsQueryFilters filters,
  ) {
    final query = SavedQuery(
      id: 'widget-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      discipline: discipline,
      filters: filters,
    );
    state = state.copyWith(pinnedWidgets: [query, ...state.pinnedWidgets]);
  }

  void unpinWidget(String id) {
    state = state.copyWith(
      pinnedWidgets: state.pinnedWidgets.where((w) => w.id != id).toList(),
    );
  }
}

final customStatsExplorerProvider =
    NotifierProvider<CustomStatsExplorerNotifier, CustomStatsExplorerState>(
      CustomStatsExplorerNotifier.new,
    );
