import 'dart:math';

/// PRD §14: "Leaderboards: scopes (Friends / Team / Club / City /
/// Ground / Tournament / Global) x metrics (runs, wickets, MVPs, XP,
/// attendance %, props) x windows (week/month/season/all-time). Friends
/// scope is default ... Self row always pinned visible with rank even
/// off-screen."
enum LeaderboardScope { friends, team, club, city, ground, tournament, global }

const Map<LeaderboardScope, String> leaderboardScopeLabels = {
  LeaderboardScope.friends: 'Friends',
  LeaderboardScope.team: 'Team',
  LeaderboardScope.club: 'Club',
  LeaderboardScope.city: 'City',
  LeaderboardScope.ground: 'Ground',
  LeaderboardScope.tournament: 'Tournament',
  LeaderboardScope.global: 'Global',
};

enum LeaderboardMetric { runs, wickets, mvps, xp, attendancePercent, props }

const Map<LeaderboardMetric, String> leaderboardMetricLabels = {
  LeaderboardMetric.runs: 'Runs',
  LeaderboardMetric.wickets: 'Wickets',
  LeaderboardMetric.mvps: 'MVPs',
  LeaderboardMetric.xp: 'XP',
  LeaderboardMetric.attendancePercent: 'Attendance %',
  LeaderboardMetric.props: 'Props',
};

enum LeaderboardWindow { week, month, season, allTime }

const Map<LeaderboardWindow, String> leaderboardWindowLabels = {
  LeaderboardWindow.week: 'Week',
  LeaderboardWindow.month: 'Month',
  LeaderboardWindow.season: 'Season',
  LeaderboardWindow.allTime: 'All-time',
};

/// PRD names the filter category ("age/experience-band filters") but no
/// exact bands -- a flagged judgment call.
enum AgeBand { under16, age16to24, age25to34, age35plus }

const Map<AgeBand, String> ageBandLabels = {
  AgeBand.under16: 'Under 16',
  AgeBand.age16to24: '16-24',
  AgeBand.age25to34: '25-34',
  AgeBand.age35plus: '35+',
};

enum ExperienceBand { newcomer, developing, veteran }

const Map<ExperienceBand, String> experienceBandLabels = {
  ExperienceBand.newcomer: 'Newcomer (0-1 seasons)',
  ExperienceBand.developing: 'Developing (2-3 seasons)',
  ExperienceBand.veteran: 'Veteran (4+ seasons)',
};

/// PRD: "Minimum-activity qualifications stop one-match wonders topping
/// averages." No exact thresholds given -- a flagged judgment call,
/// scaled by window length.
const Map<LeaderboardWindow, int> qualificationMinMatches = {
  LeaderboardWindow.week: 1,
  LeaderboardWindow.month: 3,
  LeaderboardWindow.season: 6,
  LeaderboardWindow.allTime: 10,
};

enum LeaderboardMovement { up, down }

class LeaderboardEntry {
  final String name;
  final String teamCaption;
  final int metricValue;
  final int matchesPlayed;
  final AgeBand ageBand;
  final ExperienceBand experienceBand;
  final LeaderboardMovement? movement;
  final int? movementValue;

  const LeaderboardEntry({
    required this.name,
    required this.teamCaption,
    required this.metricValue,
    required this.matchesPlayed,
    required this.ageBand,
    required this.experienceBand,
    this.movement,
    this.movementValue,
  });

  bool qualifiesFor(LeaderboardWindow window) =>
      matchesPlayed >= qualificationMinMatches[window]!;
}

const String leaderboardViewerName = 'Deepak Sharma';

const List<String> _mockNames = [
  'Arjun Rao',
  'Priya Nair',
  'Kabir Singh',
  'Ananya Iyer',
  'Farah Khan',
  'Rohan Mehta',
  'Sana Malik',
  'Vikram Joshi',
  'Meera Pillai',
  'Aditya Kapoor',
  'Ishaan Verma',
  'Divya Reddy',
];

/// No real stats database exists -- a deterministically seeded mock
/// generator stands in, so switching filters gives a stable (not
/// re-randomized every rebuild) but varied list per scope/metric/window
/// combination, and the viewer's own qualification state is genuine
/// given [viewerMatchesPlayed].
List<LeaderboardEntry> mockLeaderboard({
  required LeaderboardScope scope,
  required LeaderboardMetric metric,
  required LeaderboardWindow window,
  int viewerMatchesPlayed = 4,
}) {
  final seed = scope.index * 1000 + metric.index * 100 + window.index * 10;
  final random = Random(seed);
  final maxValue = switch (metric) {
    LeaderboardMetric.attendancePercent => 100,
    LeaderboardMetric.mvps => 12,
    LeaderboardMetric.props => 400,
    _ => 800,
  };

  final entries = [
    for (final name in _mockNames)
      LeaderboardEntry(
        name: name,
        teamCaption: 'Strikers CC',
        metricValue: 20 + random.nextInt(maxValue),
        matchesPlayed: 1 + random.nextInt(12),
        ageBand: AgeBand.values[random.nextInt(AgeBand.values.length)],
        experienceBand:
            ExperienceBand.values[random.nextInt(ExperienceBand.values.length)],
        movement: random.nextBool()
            ? LeaderboardMovement.up
            : LeaderboardMovement.down,
        movementValue: 1 + random.nextInt(3),
      ),
    LeaderboardEntry(
      name: leaderboardViewerName,
      teamCaption: 'Strikers CC',
      metricValue: 20 + random.nextInt(maxValue),
      matchesPlayed: viewerMatchesPlayed,
      ageBand: AgeBand.age25to34,
      experienceBand: ExperienceBand.developing,
    ),
  ];
  entries.sort((a, b) => b.metricValue.compareTo(a.metricValue));
  return entries;
}
