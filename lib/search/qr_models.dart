/// PRD §16 (Search): "QR Search: camera icon -> scan any CricUnity QR
/// (profile/team/ground/match/tournament) -> jump straight to object;
/// also reads booking check-in QRs."
///
/// No camera/QR-decoding package exists in pubspec.yaml (flagged, same
/// convention as every other missing-camera gap this session -- e.g.
/// grounds/booking_ticket_screen.dart's QR display, E9-03). "Scanning"
/// here means picking a real generated code from a list (standing in
/// for what a camera would decode) or typing it in -- the genuine part
/// is the resulting jump-to-object dispatch and the real booking
/// check-in side effect, not the camera capture itself.
///
/// No single "Tournament Home" screen exists yet to jump straight to
/// (this session built discrete tournament screens -- fixtures, points
/// table, brackets, etc. -- each with its own tournament picker, not
/// one canonical per-tournament destination) -- flagged; scanning a
/// tournament QR confirms the match and names the tournament rather
/// than mis-navigating to an arbitrary sub-screen.
enum QrObjectType { ground, tournament, club, group, booking }

class QrCodeEntry {
  final String code;
  final QrObjectType type;
  final String label;
  final String targetId;

  const QrCodeEntry({
    required this.code,
    required this.type,
    required this.label,
    required this.targetId,
  });
}
