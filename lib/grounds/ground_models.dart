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
  });

  BoundaryBadge get boundaryBadge => boundaryBadgeFor(boundaryMeters);
}
