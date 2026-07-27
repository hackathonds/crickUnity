/// PRD §14: "Compare tool: me vs a friend/teammate side-by-side (both
/// must have comparison enabled; comparisons of private profiles
/// blocked); radar chart across batting/bowling/fielding/consistency/
/// availability." Originally shipped as side-by-side bars (a stand-in
/// noted here until E13-01 built the real radar primitive); compare_screen.dart
/// now renders the two profiles as an overlaid [AppRadarChart]
/// (E13-01 addendum), with the bars kept only as the shell's table view.
enum RadarDimension { batting, bowling, fielding, consistency, availability }

const Map<RadarDimension, String> radarDimensionLabels = {
  RadarDimension.batting: 'Batting',
  RadarDimension.bowling: 'Bowling',
  RadarDimension.fielding: 'Fielding',
  RadarDimension.consistency: 'Consistency',
  RadarDimension.availability: 'Availability',
};

class ComparisonProfile {
  final String name;
  final bool comparisonEnabled;
  final bool isPrivate;
  final Map<RadarDimension, int> radarScores;
  final Map<String, int> statRows;

  const ComparisonProfile({
    required this.name,
    this.comparisonEnabled = true,
    this.isPrivate = false,
    this.radarScores = const {},
    this.statRows = const {},
  });
}

const String compareViewerName = 'Deepak Sharma';

/// No real per-player stats model exists to derive these from -- a
/// small fixed mock roster stands in, same convention as every other
/// missing-backend gap this session.
const Map<String, ComparisonProfile> mockComparisonProfiles = {
  'Deepak Sharma': ComparisonProfile(
    name: 'Deepak Sharma',
    radarScores: {
      RadarDimension.batting: 68,
      RadarDimension.bowling: 40,
      RadarDimension.fielding: 55,
      RadarDimension.consistency: 72,
      RadarDimension.availability: 90,
    },
    statRows: {'Runs': 540, 'Wickets': 8, 'Matches': 22, 'Strike rate': 118},
  ),
  'Arjun Rao': ComparisonProfile(
    name: 'Arjun Rao',
    radarScores: {
      RadarDimension.batting: 85,
      RadarDimension.bowling: 20,
      RadarDimension.fielding: 60,
      RadarDimension.consistency: 65,
      RadarDimension.availability: 80,
    },
    statRows: {'Runs': 890, 'Wickets': 2, 'Matches': 25, 'Strike rate': 132},
  ),
  'Farah Khan': ComparisonProfile(
    name: 'Farah Khan',
    comparisonEnabled: false,
    statRows: {},
  ),
  'Sana Malik': ComparisonProfile(name: 'Sana Malik', isPrivate: true),
};
