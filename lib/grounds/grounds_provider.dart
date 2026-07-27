import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ground_models.dart';

class GroundsFilter {
  final String query;
  final Set<Facility> requiredFacilities;
  final PitchType? pitchType;
  final int? maxPricePerHour;
  final double minRating;

  const GroundsFilter({
    this.query = '',
    this.requiredFacilities = const {},
    this.pitchType,
    this.maxPricePerHour,
    this.minRating = 0,
  });

  GroundsFilter copyWith({
    String? query,
    Set<Facility>? requiredFacilities,
    PitchType? pitchType,
    bool clearPitchType = false,
    int? maxPricePerHour,
    double? minRating,
  }) {
    return GroundsFilter(
      query: query ?? this.query,
      requiredFacilities: requiredFacilities ?? this.requiredFacilities,
      pitchType: clearPitchType ? null : (pitchType ?? this.pitchType),
      maxPricePerHour: maxPricePerHour ?? this.maxPricePerHour,
      minRating: minRating ?? this.minRating,
    );
  }
}

class GroundsState {
  final List<Ground> grounds;
  final GroundsFilter filter;
  final Set<String> followedGroundIds;

  const GroundsState({
    this.grounds = const [],
    this.filter = const GroundsFilter(),
    this.followedGroundIds = const {},
  });

  List<Ground> get filtered {
    return grounds.where((g) {
      if (filter.query.isNotEmpty &&
          !g.name.toLowerCase().contains(filter.query.toLowerCase())) {
        return false;
      }
      for (final f in filter.requiredFacilities) {
        if (g.facilities[f] == null ||
            g.facilities[f] == FacilityAvailability.no) {
          return false;
        }
      }
      if (filter.pitchType != null &&
          !g.pitchTypes.contains(filter.pitchType)) {
        return false;
      }
      if (filter.maxPricePerHour != null &&
          g.pricePerHour > filter.maxPricePerHour!) {
        return false;
      }
      if (g.rating < filter.minRating) return false;
      return true;
    }).toList();
  }

  Ground? groundById(String id) {
    for (final g in grounds) {
      if (g.id == id) return g;
    }
    return null;
  }

  GroundsState copyWith({
    List<Ground>? grounds,
    GroundsFilter? filter,
    Set<String>? followedGroundIds,
  }) {
    return GroundsState(
      grounds: grounds ?? this.grounds,
      filter: filter ?? this.filter,
      followedGroundIds: followedGroundIds ?? this.followedGroundIds,
    );
  }
}

/// PRD §10 -- E9-01's Grounds discovery engine.
class GroundsNotifier extends Notifier<GroundsState> {
  @override
  GroundsState build() => GroundsState(grounds: _seedGrounds());

  static List<Ground> _seedGrounds() => const [
    Ground(
      id: 'ground-green-valley',
      name: 'Green Valley Ground',
      verifiedOwner: true,
      city: 'Delhi',
      address: 'Sector 21, Delhi',
      photoCount: 12,
      facilities: {
        Facility.floodlights: FacilityAvailability.yes,
        Facility.washrooms: FacilityAvailability.yes,
        Facility.parking: FacilityAvailability.yes,
        Facility.pavilion: FacilityAvailability.no,
        Facility.drinkingWater: FacilityAvailability.yes,
        Facility.kitRental: FacilityAvailability.paid,
        Facility.cafe: FacilityAvailability.paid,
      },
      pitchTypes: [PitchType.turf, PitchType.matting],
      pitchCount: 2,
      boundaryMeters: 72,
      surfaceConditionTag: 'Excellent',
      rulesNote: 'Spikes allowed. Tennis-ball and leather both played.',
      pricePerHour: 800,
      cancellationPolicyNote: 'Free cancellation up to 24h before.',
      rating: 4.6,
      distanceKm: 3.2,
      facetRatings: {
        ReviewFacet.pitch: 4.7,
        ReviewFacet.facilities: 4.5,
        ReviewFacet.staff: 4.4,
        ReviewFacet.value: 4.2,
      },
      parScoreFirstInnings: 168,
    ),
    Ground(
      id: 'ground-riverside-oval',
      name: 'Riverside Oval',
      city: 'Delhi',
      address: 'Riverside Road, Delhi',
      photoCount: 5,
      facilities: {
        Facility.floodlights: FacilityAvailability.no,
        Facility.washrooms: FacilityAvailability.yes,
        Facility.parking: FacilityAvailability.no,
        Facility.drinkingWater: FacilityAvailability.yes,
      },
      pitchTypes: [PitchType.cement],
      pitchCount: 1,
      boundaryMeters: 50,
      surfaceConditionTag: 'Fair',
      rulesNote: 'Tennis-ball only.',
      pricePerHour: 400,
      cancellationPolicyNote: '50% refund within 12h.',
      rating: 3.9,
      distanceKm: 6.8,
      facetRatings: {
        ReviewFacet.pitch: 3.5,
        ReviewFacet.facilities: 3.2,
        ReviewFacet.staff: 4.0,
        ReviewFacet.value: 4.3,
      },
      parScoreFirstInnings: 132,
    ),
    Ground(
      id: 'ground-city-stadium',
      name: 'City Stadium',
      verifiedOwner: true,
      city: 'Mumbai',
      address: 'Central Avenue, Mumbai',
      photoCount: 30,
      facilities: {
        Facility.floodlights: FacilityAvailability.yes,
        Facility.washrooms: FacilityAvailability.yes,
        Facility.parking: FacilityAvailability.yes,
        Facility.pavilion: FacilityAvailability.yes,
        Facility.drinkingWater: FacilityAvailability.yes,
        Facility.kitRental: FacilityAvailability.yes,
        Facility.cafe: FacilityAvailability.yes,
      },
      pitchTypes: [PitchType.turf, PitchType.astro],
      pitchCount: 3,
      boundaryMeters: 68,
      surfaceConditionTag: 'Excellent',
      rulesNote: 'Leather ball only, spikes required.',
      pricePerHour: 1500,
      cancellationPolicyNote: 'Free cancellation up to 48h before.',
      rating: 4.8,
      distanceKm: 400.0,
      facetRatings: {
        ReviewFacet.pitch: 4.9,
        ReviewFacet.facilities: 4.9,
        ReviewFacet.staff: 4.7,
        ReviewFacet.value: 4.1,
      },
      parScoreFirstInnings: 192,
      isFullyBookedToday: true,
    ),
  ];

  void setQuery(String query) {
    state = state.copyWith(filter: state.filter.copyWith(query: query));
  }

  void toggleFacility(Facility facility) {
    final current = {...state.filter.requiredFacilities};
    if (current.contains(facility)) {
      current.remove(facility);
    } else {
      current.add(facility);
    }
    state = state.copyWith(
      filter: state.filter.copyWith(requiredFacilities: current),
    );
  }

  void setPitchType(PitchType? type) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        pitchType: type,
        clearPitchType: type == null,
      ),
    );
  }

  void setMaxPrice(int? price) {
    state = state.copyWith(
      filter: state.filter.copyWith(maxPricePerHour: price),
    );
  }

  void setMinRating(double rating) {
    state = state.copyWith(filter: state.filter.copyWith(minRating: rating));
  }

  void clearFilters() {
    state = state.copyWith(filter: const GroundsFilter());
  }

  /// PRD §10.4: "Follow a ground -> new-slot alerts, price-drop alerts,
  /// records news." The alert-catalog rows themselves are a later
  /// backlog addendum for E12-05 (Notification Center config) -- this
  /// story only owns the follow relationship itself.
  void toggleFollow(String groundId) {
    final current = {...state.followedGroundIds};
    if (current.contains(groundId)) {
      current.remove(groundId);
    } else {
      current.add(groundId);
    }
    state = state.copyWith(followedGroundIds: current);
  }

  /// PRD §2.11: owner cancellation < 48h before slot drops reliability,
  /// "visible on listing." PRD names no exact point value -- a flagged
  /// judgment call (see [reliabilityPenaltyPoints] in booking_models.dart).
  void applyReliabilityPenalty(String groundId, double points) {
    state = state.copyWith(
      grounds: [
        for (final g in state.grounds)
          if (g.id == groundId)
            g.copyWith(
              reliabilityScore: (g.reliabilityScore - points).clamp(0, 100),
            )
          else
            g,
      ],
    );
  }
}

final groundsProvider = NotifierProvider<GroundsNotifier, GroundsState>(
  GroundsNotifier.new,
);
