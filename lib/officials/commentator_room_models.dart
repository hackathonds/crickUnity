/// DS §11.4 (Officials suite): "Commentator room: stream-audio status
/// tile, [Mark moment] oversized 64 primary (feeds highlights), marker
/// history list, mute-self toggle; assigned-only access, denied state
/// explains assigner path."
///
/// Backlog cites this story against "PRD §2.6-2.7/G.2" -- §2.6/§2.7 are
/// the Scorer/Umpire role writeups and never mention a Commentator role
/// at all, and no Appendix G exists anywhere in the frozen PRD (only A
/// and B are real, established earlier this session). Unlike Scorer/
/// Umpire, the Commentator role has no PRD responsibilities/permissions/
/// credentialing text anywhere -- this DS sentence is the *only* real
/// spec for the entire feature, and everything here is built strictly
/// from it rather than inventing role detail the PRD never wrote.
library;

enum StreamAudioStatus { live, muted, disconnected }

const Map<StreamAudioStatus, String> streamAudioStatusLabels = {
  StreamAudioStatus.live: 'Live',
  StreamAudioStatus.muted: 'Muted',
  StreamAudioStatus.disconnected: 'Disconnected',
};

/// "Mark moment ... feeds highlights" -- conceptually the same
/// mechanism as §7.15's Highlights reel (MediaItem.pinnedBallIndex,
/// gallery_models.dart), but a commentator's live moment marker has no
/// media attached at mark-time, so it's its own lightweight record
/// rather than a MediaItem.
class MomentMarker {
  final int ballIndex;
  final DateTime markedAt;

  const MomentMarker({required this.ballIndex, required this.markedAt});
}
