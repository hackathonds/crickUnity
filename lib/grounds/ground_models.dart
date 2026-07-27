/// PRD §10.1 (Ground Profile, public): "facilities checklist
/// (floodlights, washrooms, parking, pavilion, drinking water, kit
/// rental, café -- each with yes/no/paid tag), pitch types (turf/
/// matting/cement/astro; count of pitches), boundary size (straight/
/// square meters, badge 'Big ground'/'Small ground'), surface condition
/// self-declared + review-derived tag, rules, pricing table by slot/
/// day-type, cancellation policy."
enum Facility {
  floodlights,
  washrooms,
  parking,
  pavilion,
  drinkingWater,
  kitRental,
  cafe,
}

const Map<Facility, String> facilityLabels = {
  Facility.floodlights: 'Floodlights',
  Facility.washrooms: 'Washrooms',
  Facility.parking: 'Parking',
  Facility.pavilion: 'Pavilion',
  Facility.drinkingWater: 'Drinking water',
  Facility.kitRental: 'Kit rental',
  Facility.cafe: 'Café',
};

enum FacilityAvailability { yes, no, paid }

enum PitchType { turf, matting, cement, astro }

const Map<PitchType, String> pitchTypeLabels = {
  PitchType.turf: 'Turf',
  PitchType.matting: 'Matting',
  PitchType.cement: 'Cement',
  PitchType.astro: 'Astro',
};

enum BoundaryBadge { big, standard, small }

/// PRD names the badge, not the meter thresholds -- a flagged judgment
/// call.
BoundaryBadge boundaryBadgeFor(int meters) {
  if (meters >= 70) return BoundaryBadge.big;
  if (meters < 55) return BoundaryBadge.small;
  return BoundaryBadge.standard;
}

const Map<BoundaryBadge, String> boundaryBadgeLabels = {
  BoundaryBadge.big: 'Big ground',
  BoundaryBadge.standard: 'Standard ground',
  BoundaryBadge.small: 'Small ground',
};

/// PRD §10.3: "facets (pitch, facilities, staff, value)."
enum ReviewFacet { pitch, facilities, staff, value }

const Map<ReviewFacet, String> reviewFacetLabels = {
  ReviewFacet.pitch: 'Pitch',
  ReviewFacet.facilities: 'Facilities',
  ReviewFacet.staff: 'Staff',
  ReviewFacet.value: 'Value',
};

/// No real geolocation/maps package exists in pubspec.yaml -- distance
/// is a mock number, same flagged gap as recognition/
/// grounds_heatmap_screen.dart (E8-04).
class Ground {
  final String id;
  final String name;
  final bool verifiedOwner;
  final String city;
  final String address;
  final int photoCount;
  final Map<Facility, FacilityAvailability> facilities;
  final List<PitchType> pitchTypes;
  final int pitchCount;
  final int boundaryMeters;
  final String surfaceConditionTag;
  final String rulesNote;
  final int pricePerHour;
  final String cancellationPolicyNote;
  final double rating;
  final double distanceKm;
  final Map<ReviewFacet, double> facetRatings;

  /// Backlog cites "par-score stats" for E9-02 (PRD §19.8, which does not
  /// exist -- §19 Analytics has no numbered subsections at all, confirmed
  /// by grepping every `^# 19` heading; only §19's flat bullet list is
  /// real, and it names no ground-level par-score metric). No per-ground
  /// match-log aggregation pipeline exists to derive a genuine average
  /// first-innings total, so this is a mocked number on the model, same
  /// flagged-mock convention as [distanceKm].
  final int parScoreFirstInnings;

  /// PRD §20 screen-list item 50 names a "fully-booked state" for this
  /// profile. Real availability comes from the booking calendar (E9-03,
  /// not yet built), so this is a mocked flag standing in until that
  /// calendar exists.
  final bool isFullyBookedToday;

  const Ground({
    required this.id,
    required this.name,
    this.verifiedOwner = false,
    required this.city,
    required this.address,
    this.photoCount = 0,
    this.facilities = const {},
    this.pitchTypes = const [],
    this.pitchCount = 1,
    required this.boundaryMeters,
    required this.surfaceConditionTag,
    required this.rulesNote,
    required this.pricePerHour,
    required this.cancellationPolicyNote,
    this.rating = 0,
    this.distanceKm = 0,
    this.facetRatings = const {},
    this.parScoreFirstInnings = 0,
    this.isFullyBookedToday = false,
  });

  BoundaryBadge get boundaryBadge => boundaryBadgeFor(boundaryMeters);
}
