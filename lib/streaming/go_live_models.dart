/// DS §11.8 (Streaming & Go-Live): "Go-Live flow (squad/organizer):
/// entry from Match Detail [Go live]; pre-flight checklist card
/// (orientation, stability, score-sync check) -> overlay theme picker (3
/// thumbnails) -> sponsor-slot confirm (if contracted) -> countdown
/// 3-2-1 -> live HUD: viewer count, health dot, [Mark moment], [End]."
/// PRD §12.4 (Live Streaming): "Go-live from a match page (squad
/// members/organizer only, so streams anchor to real matches) or
/// profile. Live chat with slow-mode toggle, pinned comment, moderator
/// assignment; viewers count; auto-save VOD to match gallery;
/// report-live escalates to priority moderation."
library;

enum OverlayTheme { classic, bold, minimal }

const Map<OverlayTheme, String> overlayThemeLabels = {
  OverlayTheme.classic: 'Classic',
  OverlayTheme.bold: 'Bold',
  OverlayTheme.minimal: 'Minimal',
};

class PreflightChecklist {
  final bool orientationOk;
  final bool stabilityOk;
  final bool scoreSyncOk;

  const PreflightChecklist({
    this.orientationOk = false,
    this.stabilityOk = false,
    this.scoreSyncOk = false,
  });

  bool get allOk => orientationOk && stabilityOk && scoreSyncOk;

  PreflightChecklist copyWith({
    bool? orientationOk,
    bool? stabilityOk,
    bool? scoreSyncOk,
  }) {
    return PreflightChecklist(
      orientationOk: orientationOk ?? this.orientationOk,
      stabilityOk: stabilityOk ?? this.stabilityOk,
      scoreSyncOk: scoreSyncOk ?? this.scoreSyncOk,
    );
  }
}

enum StreamHealthStatus { healthy, poor, disconnected }

const Map<StreamHealthStatus, String> streamHealthStatusLabels = {
  StreamHealthStatus.healthy: 'Healthy',
  StreamHealthStatus.poor: 'Poor connection',
  StreamHealthStatus.disconnected: 'Disconnected',
};

class LiveMoment {
  final int ballIndex;
  final DateTime markedAt;

  const LiveMoment({required this.ballIndex, required this.markedAt});
}

class VodChapter {
  final String label;
  final int ballIndex;

  const VodChapter({required this.label, required this.ballIndex});
}

class ChatMessage {
  final String author;
  final String text;
  final bool pinned;

  const ChatMessage({
    required this.author,
    required this.text,
    this.pinned = false,
  });
}
