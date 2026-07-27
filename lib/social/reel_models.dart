/// PRD §12.3: "Reels: <=90s vertical, cricket audio library, remix-
/// allowed toggle, auto-suggested from match highlight clips."
const int maxReelDurationSeconds = 90;

const List<String> mockCricketAudioTracks = [
  'Stadium Roar',
  'Victory Anthem',
  'Chill Nets Beat',
  'Six Hit Sting',
];

class Reel {
  final String id;
  final String authorName;
  final int durationSeconds;
  final String audioTrack;
  final bool remixAllowed;
  final String? sourceClipLabel;
  final DateTime createdAt;

  const Reel({
    required this.id,
    required this.authorName,
    required this.durationSeconds,
    required this.audioTrack,
    required this.remixAllowed,
    this.sourceClipLabel,
    required this.createdAt,
  });
}
