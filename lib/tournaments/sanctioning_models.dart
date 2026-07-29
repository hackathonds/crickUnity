/// DS §11.10 (Associations): "Association profile: crest header +
/// verified-body chip -> member clubs grid -> sanctioned tournaments
/// list (sanction chip explains on tap) -> official rankings tabs ->
/// circulars feed. Sanction request (organizer side): from Tournament
/// Console -- request card -> status tracker (Requested/Review/Granted
/// with public-reason on revoke). Rankings pages reuse Leaderboard
/// components with association scope."
///
/// Backlog cites "G.9" -- no Appendix G exists anywhere in the frozen
/// PRD (only Appendix A and B are real, same phantom-citation pattern
/// flagged repeatedly this session); DS's own gap table independently
/// confirms Associations has "—" (no PRD detail) beyond DS §11.10
/// itself, so this story builds strictly from the DS quote above.
enum SanctionStatus { requested, review, granted, revoked }

const Map<SanctionStatus, String> sanctionStatusLabels = {
  SanctionStatus.requested: 'Requested',
  SanctionStatus.review: 'Review',
  SanctionStatus.granted: 'Granted',
  SanctionStatus.revoked: 'Revoked',
};

/// No real crest/logo upload pipeline exists (flagged, same
/// convention as every other missing-asset gap this session).
class Association {
  final String id;
  final String name;
  final bool verifiedBody;
  final List<String> memberClubNames;
  final List<String> circulars;

  const Association({
    required this.id,
    required this.name,
    this.verifiedBody = true,
    this.memberClubNames = const [],
    this.circulars = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'verifiedBody': verifiedBody,
    'memberClubNames': memberClubNames,
    'circulars': circulars,
  };

  factory Association.fromJson(Map<String, dynamic> json) {
    return Association(
      id: json['id'] as String,
      name: json['name'] as String,
      verifiedBody: json['verifiedBody'] as bool? ?? true,
      memberClubNames: [
        for (final n in json['memberClubNames'] as List) n as String,
      ],
      circulars: [for (final c in json['circulars'] as List) c as String],
    );
  }
}

class SanctionRequest {
  final String id;
  final String tournamentId;
  final String tournamentName;
  final String associationId;
  final String associationName;
  final SanctionStatus status;
  final DateTime requestedAt;
  final String? revokedReason;

  const SanctionRequest({
    required this.id,
    required this.tournamentId,
    required this.tournamentName,
    required this.associationId,
    required this.associationName,
    this.status = SanctionStatus.requested,
    required this.requestedAt,
    this.revokedReason,
  });

  SanctionRequest copyWith({SanctionStatus? status, String? revokedReason}) {
    return SanctionRequest(
      id: id,
      tournamentId: tournamentId,
      tournamentName: tournamentName,
      associationId: associationId,
      associationName: associationName,
      status: status ?? this.status,
      requestedAt: requestedAt,
      revokedReason: revokedReason ?? this.revokedReason,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tournamentId': tournamentId,
    'tournamentName': tournamentName,
    'associationId': associationId,
    'associationName': associationName,
    'status': status.name,
    'requestedAt': requestedAt.toIso8601String(),
    'revokedReason': revokedReason,
  };

  factory SanctionRequest.fromJson(Map<String, dynamic> json) {
    return SanctionRequest(
      id: json['id'] as String,
      tournamentId: json['tournamentId'] as String,
      tournamentName: json['tournamentName'] as String,
      associationId: json['associationId'] as String,
      associationName: json['associationName'] as String,
      status: SanctionStatus.values.byName(json['status'] as String),
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      revokedReason: json['revokedReason'] as String?,
    );
  }
}
