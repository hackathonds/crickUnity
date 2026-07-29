/// PRD §6.26: "Transfers: player moving between teams keeps personal
/// stats; *team* aggregates freeze at departure. Transfer during a
/// tournament follows the tournament's transfer-window rule
/// (organizer-set; default: locked after fixtures publish). Rival-
/// transfer triggers courtesy notification to former captain."
///
/// No Tournament module exists yet, so whether a window is open or
/// locked is a caller-supplied mock input rather than a real
/// organizer-set rule -- same treatment as E3-03's
/// `isRivalInSameTournament` (also caller-supplied, for the same
/// reason).
enum TransferWindowStatus { open, lockedPostFixtures }

class TransferRecord {
  final String id;
  final String playerName;
  final String fromTeamName;
  final String toTeamName;
  final DateTime transferredAt;
  final bool isRivalTransfer;

  const TransferRecord({
    required this.id,
    required this.playerName,
    required this.fromTeamName,
    required this.toTeamName,
    required this.transferredAt,
    required this.isRivalTransfer,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'playerName': playerName,
    'fromTeamName': fromTeamName,
    'toTeamName': toTeamName,
    'transferredAt': transferredAt.toIso8601String(),
    'isRivalTransfer': isRivalTransfer,
  };

  factory TransferRecord.fromJson(Map<String, dynamic> json) {
    return TransferRecord(
      id: json['id'] as String,
      playerName: json['playerName'] as String,
      fromTeamName: json['fromTeamName'] as String,
      toTeamName: json['toTeamName'] as String,
      transferredAt: DateTime.parse(json['transferredAt'] as String),
      isRivalTransfer: json['isRivalTransfer'] as bool,
    );
  }
}
