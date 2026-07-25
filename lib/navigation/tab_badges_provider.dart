import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The 4 bottom-nav badge values — PRD §3.1's table. Debug-togglable until
/// the real widgets/data (Home priority widgets, live matches, feed,
/// profile completeness) exist to drive them.
class TabBadges {
  /// Home: red dot if any priority widget has an action pending.
  final bool homeActionNeeded;

  /// Matches: count of live matches involving me/my teams.
  final int liveMatchCount;

  /// Community: count of new posts from close graph since last visit.
  final int newCommunityPostCount;

  /// Profile: dot if completeness < 80% or pending verifications.
  final bool profileNeedsAttention;

  const TabBadges({
    this.homeActionNeeded = false,
    this.liveMatchCount = 0,
    this.newCommunityPostCount = 0,
    this.profileNeedsAttention = false,
  });

  TabBadges copyWith({
    bool? homeActionNeeded,
    int? liveMatchCount,
    int? newCommunityPostCount,
    bool? profileNeedsAttention,
  }) {
    return TabBadges(
      homeActionNeeded: homeActionNeeded ?? this.homeActionNeeded,
      liveMatchCount: liveMatchCount ?? this.liveMatchCount,
      newCommunityPostCount:
          newCommunityPostCount ?? this.newCommunityPostCount,
      profileNeedsAttention:
          profileNeedsAttention ?? this.profileNeedsAttention,
    );
  }
}

class TabBadgesNotifier extends Notifier<TabBadges> {
  @override
  TabBadges build() => const TabBadges();

  void setHomeActionNeeded(bool value) =>
      state = state.copyWith(homeActionNeeded: value);

  void setLiveMatchCount(int value) =>
      state = state.copyWith(liveMatchCount: value);

  void setNewCommunityPostCount(int value) =>
      state = state.copyWith(newCommunityPostCount: value);

  void setProfileNeedsAttention(bool value) =>
      state = state.copyWith(profileNeedsAttention: value);
}

final tabBadgesProvider = NotifierProvider<TabBadgesNotifier, TabBadges>(
  TabBadgesNotifier.new,
);

/// PRD §3.1: the Community badge count caps its display at "9+".
String formatCommunityBadge(int count) => count > 9 ? '9+' : '$count';
