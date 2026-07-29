import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'my_teams_models.dart';

/// "Teams I'm a member of" list -- no real membership registry exists yet
/// (same mock-seed convention as every other module in this app), but
/// once seeded this now persists on-device (lib/persistence/) instead of
/// resetting every restart.
class MyTeamsNotifier extends PersistedNotifier<List<MyTeamMembership>> {
  @override
  String get persistenceKey => 'my_teams_v1';

  @override
  List<MyTeamMembership> seed() => mockMyTeams();

  @override
  Map<String, dynamic> toJson(List<MyTeamMembership> value) => {
    'items': value.map((m) => m.toJson()).toList(),
  };

  @override
  List<MyTeamMembership> fromJson(Map<String, dynamic> json) => [
    for (final item in (json['items'] as List? ?? const []))
      MyTeamMembership.fromJson(item as Map<String, dynamic>),
  ];

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
