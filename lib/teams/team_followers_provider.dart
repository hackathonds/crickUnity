import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';

/// AC amendment #1 (PRD §6.20): "team Followers get match alerts +
/// follow CTA on public team page." No follow-a-team relationship
/// existed anywhere in this codebase before this addendum (only
/// followed-ground state, grounds_provider.dart's followedGroundIds).
class TeamFollowersState {
  final Set<String> followedTeamNames;

  const TeamFollowersState({this.followedTeamNames = const {}});

  TeamFollowersState copyWith({Set<String>? followedTeamNames}) {
    return TeamFollowersState(
      followedTeamNames: followedTeamNames ?? this.followedTeamNames,
    );
  }

  Map<String, dynamic> toJson() => {
    'followedTeamNames': followedTeamNames.toList(),
  };

  factory TeamFollowersState.fromJson(Map<String, dynamic> json) {
    return TeamFollowersState(
      followedTeamNames: {
        ...(json['followedTeamNames'] as List? ?? const []).cast<String>(),
      },
    );
  }
}

class TeamFollowersNotifier extends PersistedNotifier<TeamFollowersState> {
  @override
  String get persistenceKey => 'team_followers_v1';

  @override
  TeamFollowersState seed() => const TeamFollowersState();

  @override
  Map<String, dynamic> toJson(TeamFollowersState value) => value.toJson();

  @override
  TeamFollowersState fromJson(Map<String, dynamic> json) =>
      TeamFollowersState.fromJson(json);

  void toggleFollow(String teamName) {
    final current = {...state.followedTeamNames};
    if (!current.remove(teamName)) current.add(teamName);
    state = state.copyWith(followedTeamNames: current);
  }
}

final teamFollowersProvider =
    NotifierProvider<TeamFollowersNotifier, TeamFollowersState>(
      TeamFollowersNotifier.new,
    );
