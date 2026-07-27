/// DS §11.12 (Discover lane & Gear marketplace): "Gear exchange: listing
/// grid 2-up (photo 1:1, price tnum, condition chip); listing detail:
/// gallery, condition facets, seller card with Trusted-Seller badge +
/// Trust band, [Chat with seller] (opens Messenger thread templated
/// with listing card); mark-sold two-party confirm -> mutual review
/// prompt; safety-tips banner on first chat; minor accounts see
/// guardian-routed state. Shops directory: verified shop profiles
/// reusing Ground-profile pattern (catalog strip instead of calendar)."
///
/// Backlog cites this story against "G.7" -- no Appendix G exists
/// anywhere in the frozen PRD (only A and B are real, established
/// earlier this session), and a full-text search of the PRD for "gear"/
/// "marketplace"/"trusted-seller" returns nothing at all. Like E14-04/05
/// and E15-01/02, this DS section is the only real spec for the whole
/// feature -- built strictly from it.
library;

import '../profile/trust_sportsmanship_models.dart' show TrustBand;

enum GearCondition { brandNew, likeNew, good, fair }

const Map<GearCondition, String> gearConditionLabels = {
  GearCondition.brandNew: 'Brand new',
  GearCondition.likeNew: 'Like new',
  GearCondition.good: 'Good',
  GearCondition.fair: 'Fair',
};

enum GearListingStatus { available, saleInProgress, sold }

class GearListing {
  final String id;
  final String sellerName;
  final TrustBand sellerTrustBand;
  final String title;
  final int priceRupees;
  final GearCondition condition;
  final String description;
  final GearListingStatus status;

  const GearListing({
    required this.id,
    required this.sellerName,
    required this.sellerTrustBand,
    required this.title,
    required this.priceRupees,
    required this.condition,
    required this.description,
    this.status = GearListingStatus.available,
  });

  GearListing copyWith({GearListingStatus? status}) {
    return GearListing(
      id: id,
      sellerName: sellerName,
      sellerTrustBand: sellerTrustBand,
      title: title,
      priceRupees: priceRupees,
      condition: condition,
      description: description,
      status: status ?? this.status,
    );
  }
}

/// DS: "Trusted-Seller badge." No PRD/DS numeric ladder is given --
/// flagged judgment call, same convention as E14-02's credential tiers:
/// completed-sales thresholds are a reasonable, simple reading of
/// "ladder," not a PRD-given number.
enum TrustedSellerTier { none, bronze, silver, gold }

const Map<TrustedSellerTier, String> trustedSellerTierLabels = {
  TrustedSellerTier.none: 'New seller',
  TrustedSellerTier.bronze: 'Trusted Seller (Bronze)',
  TrustedSellerTier.silver: 'Trusted Seller (Silver)',
  TrustedSellerTier.gold: 'Trusted Seller (Gold)',
};

const Map<TrustedSellerTier, int> trustedSellerTierThresholds = {
  TrustedSellerTier.bronze: 3,
  TrustedSellerTier.silver: 10,
  TrustedSellerTier.gold: 25,
};

TrustedSellerTier trustedSellerTierFor(int completedSales) {
  var tier = TrustedSellerTier.none;
  for (final entry in trustedSellerTierThresholds.entries) {
    if (completedSales >= entry.value) tier = entry.key;
  }
  return tier;
}

class ShopProfile {
  final String name;
  final bool verified;
  final List<String> catalogItems;

  const ShopProfile({
    required this.name,
    this.verified = false,
    this.catalogItems = const [],
  });
}
