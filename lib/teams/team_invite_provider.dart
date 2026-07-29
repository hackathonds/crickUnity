import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'team_invite_models.dart';

class TeamInviteState {
  final TeamInviteLink? link;

  const TeamInviteState({this.link});

  Map<String, dynamic> toJson() => {'link': link?.toJson()};

  factory TeamInviteState.fromJson(Map<String, dynamic> json) {
    final linkJson = json['link'] as Map<String, dynamic>?;
    return TeamInviteState(
      link: linkJson == null ? null : TeamInviteLink.fromJson(linkJson),
    );
  }
}

/// PRD §6.3: "share-link (expiring 7d, revocable)."
class TeamInviteNotifier extends PersistedNotifier<TeamInviteState> {
  @override
  String get persistenceKey => 'team_invite_v1';

  @override
  TeamInviteState seed() => const TeamInviteState();

  @override
  Map<String, dynamic> toJson(TeamInviteState value) => value.toJson();

  @override
  TeamInviteState fromJson(Map<String, dynamic> json) =>
      TeamInviteState.fromJson(json);

  void generate(String teamName, {DateTime Function() now = DateTime.now}) {
    state = TeamInviteState(link: generateMockInviteLink(teamName, now: now));
  }

  void revoke() {
    final link = state.link;
    if (link == null) return;
    state = TeamInviteState(
      link: TeamInviteLink(
        url: link.url,
        expiresAt: link.expiresAt,
        revoked: true,
      ),
    );
  }
}

final teamInviteProvider =
    NotifierProvider<TeamInviteNotifier, TeamInviteState>(
      TeamInviteNotifier.new,
    );
