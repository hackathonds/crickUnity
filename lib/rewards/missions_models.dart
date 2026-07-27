/// DS §7-54 (Missions Board): "Daily 3 cards (claim states), weekly/
/// monthly tabs." Backlog adds a 4th "Epic" tier beyond DS's three --
/// no PRD/DS description exists specifically for it; treated as a
/// longer-horizon/rarer tier by the same logic as the other three,
/// flagged as a judgment call.
enum MissionTier { daily, weekly, monthly, epic }

const Map<MissionTier, String> missionTierLabels = {
  MissionTier.daily: 'Daily',
  MissionTier.weekly: 'Weekly',
  MissionTier.monthly: 'Monthly',
  MissionTier.epic: 'Epic',
};

/// Backlog: "role-fair pool rotation" -- the mission pool spans these
/// categories so a day's set is never skewed toward one role.
enum MissionRoleCategory { batting, bowling, fielding, social, any }

/// No analytics-event pipeline exists to genuinely detect every one of
/// these in real time -- a mock action catalog, same convention as
/// every other missing-instrumentation gap this session. Callers
/// (screens) invoke [MissionsNotifier.recordAction] manually/via debug
/// controls until that pipeline exists.
enum MissionActionType {
  reactToPost,
  respondAvailability,
  watchLiveOvers,
  scoreRuns,
  takeWicket,
  takeCatch,
}

class MissionDef {
  final String id;
  final MissionTier tier;
  final MissionRoleCategory roleCategory;
  final MissionActionType actionType;
  final String title;
  final int target;
  final int coins;
  final int xp;

  const MissionDef({
    required this.id,
    required this.tier,
    required this.roleCategory,
    required this.actionType,
    required this.title,
    required this.target,
    required this.coins,
    required this.xp,
  });
}

/// PRD §13.2: "3 daily missions (e.g., react to a teammate's post,
/// respond to availability, watch 5 overs live)... Weekly: weekly
/// chest at 5/7 mission-days. Monthly: performance recap chest scaled
/// to activity tier." Pool spans every [MissionRoleCategory] so the
/// rotation can be role-fair; deliberately small (an "M" story), not a
/// sprawling catalog.
const List<MissionDef> missionPool = [
  MissionDef(
    id: 'react-post',
    tier: MissionTier.daily,
    roleCategory: MissionRoleCategory.social,
    actionType: MissionActionType.reactToPost,
    title: "React to a teammate's post",
    target: 1,
    coins: 2,
    xp: 2,
  ),
  MissionDef(
    id: 'respond-availability',
    tier: MissionTier.daily,
    roleCategory: MissionRoleCategory.any,
    actionType: MissionActionType.respondAvailability,
    title: 'Respond to an availability poll',
    target: 1,
    coins: 2,
    xp: 2,
  ),
  MissionDef(
    id: 'watch-overs',
    tier: MissionTier.daily,
    roleCategory: MissionRoleCategory.social,
    actionType: MissionActionType.watchLiveOvers,
    title: 'Watch 5 overs live',
    target: 5,
    coins: 3,
    xp: 3,
  ),
  MissionDef(
    id: 'score-30',
    tier: MissionTier.daily,
    roleCategory: MissionRoleCategory.batting,
    actionType: MissionActionType.scoreRuns,
    title: 'Score 30 runs in an innings',
    target: 30,
    coins: 5,
    xp: 5,
  ),
  MissionDef(
    id: 'take-wicket',
    tier: MissionTier.daily,
    roleCategory: MissionRoleCategory.bowling,
    actionType: MissionActionType.takeWicket,
    title: 'Take a wicket',
    target: 1,
    coins: 5,
    xp: 5,
  ),
  MissionDef(
    id: 'take-catch',
    tier: MissionTier.daily,
    roleCategory: MissionRoleCategory.fielding,
    actionType: MissionActionType.takeCatch,
    title: 'Take a catch',
    target: 1,
    coins: 5,
    xp: 5,
  ),
  MissionDef(
    id: 'weekly-runs',
    tier: MissionTier.weekly,
    roleCategory: MissionRoleCategory.batting,
    actionType: MissionActionType.scoreRuns,
    title: 'Score 100 runs this week',
    target: 100,
    coins: 20,
    xp: 20,
  ),
  MissionDef(
    id: 'weekly-wickets',
    tier: MissionTier.weekly,
    roleCategory: MissionRoleCategory.bowling,
    actionType: MissionActionType.takeWicket,
    title: 'Take 4 wickets this week',
    target: 4,
    coins: 20,
    xp: 20,
  ),
  MissionDef(
    id: 'monthly-active',
    tier: MissionTier.monthly,
    roleCategory: MissionRoleCategory.any,
    actionType: MissionActionType.watchLiveOvers,
    title: 'Stay active: 40 overs watched or played this month',
    target: 40,
    coins: 50,
    xp: 50,
  ),
  MissionDef(
    id: 'epic-century',
    tier: MissionTier.epic,
    roleCategory: MissionRoleCategory.batting,
    actionType: MissionActionType.scoreRuns,
    title: 'Score a century (cumulative across the season)',
    target: 100,
    coins: 100,
    xp: 100,
  ),
];

List<MissionDef> missionsForTier(MissionTier tier) =>
    missionPool.where((m) => m.tier == tier).toList();

enum MissionClaimState { inProgress, claimable, claimed }

class MissionInstance {
  final String defId;
  final int progress;
  final bool claimed;

  const MissionInstance({
    required this.defId,
    this.progress = 0,
    this.claimed = false,
  });

  MissionDef get def => missionPool.firstWhere((m) => m.id == defId);

  MissionClaimState get claimState {
    if (claimed) return MissionClaimState.claimed;
    if (progress >= def.target) return MissionClaimState.claimable;
    return MissionClaimState.inProgress;
  }

  MissionInstance copyWith({int? progress, bool? claimed}) {
    return MissionInstance(
      defId: defId,
      progress: progress ?? this.progress,
      claimed: claimed ?? this.claimed,
    );
  }
}

/// PRD §13.2: "Season rewards: end-of-season tier ... with exclusive
/// profile frames." DS §7-55: "year scroller of monthly themes (locked
/// future months show theme + criteria)." PRD names no specific theme
/// list -- a fixed mock published calendar stands in.
class SeasonMonth {
  final int month;
  final String theme;
  final String criteria;

  const SeasonMonth({
    required this.month,
    required this.theme,
    required this.criteria,
  });
}

const List<SeasonMonth> seasonCalendar = [
  SeasonMonth(month: 1, theme: 'Fresh Start', criteria: 'Play 2 matches'),
  SeasonMonth(
    month: 2,
    theme: 'Fielding Focus',
    criteria: '5 catches/run-outs',
  ),
  SeasonMonth(month: 3, theme: 'Big Hitters', criteria: '3 sixes'),
  SeasonMonth(month: 4, theme: 'Spin Kings', criteria: '10 wickets'),
  SeasonMonth(
    month: 5,
    theme: 'Community Month',
    criteria: 'Volunteer 2 duties',
  ),
  SeasonMonth(
    month: 6,
    theme: 'Consistency',
    criteria: '4-week playing streak',
  ),
  SeasonMonth(month: 7, theme: 'Century Watch', criteria: 'Score a fifty'),
  SeasonMonth(
    month: 8,
    theme: 'Team Player',
    criteria: 'Settle 3 expenses on time',
  ),
  SeasonMonth(
    month: 9,
    theme: 'Officiating Drive',
    criteria: 'Score or umpire 2 matches',
  ),
  SeasonMonth(
    month: 10,
    theme: 'Tournament Push',
    criteria: 'Play a tournament match',
  ),
  SeasonMonth(month: 11, theme: 'Endgame', criteria: '5 MVP points'),
  SeasonMonth(month: 12, theme: 'Season Finale', criteria: 'Play every week'),
];
