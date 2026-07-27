import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sponsor_models.dart';

class SponsorState {
  final List<MarketplaceListing> listings;
  final List<SponsorOffer> offers;
  final List<CampaignStat> campaignStats;

  const SponsorState({
    this.listings = const [],
    this.offers = const [],
    this.campaignStats = const [],
  });

  /// E15-01's Go-Live flow flags its sponsor-slot-confirm step as a
  /// mock ("always contracted") since this story hadn't shipped yet --
  /// this is now the real signal for whether a stream overlay is
  /// actually sponsored.
  bool get hasAcceptedStreamSponsorship => offers.any(
    (o) =>
        o.asset == SponsorAsset.streamOverlay &&
        o.status == OfferStatus.accepted,
  );

  SponsorState copyWith({
    List<MarketplaceListing>? listings,
    List<SponsorOffer>? offers,
    List<CampaignStat>? campaignStats,
  }) {
    return SponsorState(
      listings: listings ?? this.listings,
      offers: offers ?? this.offers,
      campaignStats: campaignStats ?? this.campaignStats,
    );
  }
}

/// No real sponsorship-marketplace backend exists -- flagged mock
/// listings/offers, same convention as every other missing-backend gap
/// this session.
class SponsorNotifier extends Notifier<SponsorState> {
  @override
  SponsorState build() {
    return const SponsorState(
      listings: [
        MarketplaceListing(
          entityName: 'Strikers CC',
          entityType: SponsorEntityType.team,
          audienceStat: 1240,
          seekingAssets: [SponsorAsset.jersey, SponsorAsset.streamOverlay],
        ),
        MarketplaceListing(
          entityName: 'Monsoon Cup',
          entityType: SponsorEntityType.tournament,
          audienceStat: 8600,
          seekingAssets: [SponsorAsset.trophy, SponsorAsset.boundary],
        ),
        MarketplaceListing(
          entityName: 'Green Valley Ground',
          entityType: SponsorEntityType.ground,
          audienceStat: 3100,
          seekingAssets: [SponsorAsset.boundary],
        ),
      ],
      campaignStats: [
        CampaignStat(
          asset: SponsorAsset.jersey,
          impressions: 12400,
          engagement: 340,
        ),
        CampaignStat(
          asset: SponsorAsset.streamOverlay,
          impressions: 5200,
          engagement: 180,
        ),
      ],
    );
  }

  void makeOffer({
    required String entityName,
    required SponsorAsset asset,
    required int amountRupees,
    required int durationWeeks,
  }) {
    final id = 'offer-${DateTime.now().millisecondsSinceEpoch}';
    state = state.copyWith(
      offers: [
        SponsorOffer(
          id: id,
          entityName: entityName,
          asset: asset,
          amountRupees: amountRupees,
          durationWeeks: durationWeeks,
        ),
        ...state.offers,
      ],
    );
  }

  /// DS: "offer states (sent/countered/accepted)." Counter is the
  /// entity's side; acceptance is modeled here as the sponsor accepting
  /// the counter (no separate entity-side console exists yet -- this
  /// screen stands in for both sides of the negotiation, flagged).
  void receiveCounter(String offerId, int counterAmountRupees) {
    state = state.copyWith(
      offers: [
        for (final o in state.offers)
          if (o.id == offerId)
            o.copyWith(
              status: OfferStatus.countered,
              counterAmountRupees: counterAmountRupees,
            )
          else
            o,
      ],
    );
  }

  void acceptOffer(String offerId) {
    state = state.copyWith(
      offers: [
        for (final o in state.offers)
          if (o.id == offerId) o.copyWith(status: OfferStatus.accepted) else o,
      ],
    );
  }

  void declineOffer(String offerId) {
    state = state.copyWith(
      offers: [
        for (final o in state.offers)
          if (o.id == offerId) o.copyWith(status: OfferStatus.declined) else o,
      ],
    );
  }
}

final sponsorProvider = NotifierProvider<SponsorNotifier, SponsorState>(
  SponsorNotifier.new,
);
