import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/achievement_models.dart';
import '../profile/achievements_wall_screen.dart';
import '../profile/activity_calendar_models.dart';
import '../profile/activity_calendar_screen.dart';
import '../profile/followers_provider.dart';
import '../profile/profile_models.dart';
import '../profile/profile_screen.dart';

/// PRD §16: search results (and QR scans) for a player must land
/// somewhere real, not a dead row -- this wraps E2-01's [ProfileScreen]
/// for a name found via Search/QR rather than duplicating profile
/// rendering. No per-player profile registry exists anywhere in this
/// app (every other profile view is the one hardcoded `mockPlayerProfile`
/// "self" demo) -- the searched name is stamped onto that same mock
/// shape, same honest-gap convention used throughout this session
/// (e.g. E3-12's scorer-scoped identity). [followGraphProvider] (E16-02)
/// is the one real, shared follow-relationship store in the app, so
/// Follow/Unfollow here are genuine actions, not a log line.
class SearchedPlayerProfileScreen extends ConsumerWidget {
  final String playerName;

  const SearchedPlayerProfileScreen({super.key, required this.playerName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = mockPlayerProfile();
    final profile = PlayerProfile(
      name: playerName,
      city: base.city,
      bio: base.bio,
      roleChips: base.roleChips,
      headerStats: base.headerStats,
      pinnedBadges: base.pinnedBadges,
      recentForm: base.recentForm,
      favoriteTeams: base.favoriteTeams,
      endorsements: base.endorsements,
      styleTags: base.styleTags,
    );

    final graph = ref.watch(followGraphProvider);
    final notifier = ref.read(followGraphProvider.notifier);
    final isFollowing = graph.isFollowing(playerName);

    return ProfileScreen(
      profile: profile,
      relation: ViewerRelation.public,
      isFollowing: isFollowing,
      onFollow: () => isFollowing
          ? notifier.unfollow(playerName)
          : notifier.follow(playerName),
      onOpenAchievements: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              AchievementsWallScreen(badges: mockAchievementBadges()),
        ),
      ),
      onOpenActivityCalendar: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ActivityCalendarScreen(
            entries: mockActivityEntries(),
            relation: ViewerRelation.public,
          ),
        ),
      ),
    );
  }
}
