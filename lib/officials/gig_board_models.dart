/// PRD §2.6 (Scorer): "Visible modules: Scorer Console, Gig Board
/// (matches needing scorers nearby)." §2.7 (Umpire): "Umpire Gig Board;
/// set fees & travel radius."
/// DS §11.4 (Officials suite): "Gig Board: filter chips (distance
/// slider, fee min, date); gig cards: match line, teams' Trust bands,
/// fee tnum, distance, [Accept]/[Details]; accepting -> assignment
/// confirmation with calendar add. Empty: radius-widen suggestion."
library;

import '../profile/trust_sportsmanship_models.dart'
    show TrustBand, trustBandLabels;

enum OfficialRole { scorer, umpire }

const Map<OfficialRole, String> officialRoleLabels = {
  OfficialRole.scorer: 'Scorer',
  OfficialRole.umpire: 'Umpire',
};

class GigListing {
  final String id;
  final OfficialRole role;
  final String matchLabel;
  final String teamAName;
  final TrustBand teamATrust;
  final String teamBName;
  final TrustBand teamBTrust;
  final DateTime date;
  final String groundName;
  final double distanceKm;
  final int feeRupees;

  const GigListing({
    required this.id,
    required this.role,
    required this.matchLabel,
    required this.teamAName,
    required this.teamATrust,
    required this.teamBName,
    required this.teamBTrust,
    required this.date,
    required this.groundName,
    required this.distanceKm,
    required this.feeRupees,
  });

  String get teamsLine =>
      '$teamAName (${trustBandLabels[teamATrust]}) vs '
      '$teamBName (${trustBandLabels[teamBTrust]})';
}

class GigFilters {
  final double maxDistanceKm;
  final int minFeeRupees;
  final DateTime? onDate;

  const GigFilters({
    this.maxDistanceKm = 15,
    this.minFeeRupees = 0,
    this.onDate,
  });

  GigFilters copyWith({
    double? maxDistanceKm,
    int? minFeeRupees,
    DateTime? onDate,
    bool clearDate = false,
  }) {
    return GigFilters(
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      minFeeRupees: minFeeRupees ?? this.minFeeRupees,
      onDate: clearDate ? null : (onDate ?? this.onDate),
    );
  }

  bool matches(GigListing gig) {
    if (gig.distanceKm > maxDistanceKm) return false;
    if (gig.feeRupees < minFeeRupees) return false;
    if (onDate != null &&
        !(gig.date.year == onDate!.year &&
            gig.date.month == onDate!.month &&
            gig.date.day == onDate!.day)) {
      return false;
    }
    return true;
  }
}

/// No real match-needing-officials pipeline exists yet (Epic E4's
/// matches never flag "scorer/umpire needed") -- flagged mock listings,
/// same convention as every other missing-backend gap this session.
List<GigListing> mockGigListings(DateTime now) => [
  GigListing(
    id: 'gig-1',
    role: OfficialRole.scorer,
    matchLabel: 'League fixture',
    teamAName: 'Strikers CC',
    teamATrust: TrustBand.rockSolid,
    teamBName: 'Riverside Warriors',
    teamBTrust: TrustBand.reliable,
    date: now.add(const Duration(days: 2)),
    groundName: 'Green Valley Ground',
    distanceKm: 4,
    feeRupees: 500,
  ),
  GigListing(
    id: 'gig-2',
    role: OfficialRole.umpire,
    matchLabel: 'Friendly',
    teamAName: 'City Titans',
    teamATrust: TrustBand.building,
    teamBName: 'Titans',
    teamBTrust: TrustBand.reliable,
    date: now.add(const Duration(days: 3)),
    groundName: 'Central Oval',
    distanceKm: 9,
    feeRupees: 700,
  ),
  GigListing(
    id: 'gig-3',
    role: OfficialRole.scorer,
    matchLabel: 'Tournament group match',
    teamAName: 'Monsoon Cup XI',
    teamATrust: TrustBand.reliable,
    teamBName: 'Riverside Warriors',
    teamBTrust: TrustBand.reliable,
    date: now.add(const Duration(days: 5)),
    groundName: 'Riverside Turf',
    distanceKm: 22,
    feeRupees: 900,
  ),
  GigListing(
    id: 'gig-4',
    role: OfficialRole.umpire,
    matchLabel: 'League fixture',
    teamAName: 'Strikers CC',
    teamATrust: TrustBand.rockSolid,
    teamBName: 'City Titans',
    teamBTrust: TrustBand.building,
    date: now.add(const Duration(days: 1)),
    groundName: 'Green Valley Ground',
    distanceKm: 4,
    feeRupees: 600,
  ),
  GigListing(
    id: 'gig-5',
    role: OfficialRole.scorer,
    matchLabel: 'Cup knockout',
    teamAName: 'Titans',
    teamATrust: TrustBand.reliable,
    teamBName: 'Monsoon Cup XI',
    teamBTrust: TrustBand.reliable,
    date: now.add(const Duration(days: 8)),
    groundName: 'Central Oval',
    distanceKm: 30,
    feeRupees: 1200,
  ),
];
