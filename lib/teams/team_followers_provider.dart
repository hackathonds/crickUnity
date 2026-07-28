import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

class TeamFollowersNotifier extends Notifier<TeamFollowersState> {
  @override
  TeamFollowersState build() => const TeamFollowersState();

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
