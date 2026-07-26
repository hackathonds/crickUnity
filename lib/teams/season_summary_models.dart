/// PRD §6.19: "Milestones auto-detected (50th win, 100th match, first
/// championship) -> milestone card + team-wide celebration post +
/// commemorative badge to all members on roster at that time."
enum MilestoneType { fiftiethWin, hundredthMatch, firstChampionship }

const Map<MilestoneType, String> milestoneTitles = {
  MilestoneType.fiftiethWin: '50th win',
  MilestoneType.hundredthMatch: '100th match',
  MilestoneType.firstChampionship: 'First championship',
};

class Milestone {
  final MilestoneType type;
  final DateTime achievedAt;

  const Milestone({required this.type, required this.achievedAt});
}

/// No real Match module exists yet (Epic E4) -- milestones are detected
/// from mock counters rather than a real match archive, same pattern as
/// other cross-epic stand-ins this session (Practice Session's
/// `weeklyAttendanceCount`, Create Team's `ownedTeamCount`).
List<Milestone> detectMilestones({
  required int matchesPlayed,
  required int winsCount,
  required int championshipsWon,
  DateTime Function() now = DateTime.now,
}) {
  final milestones = <Milestone>[];
  if (winsCount >= 50) {
    milestones.add(
      Milestone(
        type: MilestoneType.fiftiethWin,
        achievedAt: now().subtract(const Duration(days: 20)),
      ),
    );
  }
  if (matchesPlayed >= 100) {
    milestones.add(
      Milestone(
        type: MilestoneType.hundredthMatch,
        achievedAt: now().subtract(const Duration(days: 10)),
      ),
    );
  }
  if (championshipsWon >= 1) {
    milestones.add(
      Milestone(
        type: MilestoneType.firstChampionship,
        achievedAt: now().subtract(const Duration(days: 3)),
      ),
    );
  }
  return milestones;
}

/// DS §7 screen 22: "Wrap cards vertical" -- [money] is the one DS says
/// must be "auto-excluded from public share" (PRD §6.29), so it's the
/// only type callers need to branch on.
enum WrapCardType { record, topPerformers, bestWin, chemistryTrend, money }

class WrapCard {
  final WrapCardType type;
  final String title;
  final String body;

  const WrapCard({required this.type, required this.title, required this.body});

  bool get isMoneyCard => type == WrapCardType.money;
}

/// PRD's screen table (#30) requires an "insufficient-data variant" but
/// gives no concrete threshold -- 3 matches is a judgment-call minimum
/// (enough for a "record" and a "best win" to be meaningful at all).
const int seasonSummaryMinMatches = 3;

/// PRD §6.28's Chemistry score is a real, team-private computed metric
/// from Epic E3-12 (Peer ratings + chemistry) -- but that story is
/// itself blocked on E4-10 (post-match peer-rating window), which needs
/// a real Match module that doesn't exist yet. The chemistry figure in
/// this wrap is therefore mock data, same honest-gap treatment as the
/// QR-code placeholder in Team Invite (E3-03).
class SeasonSummaryData {
  final int matchesPlayed;
  final int winsCount;
  final int lossesCount;
  final int drawsCount;
  final int championshipsWon;
  final String topScorerName;
  final int topScorerRuns;
  final String topWicketTakerName;
  final int topWicketTakerWickets;
  final String bestWinDescription;
  final int chemistryTrendPercent;
  final int moneyCollectedRupees;
  final int moneySpentRupees;
  final int perHeadCostRupees;

  const SeasonSummaryData({
    required this.matchesPlayed,
    required this.winsCount,
    required this.lossesCount,
    required this.drawsCount,
    required this.championshipsWon,
    required this.topScorerName,
    required this.topScorerRuns,
    required this.topWicketTakerName,
    required this.topWicketTakerWickets,
    required this.bestWinDescription,
    required this.chemistryTrendPercent,
    required this.moneyCollectedRupees,
    required this.moneySpentRupees,
    required this.perHeadCostRupees,
  });

  List<WrapCard> toWrapCards() => [
    WrapCard(
      type: WrapCardType.record,
      title: 'Record',
      body: '$winsCount wins · $lossesCount losses · $drawsCount draws',
    ),
    WrapCard(
      type: WrapCardType.topPerformers,
      title: 'Top performers',
      body:
          '$topScorerName -- $topScorerRuns runs\n'
          '$topWicketTakerName -- $topWicketTakerWickets wickets',
    ),
    WrapCard(
      type: WrapCardType.bestWin,
      title: 'Best win',
      body: bestWinDescription,
    ),
    WrapCard(
      type: WrapCardType.chemistryTrend,
      title: 'Chemistry trend',
      body: chemistryTrendPercent >= 0
          ? 'Up $chemistryTrendPercent% this season'
          : 'Down ${-chemistryTrendPercent}% this season',
    ),
    WrapCard(
      type: WrapCardType.money,
      title: 'Money summary',
      body:
          'Collected ₹$moneyCollectedRupees · Spent ₹$moneySpentRupees\n'
          '₹$perHeadCostRupees per head',
    ),
  ];
}

/// Mock seed data for the debug demo and tests.
SeasonSummaryData mockSeasonSummary() => const SeasonSummaryData(
  matchesPlayed: 105,
  winsCount: 52,
  lossesCount: 40,
  drawsCount: 13,
  championshipsWon: 1,
  topScorerName: 'Rohan Verma',
  topScorerRuns: 612,
  topWicketTakerName: 'Priya Nair',
  topWicketTakerWickets: 24,
  bestWinDescription: 'Chased 187 in the last over vs Central Warriors',
  chemistryTrendPercent: -12,
  moneyCollectedRupees: 48000,
  moneySpentRupees: 41500,
  perHeadCostRupees: 350,
);
