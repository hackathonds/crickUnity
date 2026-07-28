/// PRD §4 (Home Dashboard): "Layout model: Vertical stack of widgets.
/// Order = (1) pinned by user, (2) urgency score (action needed >
/// time-sensitive > informational), (3) recency ... Edit Home mode ...
/// allows reorder, hide, pin (max 3 pinned). Hidden widgets reachable
/// under 'More for you' footer. Every widget has: header (title + ⋮),
/// body, and at most 2 action buttons. Pull-to-refresh refreshes all.
/// First-launch default order differs by role (Player-first vs
/// Fan-first vs Owner-first presets)."
///
/// E18-01's job is this framework -- the ordering engine, the pin/hide
/// mechanics, and the header/⋮/2-action contract -- not each widget's
/// real content. Only [pendingPayments] and [coinBalance] are wired to
/// real cross-module state here (enough to make urgency reordering
/// genuinely demonstrable, the story's own AC); the other 22 widget
/// bodies are placeholders citing E18-03/04/05, same "stand-in for a
/// later screen" pattern used throughout this session.
library;

enum HomeWidgetId {
  upcomingMatches,
  recentPerformance,
  todaysActivity,
  expenseSummary,
  coinBalance,
  rewards,
  challenges,
  suggestedFriends,
  suggestedTeams,
  suggestedGrounds,
  nearbyMatches,
  liveMatches,
  weather,
  tournamentUpdates,
  followers,
  messages,
  invitations,
  unreadNotifications,
  pendingPayments,
  recentPosts,
  recentAchievements,
  playerRanking,
  fitnessProgress,
  attendance,
}

const Map<HomeWidgetId, String> homeWidgetTitles = {
  HomeWidgetId.upcomingMatches: 'Upcoming Matches',
  HomeWidgetId.recentPerformance: 'Recent Performance',
  HomeWidgetId.todaysActivity: "Today's Activity",
  HomeWidgetId.expenseSummary: 'Expense Summary',
  HomeWidgetId.coinBalance: 'Coin Balance',
  HomeWidgetId.rewards: 'Rewards',
  HomeWidgetId.challenges: 'Challenges',
  HomeWidgetId.suggestedFriends: 'Suggested Friends',
  HomeWidgetId.suggestedTeams: 'Suggested Teams',
  HomeWidgetId.suggestedGrounds: 'Suggested Grounds',
  HomeWidgetId.nearbyMatches: 'Nearby Matches',
  HomeWidgetId.liveMatches: 'Live Matches',
  HomeWidgetId.weather: 'Weather',
  HomeWidgetId.tournamentUpdates: 'Tournament Updates',
  HomeWidgetId.followers: 'Followers',
  HomeWidgetId.messages: 'Messages',
  HomeWidgetId.invitations: 'Invitations',
  HomeWidgetId.unreadNotifications: 'Unread Notifications',
  HomeWidgetId.pendingPayments: 'Pending Payments',
  HomeWidgetId.recentPosts: 'Recent Posts',
  HomeWidgetId.recentAchievements: 'Recent Achievements',
  HomeWidgetId.playerRanking: 'Player Ranking',
  HomeWidgetId.fitnessProgress: 'Fitness Progress',
  HomeWidgetId.attendance: 'Attendance',
};

/// PRD §4: "urgency score (action needed > time-sensitive >
/// informational)."
enum HomeWidgetUrgency { actionNeeded, timeSensitive, informational }

class HomeWidgetInstance {
  final HomeWidgetId id;
  final HomeWidgetUrgency urgency;
  final bool isPinned;
  final bool isHidden;
  final DateTime lastUpdated;

  const HomeWidgetInstance({
    required this.id,
    required this.urgency,
    this.isPinned = false,
    this.isHidden = false,
    required this.lastUpdated,
  });

  HomeWidgetInstance copyWith({
    HomeWidgetUrgency? urgency,
    bool? isPinned,
    bool? isHidden,
    DateTime? lastUpdated,
  }) {
    return HomeWidgetInstance(
      id: id,
      urgency: urgency ?? this.urgency,
      isPinned: isPinned ?? this.isPinned,
      isHidden: isHidden ?? this.isHidden,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// PRD §4: "First-launch default order differs by role (Player-first
/// vs Fan-first vs Owner-first presets)." Same 24-widget candidate set
/// in every preset -- per-widget Visibility rules (documented per
/// widget in §4.1-4.24, e.g. "hidden for pure Fans") decide whether an
/// individual widget actually renders; a preset only decides *default
/// order* among whichever end up visible, matching the PRD's wording
/// literally ("order differs", not "widget set differs").
enum HomeRolePreset { playerFirst, fanFirst, ownerFirst }

const Map<HomeRolePreset, List<HomeWidgetId>> homeRolePresetOrder = {
  HomeRolePreset.playerFirst: [
    HomeWidgetId.upcomingMatches,
    HomeWidgetId.todaysActivity,
    HomeWidgetId.pendingPayments,
    HomeWidgetId.recentPerformance,
    HomeWidgetId.expenseSummary,
    HomeWidgetId.coinBalance,
    HomeWidgetId.rewards,
    HomeWidgetId.challenges,
    HomeWidgetId.liveMatches,
    HomeWidgetId.tournamentUpdates,
    HomeWidgetId.invitations,
    HomeWidgetId.messages,
    HomeWidgetId.followers,
    HomeWidgetId.unreadNotifications,
    HomeWidgetId.recentPosts,
    HomeWidgetId.recentAchievements,
    HomeWidgetId.playerRanking,
    HomeWidgetId.fitnessProgress,
    HomeWidgetId.attendance,
    HomeWidgetId.suggestedFriends,
    HomeWidgetId.suggestedTeams,
    HomeWidgetId.suggestedGrounds,
    HomeWidgetId.nearbyMatches,
    HomeWidgetId.weather,
  ],
  HomeRolePreset.fanFirst: [
    HomeWidgetId.liveMatches,
    HomeWidgetId.nearbyMatches,
    HomeWidgetId.tournamentUpdates,
    HomeWidgetId.recentPosts,
    HomeWidgetId.followers,
    HomeWidgetId.messages,
    HomeWidgetId.invitations,
    HomeWidgetId.unreadNotifications,
    HomeWidgetId.recentAchievements,
    HomeWidgetId.suggestedFriends,
    HomeWidgetId.suggestedTeams,
    HomeWidgetId.suggestedGrounds,
    HomeWidgetId.coinBalance,
    HomeWidgetId.rewards,
    HomeWidgetId.challenges,
    HomeWidgetId.weather,
    HomeWidgetId.upcomingMatches,
    HomeWidgetId.todaysActivity,
    HomeWidgetId.pendingPayments,
    HomeWidgetId.expenseSummary,
    HomeWidgetId.recentPerformance,
    HomeWidgetId.playerRanking,
    HomeWidgetId.fitnessProgress,
    HomeWidgetId.attendance,
  ],
  HomeRolePreset.ownerFirst: [
    HomeWidgetId.expenseSummary,
    HomeWidgetId.pendingPayments,
    HomeWidgetId.todaysActivity,
    HomeWidgetId.upcomingMatches,
    HomeWidgetId.tournamentUpdates,
    HomeWidgetId.invitations,
    HomeWidgetId.messages,
    HomeWidgetId.unreadNotifications,
    HomeWidgetId.followers,
    HomeWidgetId.liveMatches,
    HomeWidgetId.nearbyMatches,
    HomeWidgetId.weather,
    HomeWidgetId.recentPosts,
    HomeWidgetId.recentAchievements,
    HomeWidgetId.coinBalance,
    HomeWidgetId.rewards,
    HomeWidgetId.challenges,
    HomeWidgetId.playerRanking,
    HomeWidgetId.fitnessProgress,
    HomeWidgetId.attendance,
    HomeWidgetId.suggestedFriends,
    HomeWidgetId.suggestedTeams,
    HomeWidgetId.suggestedGrounds,
    HomeWidgetId.recentPerformance,
  ],
};

/// Max simultaneously pinned widgets -- PRD §4: "pin (max 3 pinned)."
const int maxPinnedHomeWidgets = 3;
