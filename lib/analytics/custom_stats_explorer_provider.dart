import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
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

  Map<String, dynamic> toJson() => {
    'savedQueries': [for (final q in savedQueries) q.toJson()],
    'pinnedWidgets': [for (final w in pinnedWidgets) w.toJson()],
  };

  factory CustomStatsExplorerState.fromJson(Map<String, dynamic> json) {
    return CustomStatsExplorerState(
      savedQueries: [
        for (final q in json['savedQueries'] as List)
          SavedQuery.fromJson(q as Map<String, dynamic>),
      ],
      pinnedWidgets: [
        for (final w in json['pinnedWidgets'] as List)
          SavedQuery.fromJson(w as Map<String, dynamic>),
      ],
    );
  }
}

/// DS §7.10 screen 68: "[Save query][Pin as widget]."
class CustomStatsExplorerNotifier
    extends PersistedNotifier<CustomStatsExplorerState> {
  @override
  String get persistenceKey => 'custom_stats_explorer_v1';

  @override
  CustomStatsExplorerState seed() => const CustomStatsExplorerState();

  @override
  Map<String, dynamic> toJson(CustomStatsExplorerState value) => value.toJson();

  @override
  CustomStatsExplorerState fromJson(Map<String, dynamic> json) =>
      CustomStatsExplorerState.fromJson(json);

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
