import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'gig_board_models.dart';

class GigBoardState {
  final List<GigListing> listings;
  final GigFilters filters;
  final Set<String> acceptedGigIds;

  const GigBoardState({
    this.listings = const [],
    this.filters = const GigFilters(),
    this.acceptedGigIds = const {},
  });

  GigBoardState copyWith({
    List<GigListing>? listings,
    GigFilters? filters,
    Set<String>? acceptedGigIds,
  }) {
    return GigBoardState(
      listings: listings ?? this.listings,
      filters: filters ?? this.filters,
      acceptedGigIds: acceptedGigIds ?? this.acceptedGigIds,
    );
  }

  List<GigListing> get filtered =>
      listings.where((g) => filters.matches(g)).toList();

  /// Only [filters]/[acceptedGigIds] persist -- [listings] are
  /// generated relative to "now" each time (mockGigListings), so
  /// they're re-seeded fresh rather than frozen with stale dates.
  Map<String, dynamic> toJson() => {
    'filters': filters.toJson(),
    'acceptedGigIds': acceptedGigIds.toList(),
  };
}

/// DS §11.4: "accepting -> assignment confirmation with calendar add."
/// No real device-calendar integration exists (flagged, same convention
/// as every other missing-platform-API gap this session) -- acceptance
/// is tracked in-app only.
class GigBoardNotifier extends PersistedNotifier<GigBoardState> {
  @override
  String get persistenceKey => 'gig_board_v1';

  @override
  Map<String, dynamic> toJson(GigBoardState value) => value.toJson();

  @override
  GigBoardState fromJson(Map<String, dynamic> json) {
    return GigBoardState(
      listings: mockGigListings(DateTime.now()),
      filters: GigFilters.fromJson(json['filters'] as Map<String, dynamic>),
      acceptedGigIds: {
        for (final id in json['acceptedGigIds'] as List) id as String,
      },
    );
  }

  @override
  GigBoardState seed() =>
      GigBoardState(listings: mockGigListings(DateTime.now()));

  void updateFilters(GigFilters filters) {
    state = state.copyWith(filters: filters);
  }

  void widenRadius() {
    state = state.copyWith(
      filters: state.filters.copyWith(
        maxDistanceKm: state.filters.maxDistanceKm + 10,
      ),
    );
  }

  void accept(String gigId) {
    state = state.copyWith(acceptedGigIds: {...state.acceptedGigIds, gigId});
  }
}

final gigBoardProvider = NotifierProvider<GigBoardNotifier, GigBoardState>(
  GigBoardNotifier.new,
);
