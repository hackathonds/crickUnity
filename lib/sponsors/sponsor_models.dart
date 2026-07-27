/// PRD §2.15 (Sponsor): "browse sponsorship marketplace (teams/
/// tournaments/grounds seeking sponsors, with audience stats); make
/// offers (amount, duration, asset: jersey/boundary/trophy/stream
/// overlay); view campaign dashboard (impressions of sponsored
/// surfaces, engagement); sponsored badge on funded entities ...
/// sponsorship appears only on agreed assets; all sponsorships labeled
/// 'Sponsored by.'"
/// DS §11.9: "Sponsor Console: marketplace list (teams/tournaments/
/// grounds seeking, audience stat chips) -> entity detail -> [Make
/// offer] form (asset segmented: Jersey/Banner/Trophy/Stream · amount ·
/// duration) -> offer states (sent/countered/accepted). Campaign
/// dashboard: impressions & engagement stat cards per asset, date
/// filter; export card. Sponsored rendering rules (global): sponsor logo
/// slots are fixed-size reserved zones (team header 88x28, match card
/// footer 72x20, stream lower-third), always with 'Sponsored' microlabel
/// 10, never animated, never in feed posts."
library;

enum SponsorAsset { jersey, boundary, trophy, streamOverlay }

const Map<SponsorAsset, String> sponsorAssetLabels = {
  SponsorAsset.jersey: 'Jersey',
  SponsorAsset.boundary: 'Boundary/Banner',
  SponsorAsset.trophy: 'Trophy',
  SponsorAsset.streamOverlay: 'Stream overlay',
};

enum SponsorEntityType { team, tournament, ground }

const Map<SponsorEntityType, String> sponsorEntityTypeLabels = {
  SponsorEntityType.team: 'Team',
  SponsorEntityType.tournament: 'Tournament',
  SponsorEntityType.ground: 'Ground',
};

class MarketplaceListing {
  final String entityName;
  final SponsorEntityType entityType;
  final int audienceStat;
  final List<SponsorAsset> seekingAssets;

  const MarketplaceListing({
    required this.entityName,
    required this.entityType,
    required this.audienceStat,
    required this.seekingAssets,
  });
}

enum OfferStatus { sent, countered, accepted, declined }

const Map<OfferStatus, String> offerStatusLabels = {
  OfferStatus.sent: 'Sent',
  OfferStatus.countered: 'Countered',
  OfferStatus.accepted: 'Accepted',
  OfferStatus.declined: 'Declined',
};

class SponsorOffer {
  final String id;
  final String entityName;
  final SponsorAsset asset;
  final int amountRupees;
  final int durationWeeks;
  final OfferStatus status;
  final int? counterAmountRupees;

  const SponsorOffer({
    required this.id,
    required this.entityName,
    required this.asset,
    required this.amountRupees,
    required this.durationWeeks,
    this.status = OfferStatus.sent,
    this.counterAmountRupees,
  });

  SponsorOffer copyWith({OfferStatus? status, int? counterAmountRupees}) {
    return SponsorOffer(
      id: id,
      entityName: entityName,
      asset: asset,
      amountRupees: amountRupees,
      durationWeeks: durationWeeks,
      status: status ?? this.status,
      counterAmountRupees: counterAmountRupees ?? this.counterAmountRupees,
    );
  }
}

class CampaignStat {
  final SponsorAsset asset;
  final int impressions;
  final int engagement;

  const CampaignStat({
    required this.asset,
    required this.impressions,
    required this.engagement,
  });
}
