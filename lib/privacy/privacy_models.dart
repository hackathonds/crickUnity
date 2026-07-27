/// PRD §17 (Privacy). "Model: every surface has an audience dial
/// (Everyone -> Members -> Followers -> Teammates/Friends -> Only me),
/// sensible defaults per sensitivity, previews to verify, and minors get
/// locked-stricter defaults." Table of 14 surfaces with per-surface
/// defaults and options, quoted verbatim in each [PrivacySurfaceConfig]
/// below.
library;

enum AudienceLevel { everyone, members, followers, teammatesFriends, onlyMe }

const Map<AudienceLevel, String> audienceLevelLabels = {
  AudienceLevel.everyone: 'Everyone',
  AudienceLevel.members: 'Members',
  AudienceLevel.followers: 'Followers',
  AudienceLevel.teammatesFriends: 'Teammates/Friends',
  AudienceLevel.onlyMe: 'Only me',
};

enum PrivacySurface {
  profileDiscoverability,
  posts,
  photosAndTags,
  followersList,
  messagesWhoCanDm,
  expensesWallet,
  paymentActivity,
  statistics,
  matchHistory,
  teamMembership,
  tournamentHistory,
  onlineStatus,
  activityCalendarDetail,
  readReceipts,
  comparisonOptIn,
}

const Map<PrivacySurface, String> privacySurfaceLabels = {
  PrivacySurface.profileDiscoverability: 'Profile discoverability',
  PrivacySurface.posts: 'Posts',
  PrivacySurface.photosAndTags: 'Photos/videos & tags',
  PrivacySurface.followersList: 'Followers list',
  PrivacySurface.messagesWhoCanDm: 'Messages -- who can DM',
  PrivacySurface.expensesWallet: 'Expenses & wallet',
  PrivacySurface.paymentActivity: 'Payment activity',
  PrivacySurface.statistics: 'Statistics',
  PrivacySurface.matchHistory: 'Match history',
  PrivacySurface.teamMembership: 'Team membership',
  PrivacySurface.tournamentHistory: 'Tournament history',
  PrivacySurface.onlineStatus: 'Online status / last seen',
  PrivacySurface.activityCalendarDetail: 'Activity calendar detail',
  PrivacySurface.readReceipts: 'Read receipts',
  PrivacySurface.comparisonOptIn: 'Comparison opt-in',
};

/// PRD §17's per-row "Options / rules" column, quoted where the row
/// isn't a plain audience dial: Expenses & wallet and Payment activity
/// are hard rules (never public, no dial at all); Read receipts and
/// Comparison opt-in are plain on/off toggles, not audience dials.
class PrivacySurfaceConfig {
  final PrivacySurface surface;
  final List<AudienceLevel> allowedLevels;
  final AudienceLevel defaultLevel;
  final bool isHardRuleLocked;
  final String? rulesNote;

  const PrivacySurfaceConfig({
    required this.surface,
    required this.allowedLevels,
    required this.defaultLevel,
    this.isHardRuleLocked = false,
    this.rulesNote,
  });
}

const List<PrivacySurfaceConfig> privacySurfaceConfigs = [
  PrivacySurfaceConfig(
    surface: PrivacySurface.profileDiscoverability,
    allowedLevels: [
      AudienceLevel.everyone,
      AudienceLevel.followers,
      AudienceLevel.onlyMe,
    ],
    defaultLevel: AudienceLevel.everyone,
    rulesNote: '§5.20 presets',
  ),
  PrivacySurfaceConfig(
    surface: PrivacySurface.posts,
    allowedLevels: [
      AudienceLevel.everyone,
      AudienceLevel.followers,
      AudienceLevel.teammatesFriends,
      AudienceLevel.onlyMe,
    ],
    defaultLevel: AudienceLevel.followers,
    rulesNote: 'Per-post override; audience shown on post',
  ),
  PrivacySurfaceConfig(
    surface: PrivacySurface.photosAndTags,
    allowedLevels: [
      AudienceLevel.everyone,
      AudienceLevel.followers,
      AudienceLevel.onlyMe,
    ],
    defaultLevel: AudienceLevel.followers,
    rulesNote: 'Tag-approval ON by default',
  ),
  PrivacySurfaceConfig(
    surface: PrivacySurface.followersList,
    allowedLevels: [
      AudienceLevel.everyone,
      AudienceLevel.followers,
      AudienceLevel.onlyMe,
    ],
    defaultLevel: AudienceLevel.followers,
  ),
  PrivacySurfaceConfig(
    surface: PrivacySurface.messagesWhoCanDm,
    allowedLevels: [
      AudienceLevel.everyone,
      AudienceLevel.followers,
      AudienceLevel.teammatesFriends,
      AudienceLevel.onlyMe,
    ],
    defaultLevel: AudienceLevel.teammatesFriends,
    rulesNote: '+Followers/Everyone(requests)/Nobody',
  ),
  PrivacySurfaceConfig(
    surface: PrivacySurface.expensesWallet,
    allowedLevels: [],
    defaultLevel: AudienceLevel.onlyMe,
    isHardRuleLocked: true,
    rulesNote: 'Never public, ever (hard rule) -- participants only',
  ),
  PrivacySurfaceConfig(
    surface: PrivacySurface.paymentActivity,
    allowedLevels: [],
    defaultLevel: AudienceLevel.onlyMe,
    isHardRuleLocked: true,
    rulesNote: 'Hard rule -- counterparties only',
  ),
  PrivacySurfaceConfig(
    surface: PrivacySurface.statistics,
    allowedLevels: [
      AudienceLevel.everyone,
      AudienceLevel.followers,
      AudienceLevel.onlyMe,
    ],
    defaultLevel: AudienceLevel.everyone,
    rulesNote:
        'Ranked players\' ranking stats stay public (fairness rule); '
        'opting fully private removes you from public leaderboards',
  ),
  PrivacySurfaceConfig(
    surface: PrivacySurface.matchHistory,
    allowedLevels: [AudienceLevel.everyone, AudienceLevel.onlyMe],
    defaultLevel: AudienceLevel.everyone,
    rulesNote: 'Follows stats setting; private matches always hidden',
  ),
  PrivacySurfaceConfig(
    surface: PrivacySurface.teamMembership,
    allowedLevels: [AudienceLevel.everyone, AudienceLevel.onlyMe],
    defaultLevel: AudienceLevel.everyone,
    rulesNote:
        'Hide specific teams (except within tournaments you\'re '
        'registered in -- organizers/opponents must see eligibility)',
  ),
  PrivacySurfaceConfig(
    surface: PrivacySurface.tournamentHistory,
    allowedLevels: [AudienceLevel.everyone, AudienceLevel.onlyMe],
    defaultLevel: AudienceLevel.everyone,
    rulesNote: 'Follows match history',
  ),
  PrivacySurfaceConfig(
    surface: PrivacySurface.onlineStatus,
    allowedLevels: [AudienceLevel.teammatesFriends, AudienceLevel.onlyMe],
    defaultLevel: AudienceLevel.teammatesFriends,
    rulesNote: 'Reciprocity: hide = can\'t see others\'',
  ),
  PrivacySurfaceConfig(
    surface: PrivacySurface.activityCalendarDetail,
    allowedLevels: [AudienceLevel.teammatesFriends, AudienceLevel.onlyMe],
    defaultLevel: AudienceLevel.teammatesFriends,
    rulesNote: 'Density public, detail Friends (§5.12)',
  ),
  PrivacySurfaceConfig(
    surface: PrivacySurface.readReceipts,
    allowedLevels: [AudienceLevel.everyone, AudienceLevel.onlyMe],
    defaultLevel: AudienceLevel.everyone,
    rulesNote: 'On by default; reciprocity rule',
  ),
  PrivacySurfaceConfig(
    surface: PrivacySurface.comparisonOptIn,
    allowedLevels: [AudienceLevel.everyone, AudienceLevel.onlyMe],
    defaultLevel: AudienceLevel.everyone,
    rulesNote: 'On (adults); off = nobody can pull you into compare',
  ),
];
