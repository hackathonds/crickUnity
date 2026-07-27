/// PRD §13.5's 5 catalog categories.
enum ListingCategory {
  couponsGiftCards,
  merchandise,
  partnerOffers,
  exclusiveEvents,
  cosmetics,
}

const Map<ListingCategory, String> listingCategoryLabels = {
  ListingCategory.couponsGiftCards: 'Coupons & Gift cards',
  ListingCategory.merchandise: 'Merchandise',
  ListingCategory.partnerOffers: 'Partner offers',
  ListingCategory.exclusiveEvents: 'Exclusive events',
  ListingCategory.cosmetics: 'Cosmetics',
};

/// PRD §13.5: "Each listing: coin price, stock, level/tier requirement
/// (if any), terms, expiry ... Fair-use: redemption caps per item per
/// user per month." No specific cap number is given -- 1/item/month is
/// a flagged judgment call (the PRD only names the rule, not a number).
class RewardListing {
  final String id;
  final String title;
  final ListingCategory category;
  final int coinPrice;
  final int stock;
  final int levelRequirement;
  final String terms;
  final String expiryNote;
  final int redemptionCapPerMonth;

  const RewardListing({
    required this.id,
    required this.title,
    required this.category,
    required this.coinPrice,
    required this.stock,
    this.levelRequirement = 1,
    required this.terms,
    required this.expiryNote,
    this.redemptionCapPerMonth = 1,
  });
}

/// Mock catalog for the debug demo -- no partner/merchandise backend
/// exists yet, same convention as every other missing-integration gap
/// this session (real FX rates, real camera/OCR, real Ground module).
const List<RewardListing> mockRewardListings = [
  RewardListing(
    id: 'sports-store-200',
    title: 'Sports store gift card (₹200)',
    category: ListingCategory.couponsGiftCards,
    coinPrice: 400,
    stock: 25,
    terms: 'Redeemable at any partner sports retail outlet. Single use.',
    expiryNote: 'Voucher valid 60 days from redemption.',
  ),
  RewardListing(
    id: 'food-delivery-150',
    title: 'Food delivery voucher (₹150)',
    category: ListingCategory.couponsGiftCards,
    coinPrice: 300,
    stock: 40,
    terms: 'Valid on orders above ₹300. One per account.',
    expiryNote: 'Voucher valid 30 days from redemption.',
  ),
  RewardListing(
    id: 'cricunity-jersey',
    title: 'CricUnity replica jersey',
    category: ListingCategory.merchandise,
    coinPrice: 1200,
    stock: 10,
    levelRequirement: 10,
    terms: 'Uses your saved jersey size. Ships in 2-3 weeks.',
    expiryNote: 'No expiry once redeemed -- physical goods.',
  ),
  RewardListing(
    id: 'ground-slot-discount',
    title: 'Ground booking 20% off',
    category: ListingCategory.partnerOffers,
    coinPrice: 250,
    stock: 100,
    terms: 'Valid at participating partner grounds only.',
    expiryNote: 'Voucher valid 45 days from redemption.',
  ),
  RewardListing(
    id: 'academy-trial-pass',
    title: 'Academy trial pass',
    category: ListingCategory.partnerOffers,
    coinPrice: 600,
    stock: 15,
    levelRequirement: 5,
    terms: 'One free trial session at a partner academy.',
    expiryNote: 'Voucher valid 90 days from redemption.',
  ),
  RewardListing(
    id: 'local-legend-match',
    title: 'Local-legend exhibition match (entry)',
    category: ListingCategory.exclusiveEvents,
    coinPrice: 800,
    stock: 3,
    levelRequirement: 15,
    terms: 'Limited seats -- waitlist opens once stock is exhausted.',
    expiryNote: 'Entry valid for the announced event date only.',
  ),
  RewardListing(
    id: 'coaching-clinic',
    title: 'Coaching clinic seat',
    category: ListingCategory.exclusiveEvents,
    coinPrice: 500,
    stock: 8,
    levelRequirement: 10,
    terms: 'Limited seats -- waitlist opens once stock is exhausted.',
    expiryNote: 'Entry valid for the announced event date only.',
  ),
  RewardListing(
    id: 'profile-frame-gold',
    title: 'Gold profile frame',
    category: ListingCategory.cosmetics,
    coinPrice: 350,
    stock: 999,
    terms: 'Cosmetic only -- no gameplay effect.',
    expiryNote: 'No expiry once redeemed.',
  ),
  RewardListing(
    id: 'scorecard-theme-neon',
    title: 'Neon scorecard theme',
    category: ListingCategory.cosmetics,
    coinPrice: 200,
    stock: 999,
    terms: 'Cosmetic only -- no gameplay effect.',
    expiryNote: 'No expiry once redeemed.',
  ),
];

RewardListing listingById(String id) =>
    mockRewardListings.firstWhere((l) => l.id == id);

enum RedemptionStatus { active, expired, failedRefunded }

/// A single "My Rewards" voucher card. `code` is a mock -- no real
/// partner voucher API exists.
class VoucherRedemption {
  final String id;
  final String listingId;
  final String code;
  final DateTime redeemedAt;
  final DateTime redeemByDate;
  final RedemptionStatus status;

  const VoucherRedemption({
    required this.id,
    required this.listingId,
    required this.code,
    required this.redeemedAt,
    required this.redeemByDate,
    this.status = RedemptionStatus.active,
  });

  RewardListing get listing => listingById(listingId);

  VoucherRedemption copyWith({RedemptionStatus? status}) {
    return VoucherRedemption(
      id: id,
      listingId: listingId,
      code: code,
      redeemedAt: redeemedAt,
      redeemByDate: redeemByDate,
      status: status ?? this.status,
    );
  }
}
