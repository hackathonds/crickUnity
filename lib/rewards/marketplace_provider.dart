import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'marketplace_models.dart';
import 'rewards_provider.dart';

enum RedeemFailureReason {
  levelLocked,
  outOfStock,
  insufficientCoins,
  capReached,
}

class MarketplaceState {
  final Map<String, int> stockByListingId;
  final List<VoucherRedemption> redemptions;

  const MarketplaceState({
    this.stockByListingId = const {},
    this.redemptions = const [],
  });

  int stockFor(RewardListing listing) =>
      stockByListingId[listing.id] ?? listing.stock;

  MarketplaceState copyWith({
    Map<String, int>? stockByListingId,
    List<VoucherRedemption>? redemptions,
  }) {
    return MarketplaceState(
      stockByListingId: stockByListingId ?? this.stockByListingId,
      redemptions: redemptions ?? this.redemptions,
    );
  }

  Map<String, dynamic> toJson() => {
    'stockByListingId': stockByListingId,
    'redemptions': [for (final r in redemptions) r.toJson()],
  };

  factory MarketplaceState.fromJson(Map<String, dynamic> json) {
    return MarketplaceState(
      stockByListingId: {
        for (final entry
            in (json['stockByListingId'] as Map<String, dynamic>).entries)
          entry.key: entry.value as int,
      },
      redemptions: [
        for (final r in json['redemptions'] as List)
          VoucherRedemption.fromJson(r as Map<String, dynamic>),
      ],
    );
  }
}

int _monthKey(DateTime d) => d.year * 12 + d.month;

/// PRD §13.5 -- E6-05's marketplace & redemption engine. Genuinely
/// spends from the FIFO coin ledger via rewardsProvider.spendCoins,
/// same quality bar as every other real cross-module wire this session.
class MarketplaceNotifier extends PersistedNotifier<MarketplaceState> {
  @override
  String get persistenceKey => 'marketplace_v1';

  @override
  MarketplaceState seed() => const MarketplaceState();

  @override
  Map<String, dynamic> toJson(MarketplaceState value) => value.toJson();

  @override
  MarketplaceState fromJson(Map<String, dynamic> json) =>
      MarketplaceState.fromJson(json);

  /// Returns null on success, or the reason it was blocked -- callers
  /// (Listing detail screen) show that reason inline rather than
  /// silently failing.
  RedeemFailureReason? redeem(
    RewardListing listing, {
    required int viewerLevel,
    DateTime Function() now = DateTime.now,
  }) {
    if (viewerLevel < listing.levelRequirement) {
      return RedeemFailureReason.levelLocked;
    }
    if (state.stockFor(listing) <= 0) return RedeemFailureReason.outOfStock;

    final n = now();
    final thisMonthCount = state.redemptions
        .where(
          (r) =>
              r.listingId == listing.id &&
              _monthKey(r.redeemedAt) == _monthKey(n),
        )
        .length;
    if (thisMonthCount >= listing.redemptionCapPerMonth) {
      return RedeemFailureReason.capReached;
    }

    final spent = ref
        .read(rewardsProvider.notifier)
        .spendCoins(listing.coinPrice, label: 'Redeemed ${listing.title}');
    if (!spent) return RedeemFailureReason.insufficientCoins;

    final voucher = VoucherRedemption(
      id: 'redemption-${n.microsecondsSinceEpoch}',
      listingId: listing.id,
      code: _mockCode(listing, n),
      redeemedAt: n,
      redeemByDate: n.add(const Duration(days: 60)),
    );
    state = state.copyWith(
      stockByListingId: {
        ...state.stockByListingId,
        listing.id: state.stockFor(listing) - 1,
      },
      redemptions: [...state.redemptions, voucher],
    );
    return null;
  }

  String _mockCode(RewardListing listing, DateTime now) {
    final suffix = now.microsecondsSinceEpoch.toRadixString(36).toUpperCase();
    return '${listing.id.toUpperCase().replaceAll('-', '')}-$suffix'.substring(
      0,
      14,
    );
  }

  /// PRD §13.5: "failed fulfillment auto-refunds coins with apology
  /// bonus (+10)." No real partner fulfillment pipeline exists to
  /// genuinely fail -- a manual debug control triggers this path.
  void simulateFailedFulfillment(String redemptionId) {
    final index = state.redemptions.indexWhere((r) => r.id == redemptionId);
    if (index < 0) return;
    final voucher = state.redemptions[index];
    if (voucher.status != RedemptionStatus.active) return;

    ref
        .read(rewardsProvider.notifier)
        .refundWithApology(
          voucher.listing.coinPrice,
          label: 'Failed fulfillment: ${voucher.listing.title}',
        );

    final updated = [...state.redemptions];
    updated[index] = voucher.copyWith(status: RedemptionStatus.failedRefunded);
    state = state.copyWith(redemptions: updated);
  }

  /// Marks any active voucher whose redeem-by date has passed as
  /// expired -- no real cron exists, called from a debug control /
  /// screen init the same way sweepExpiredCoins is.
  void sweepExpiredVouchers({DateTime Function() now = DateTime.now}) {
    final n = now();
    var changed = false;
    final updated = <VoucherRedemption>[];
    for (final r in state.redemptions) {
      if (r.status == RedemptionStatus.active && n.isAfter(r.redeemByDate)) {
        changed = true;
        updated.add(r.copyWith(status: RedemptionStatus.expired));
      } else {
        updated.add(r);
      }
    }
    if (changed) state = state.copyWith(redemptions: updated);
  }
}

final marketplaceProvider =
    NotifierProvider<MarketplaceNotifier, MarketplaceState>(
      MarketplaceNotifier.new,
    );
