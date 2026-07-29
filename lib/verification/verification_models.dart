/// PRD §17 (Privacy): "Verification: blue-tick verification for notable
/// figures/organizations (document-based, Admin-reviewed); green
/// verified-record tick for Ground/Academy listings (ownership proof);
/// scorer/umpire credential badges are activity-earned (§2.6) -- three
/// visually distinct marks." Credential badges are already real and
/// automatic (E14-02's CredentialTier, activity-earned, no request
/// flow) -- this module covers the two *document-based, Admin-reviewed*
/// marks, since "Verification flows" (plural) implies the
/// request/review process, not just a static badge.
library;

enum VerificationMarkType { blueTick, greenVerifiedRecord }

const Map<VerificationMarkType, String> verificationMarkTypeLabels = {
  VerificationMarkType.blueTick: 'Blue tick (notable figure/organization)',
  VerificationMarkType.greenVerifiedRecord:
      'Green verified-record tick (Ground/Academy)',
};

enum VerificationRequestStatus { pending, approved, rejected }

const Map<VerificationRequestStatus, String> verificationRequestStatusLabels = {
  VerificationRequestStatus.pending: 'Pending review',
  VerificationRequestStatus.approved: 'Approved',
  VerificationRequestStatus.rejected: 'Rejected',
};

class VerificationRequest {
  final String id;
  final String requesterName;
  final VerificationMarkType markType;
  final String entityName;
  final String justification;
  final bool documentAttached;
  final VerificationRequestStatus status;
  final String? adminNote;

  const VerificationRequest({
    required this.id,
    required this.requesterName,
    required this.markType,
    required this.entityName,
    required this.justification,
    this.documentAttached = false,
    this.status = VerificationRequestStatus.pending,
    this.adminNote,
  });

  VerificationRequest copyWith({
    VerificationRequestStatus? status,
    String? adminNote,
  }) {
    return VerificationRequest(
      id: id,
      requesterName: requesterName,
      markType: markType,
      entityName: entityName,
      justification: justification,
      documentAttached: documentAttached,
      status: status ?? this.status,
      adminNote: adminNote ?? this.adminNote,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'requesterName': requesterName,
    'markType': markType.name,
    'entityName': entityName,
    'justification': justification,
    'documentAttached': documentAttached,
    'status': status.name,
    'adminNote': adminNote,
  };

  factory VerificationRequest.fromJson(Map<String, dynamic> json) {
    return VerificationRequest(
      id: json['id'] as String,
      requesterName: json['requesterName'] as String,
      markType: VerificationMarkType.values.byName(json['markType'] as String),
      entityName: json['entityName'] as String,
      justification: json['justification'] as String,
      documentAttached: json['documentAttached'] as bool? ?? false,
      status: VerificationRequestStatus.values.byName(json['status'] as String),
      adminNote: json['adminNote'] as String?,
    );
  }
}
