/// PRD §5.15: "Trust Score (bands: Building → Reliable → Rock Solid) ...
/// Shown as band (not raw number)."
enum TrustBand { building, reliable, rockSolid }

const Map<TrustBand, String> trustBandLabels = {
  TrustBand.building: 'Building',
  TrustBand.reliable: 'Reliable',
  TrustBand.rockSolid: 'Rock Solid',
};

/// PRD §5.15: "Sportsmanship Score (bands: Fair → Exemplary; can drop to
/// Under Review) ... Appealable (§17)."
enum SportsmanshipBand { fair, exemplary, underReview }

const Map<SportsmanshipBand, String> sportsmanshipBandLabels = {
  SportsmanshipBand.fair: 'Fair',
  SportsmanshipBand.exemplary: 'Exemplary',
  SportsmanshipBand.underReview: 'Under review',
};

/// A single contributing factor on the Self breakdown screen (DS §11.5):
/// "factor rows with personal trend sparklines + 'how to improve'
/// plain-language rows." `trend` is a relative 0-1 sparkline shape only
/// -- never a literal score, per the "raw scores never rendered" AC.
class BandFactor {
  final String label;
  final List<double> trend;
  final String howToImprove;

  const BandFactor({
    required this.label,
    required this.trend,
    required this.howToImprove,
  });
}

/// PRD §5.15: trust "Drops decay-forgiven over 90 clean days."
class PlayerTrustProfile {
  final TrustBand trustBand;
  final List<BandFactor> trustFactors;
  final int trustCleanDaysCount;

  final SportsmanshipBand sportsmanshipBand;
  final List<BandFactor> sportsmanshipFactors;

  const PlayerTrustProfile({
    required this.trustBand,
    required this.trustFactors,
    required this.trustCleanDaysCount,
    required this.sportsmanshipBand,
    required this.sportsmanshipFactors,
  });
}

/// Mock data for the debug demo and tests -- no backend Trust/
/// Sportsmanship computation exists yet.
PlayerTrustProfile mockPlayerTrustProfile() => const PlayerTrustProfile(
  trustBand: TrustBand.reliable,
  trustCleanDaysCount: 46,
  trustFactors: [
    BandFactor(
      label: 'Availability answered on time',
      trend: [0.4, 0.5, 0.6, 0.7, 0.8],
      howToImprove: 'Respond to availability requests within 24h.',
    ),
    BandFactor(
      label: 'Showed up when confirmed',
      trend: [0.6, 0.6, 0.5, 0.7, 0.75],
      howToImprove: 'Mark yourself Busy/Injured early if plans change.',
    ),
    BandFactor(
      label: 'Paid dues on time',
      trend: [0.3, 0.4, 0.5, 0.55, 0.6],
      howToImprove: 'Settle expense splits within a week of the match.',
    ),
    BandFactor(
      label: 'Scorecards confirmed promptly',
      trend: [0.5, 0.55, 0.6, 0.65, 0.7],
      howToImprove: 'Confirm scorecards as soon as they\'re submitted.',
    ),
  ],
  sportsmanshipBand: SportsmanshipBand.exemplary,
  sportsmanshipFactors: [
    BandFactor(
      label: 'Umpire conduct reports',
      trend: [0.9, 0.9, 0.95, 1.0, 1.0],
      howToImprove: 'Keep discussions with umpires calm and brief.',
    ),
    BandFactor(
      label: 'Opponent fair-play votes',
      trend: [0.8, 0.85, 0.9, 0.9, 0.95],
      howToImprove: 'Shake hands and acknowledge good play post-match.',
    ),
    BandFactor(
      label: 'Dispute behavior',
      trend: [1.0, 1.0, 1.0, 1.0, 1.0],
      howToImprove:
          'Raise disagreements through the dispute flow, not on-field.',
    ),
  ],
);
