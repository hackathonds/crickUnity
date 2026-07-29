/// Backlog E11-04: "Compliance vault + forms (M) cert/first-aid
/// expiries, signed-status matrix blocking registration." Cites "G.13"
/// -- no Appendix G exists anywhere in the frozen PRD (only Appendix A
/// and B are real, same phantom-citation pattern flagged repeatedly
/// this session; G.13 was already flagged for this exact reason in
/// E10-02's registration forms checklist and is cited again here for a
/// different feature). With no PRD detail to build from, this
/// implements the backlog line's own words directly: coach
/// certifications with expiries, tracked in a per-coach compliance
/// matrix that blocks assignment ("registration") to a batch
/// (E11-02/E11-03) while any required document is missing, unsigned,
/// or expired.
library;

enum ComplianceDocType {
  coachingCertification,
  firstAidCertification,
  backgroundCheck,
}

const Map<ComplianceDocType, String> complianceDocTypeLabels = {
  ComplianceDocType.coachingCertification: 'Coaching certification',
  ComplianceDocType.firstAidCertification: 'First-aid certification',
  ComplianceDocType.backgroundCheck: 'Background check',
};

/// A curated required-document list stands in for the missing PRD
/// taxonomy -- flagged, same bigger-gap convention as
/// record_models.dart's category list (E8-02) and
/// tournament_models.dart's commonRegistrationDocs (E10-02).
const List<ComplianceDocType> requiredComplianceDocs = ComplianceDocType.values;

class ComplianceDocument {
  final String id;
  final String coachName;
  final ComplianceDocType docType;
  final DateTime issuedDate;
  final DateTime expiryDate;
  final bool signed;

  const ComplianceDocument({
    required this.id,
    required this.coachName,
    required this.docType,
    required this.issuedDate,
    required this.expiryDate,
    this.signed = false,
  });

  bool isValid(DateTime now) => signed && now.isBefore(expiryDate);

  ComplianceDocument copyWith({bool? signed}) {
    return ComplianceDocument(
      id: id,
      coachName: coachName,
      docType: docType,
      issuedDate: issuedDate,
      expiryDate: expiryDate,
      signed: signed ?? this.signed,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'coachName': coachName,
    'docType': docType.name,
    'issuedDate': issuedDate.toIso8601String(),
    'expiryDate': expiryDate.toIso8601String(),
    'signed': signed,
  };

  factory ComplianceDocument.fromJson(Map<String, dynamic> json) {
    return ComplianceDocument(
      id: json['id'] as String,
      coachName: json['coachName'] as String,
      docType: ComplianceDocType.values.byName(json['docType'] as String),
      issuedDate: DateTime.parse(json['issuedDate'] as String),
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      signed: json['signed'] as bool? ?? false,
    );
  }
}
