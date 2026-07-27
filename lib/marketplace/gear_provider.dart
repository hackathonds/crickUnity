import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/trust_sportsmanship_models.dart' show TrustBand;
import 'gear_models.dart';

class GearState {
  final List<GearListing> listings;
  final Map<String, int> completedSalesBySeller;
  final Set<String> buyerConfirmedSold;
  final Set<String> sellerConfirmedSold;
  final bool safetyTipsShown;

  /// No real minor/guardian-account distinction is wired into this
  /// module (PlayerProfile.isMinor exists on the Profile module only) --
  /// a toggleable flag stands in so the guardian-routed state is still
  /// genuinely exercisable.
  final bool viewerIsMinor;

  const GearState({
    this.listings = const [],
    this.completedSalesBySeller = const {},
    this.buyerConfirmedSold = const {},
    this.sellerConfirmedSold = const {},
    this.safetyTipsShown = false,
    this.viewerIsMinor = false,
  });

  TrustedSellerTier tierFor(String sellerName) =>
      trustedSellerTierFor(completedSalesBySeller[sellerName] ?? 0);

  GearState copyWith({
    List<GearListing>? listings,
    Map<String, int>? completedSalesBySeller,
    Set<String>? buyerConfirmedSold,
    Set<String>? sellerConfirmedSold,
    bool? safetyTipsShown,
    bool? viewerIsMinor,
  }) {
    return GearState(
      listings: listings ?? this.listings,
      completedSalesBySeller:
          completedSalesBySeller ?? this.completedSalesBySeller,
      buyerConfirmedSold: buyerConfirmedSold ?? this.buyerConfirmedSold,
      sellerConfirmedSold: sellerConfirmedSold ?? this.sellerConfirmedSold,
      safetyTipsShown: safetyTipsShown ?? this.safetyTipsShown,
      viewerIsMinor: viewerIsMinor ?? this.viewerIsMinor,
    );
  }
}

/// No real gear-marketplace backend exists -- flagged mock listings,
/// same convention as every other missing-backend gap this session.
class GearNotifier extends Notifier<GearState> {
  @override
  GearState build() {
    return const GearState(
      listings: [
        GearListing(
          id: 'gear-1',
          sellerName: 'Arjun Rao',
          sellerTrustBand: TrustBand.rockSolid,
          title: 'SG Sunny Tonney bat',
          priceRupees: 3200,
          condition: GearCondition.likeNew,
          description: 'Used for one season, no cracks, freshly oiled.',
        ),
        GearListing(
          id: 'gear-2',
          sellerName: 'Priya Nair',
          sellerTrustBand: TrustBand.reliable,
          title: 'Keeping gloves, size M',
          priceRupees: 900,
          condition: GearCondition.good,
          description: 'A few seasons old, still solid grip.',
        ),
        GearListing(
          id: 'gear-3',
          sellerName: 'Kabir Singh',
          sellerTrustBand: TrustBand.building,
          title: 'Full kit bag',
          priceRupees: 1500,
          condition: GearCondition.fair,
          description: 'Zip is a bit worn but holds everything.',
        ),
      ],
      completedSalesBySeller: {'Arjun Rao': 4, 'Priya Nair': 12},
    );
  }

  void markSafetyTipsShown() {
    if (state.safetyTipsShown) return;
    state = state.copyWith(safetyTipsShown: true);
  }

  void setViewerIsMinor(bool value) {
    state = state.copyWith(viewerIsMinor: value);
  }

  /// DS: "mark-sold two-party confirm -> mutual review prompt." Returns
  /// true once both sides have confirmed (caller triggers the review
  /// prompt then).
  bool confirmSoldAsBuyer(String listingId) {
    state = state.copyWith(
      buyerConfirmedSold: {...state.buyerConfirmedSold, listingId},
    );
    return _maybeFinalizeSale(listingId);
  }

  bool confirmSoldAsSeller(String listingId) {
    state = state.copyWith(
      sellerConfirmedSold: {...state.sellerConfirmedSold, listingId},
    );
    return _maybeFinalizeSale(listingId);
  }

  bool _maybeFinalizeSale(String listingId) {
    final bothConfirmed =
        state.buyerConfirmedSold.contains(listingId) &&
        state.sellerConfirmedSold.contains(listingId);
    if (!bothConfirmed) {
      state = state.copyWith(
        listings: [
          for (final l in state.listings)
            if (l.id == listingId)
              l.copyWith(status: GearListingStatus.saleInProgress)
            else
              l,
        ],
      );
      return false;
    }
    final listing = state.listings.firstWhere((l) => l.id == listingId);
    state = state.copyWith(
      listings: [
        for (final l in state.listings)
          if (l.id == listingId)
            l.copyWith(status: GearListingStatus.sold)
          else
            l,
      ],
      completedSalesBySeller: {
        ...state.completedSalesBySeller,
        listing.sellerName:
            (state.completedSalesBySeller[listing.sellerName] ?? 0) + 1,
      },
    );
    return true;
  }
}

final gearProvider = NotifierProvider<GearNotifier, GearState>(
  GearNotifier.new,
);

/// DS: "Shops directory: verified shop profiles ... catalog strip."
final shopsDirectoryProvider = Provider<List<ShopProfile>>((ref) {
  return const [
    ShopProfile(
      name: 'CricGear Co.',
      verified: true,
      catalogItems: ['Bats', 'Pads', 'Helmets', 'Kit bags'],
    ),
    ShopProfile(
      name: 'Boundary Sports',
      verified: true,
      catalogItems: ['Balls', 'Gloves', 'Shoes'],
    ),
    ShopProfile(name: "Ravi's Cricket Corner", catalogItems: ['Bats', 'Balls']),
  ];
});
