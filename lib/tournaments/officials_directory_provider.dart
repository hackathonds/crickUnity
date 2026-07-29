import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'officials_directory_models.dart';

class OfficialsDirectoryState {
  final List<DirectoryOfficial> roster;
  final OfficialsDirectoryFilters filters;

  const OfficialsDirectoryState({
    this.roster = const [],
    this.filters = const OfficialsDirectoryFilters(),
  });

  List<DirectoryOfficial> get filtered =>
      roster.where(filters.matches).toList();

  OfficialsDirectoryState copyWith({
    List<DirectoryOfficial>? roster,
    OfficialsDirectoryFilters? filters,
  }) {
    return OfficialsDirectoryState(
      roster: roster ?? this.roster,
      filters: filters ?? this.filters,
    );
  }

  /// Only [filters] persists -- [roster] is a deterministic mock
  /// dataset (mockOfficialsDirectory()), re-seeded fresh on every load
  /// rather than round-tripped through storage.
  Map<String, dynamic> toJson() => {'filters': filters.toJson()};
}

class OfficialsDirectoryNotifier
    extends PersistedNotifier<OfficialsDirectoryState> {
  @override
  String get persistenceKey => 'officials_directory_v1';

  @override
  OfficialsDirectoryState seed() =>
      OfficialsDirectoryState(roster: mockOfficialsDirectory());

  @override
  Map<String, dynamic> toJson(OfficialsDirectoryState value) => value.toJson();

  @override
  OfficialsDirectoryState fromJson(Map<String, dynamic> json) {
    return OfficialsDirectoryState(
      roster: mockOfficialsDirectory(),
      filters: OfficialsDirectoryFilters.fromJson(
        json['filters'] as Map<String, dynamic>,
      ),
    );
  }

  void updateFilters(
    OfficialsDirectoryFilters Function(OfficialsDirectoryFilters) f,
  ) {
    state = state.copyWith(filters: f(state.filters));
  }
}

final officialsDirectoryProvider =
    NotifierProvider<OfficialsDirectoryNotifier, OfficialsDirectoryState>(
      OfficialsDirectoryNotifier.new,
    );
