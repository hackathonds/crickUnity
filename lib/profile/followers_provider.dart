import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'follower_models.dart';

/// In-memory follow graph -- no backend exists for this yet, same
/// mock-provider pattern as every other module in this app.
class FollowGraphState {
  final List<FollowerEntry> followers;
  final List<FollowerEntry> following;

  /// Restriction is tracked only against followers (PRD §12.8 scopes it to
  /// "follower management") and is never exposed to the restricted person.
  final Set<String> restrictedNames;

  const FollowGraphState({
    required this.followers,
    required this.following,
    this.restrictedNames = const {},
  });

  bool isRestricted(String name) => restrictedNames.contains(name);

  bool isFollowing(String name) => following.any((f) => f.name == name);

  FollowGraphState copyWith({
    List<FollowerEntry>? followers,
    List<FollowerEntry>? following,
    Set<String>? restrictedNames,
  }) => FollowGraphState(
    followers: followers ?? this.followers,
    following: following ?? this.following,
    restrictedNames: restrictedNames ?? this.restrictedNames,
  );
}

class FollowGraphNotifier extends Notifier<FollowGraphState> {
  @override
  FollowGraphState build() =>
      FollowGraphState(followers: mockFollowers(), following: mockFollowing());

  /// A brand-new follow relationship (e.g. following a player found via
  /// Search/QR, PRD §16) -- idempotent no-op if already following.
  void follow(String name) {
    if (state.following.any((f) => f.name == name)) return;
    state = state.copyWith(
      following: [...state.following, FollowerEntry(name: name)],
    );
  }

  /// PRD §12.8: "restrict (they see public-only without knowing)" -- a
  /// silent toggle, never notifies the restricted follower.
  void toggleRestrict(String name) {
    final restricted = {...state.restrictedNames};
    if (!restricted.remove(name)) restricted.add(name);
    state = state.copyWith(restrictedNames: restricted);
  }

  void removeFollower(String name) {
    final restricted = {...state.restrictedNames}..remove(name);
    state = state.copyWith(
      followers: state.followers.where((f) => f.name != name).toList(),
      restrictedNames: restricted,
    );
  }

  void unfollow(String name) {
    state = state.copyWith(
      following: state.following.where((f) => f.name != name).toList(),
    );
  }
}

final followGraphProvider =
    NotifierProvider<FollowGraphNotifier, FollowGraphState>(
      FollowGraphNotifier.new,
    );
