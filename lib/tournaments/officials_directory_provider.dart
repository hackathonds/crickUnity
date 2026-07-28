import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

class OfficialsDirectoryNotifier extends Notifier<OfficialsDirectoryState> {
  @override
  OfficialsDirectoryState build() =>
      OfficialsDirectoryState(roster: mockOfficialsDirectory());

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
