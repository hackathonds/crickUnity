import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'team_invite_models.dart';

class TeamInviteState {
  final TeamInviteLink? link;

  const TeamInviteState({this.link});
}

/// PRD §6.3: "share-link (expiring 7d, revocable)."
class TeamInviteNotifier extends Notifier<TeamInviteState> {
  @override
  TeamInviteState build() => const TeamInviteState();

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
