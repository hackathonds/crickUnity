import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'my_teams_models.dart';

/// In-memory "teams I'm a member of" list -- no real membership registry
/// exists yet, same mock-provider pattern as every other module in this
/// app.
class MyTeamsNotifier extends Notifier<List<MyTeamMembership>> {
  @override
  List<MyTeamMembership> build() => mockMyTeams();

  /// DS §3.12: long-press action "Set default team" -- exactly one team
  /// is ever the default.
  void setDefault(String teamName) {
    state = [
      for (final m in state) m.copyWith(isDefault: m.team.name == teamName),
    ];
  }

  void toggleMute(String teamName) {
    state = [
      for (final m in state)
        if (m.team.name == teamName) m.copyWith(isMuted: !m.isMuted) else m,
    ];
  }

  void leave(String teamName) {
    state = state.where((m) => m.team.name != teamName).toList();
  }
}

final myTeamsProvider =
    NotifierProvider<MyTeamsNotifier, List<MyTeamMembership>>(
      MyTeamsNotifier.new,
    );
