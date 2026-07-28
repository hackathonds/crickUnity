/// PRD §2.7 (Umpire): "file match conduct reports (fair play
/// incidents), rate team behavior ... conduct-report tools (report
/// reaches organizer + affects Sportsmanship Scores after review);
/// conduct reports about a team they follow socially get an
/// auto-disclosed relationship tag."
/// DS §11.4: "Conduct report (umpire, from match menu): stepped sheet --
/// incident type grid -> involved player picker (match roster only) ->
/// description (min 30 chars) -> severity -> submit; confirmation
/// states it goes to organizer review; relationship auto-disclosure
/// chip if applicable."
/// A separate, cricket-specific incident model from the general
/// moderation Report (lib/moderation/report_models.dart, E7-07, PRD
/// §12.10) -- that system's reasons (spam/abuse/nudity/etc.) don't fit
/// on-field conduct, and this one specifically routes to organizer
/// review and affects SportsmanshipBand, which the general system
/// doesn't model.
library;

enum ConductIncidentType {
  dissent,
  verbalAbuse,
  physicalAltercation,
  unsportingPlay,
  other,
}

const Map<ConductIncidentType, String> conductIncidentTypeLabels = {
  ConductIncidentType.dissent: 'Dissent',
  ConductIncidentType.verbalAbuse: 'Verbal abuse',
  ConductIncidentType.physicalAltercation: 'Physical altercation',
  ConductIncidentType.unsportingPlay: 'Unsporting play',
  ConductIncidentType.other: 'Other',
};

enum ConductSeverity { minor, moderate, serious }

const Map<ConductSeverity, String> conductSeverityLabels = {
  ConductSeverity.minor: 'Minor',
  ConductSeverity.moderate: 'Moderate',
  ConductSeverity.serious: 'Serious',
};

enum ConductReportStatus {
  submitted,
  underOrganizerReview,
  actionTaken,
  dismissed,
  appealed,
  appealUpheld,
  appealOverturned,
}

const Map<ConductReportStatus, String> conductReportStatusLabels = {
  ConductReportStatus.submitted: 'Submitted',
  ConductReportStatus.underOrganizerReview: 'Under organizer review',
  ConductReportStatus.actionTaken: 'Action taken',
  ConductReportStatus.dismissed: 'Dismissed',
  ConductReportStatus.appealed: 'Appeal submitted',
  ConductReportStatus.appealUpheld: 'Appeal upheld -- action reversed',
  ConductReportStatus.appealOverturned: 'Appeal reviewed -- action stands',
};

/// PRD's minimum -- "description (min 30 chars)."
const int conductReportMinDescriptionLength = 30;

class ConductReport {
  final String id;
  final String matchLabel;
  final String reporterName;
  final String reportedPlayerName;
  final ConductIncidentType incidentType;
  final String description;
  final ConductSeverity severity;
  final ConductReportStatus status;
  final DateTime filedAt;
  final bool relationshipDisclosed;
  final String? appealText;

  const ConductReport({
    required this.id,
    required this.matchLabel,
    required this.reporterName,
    required this.reportedPlayerName,
    required this.incidentType,
    required this.description,
    required this.severity,
    this.status = ConductReportStatus.submitted,
    required this.filedAt,
    this.relationshipDisclosed = false,
    this.appealText,
  });

  ConductReport copyWith({ConductReportStatus? status, String? appealText}) {
    return ConductReport(
      id: id,
      matchLabel: matchLabel,
      reporterName: reporterName,
      reportedPlayerName: reportedPlayerName,
      incidentType: incidentType,
      description: description,
      severity: severity,
      status: status ?? this.status,
      filedAt: filedAt,
      relationshipDisclosed: relationshipDisclosed,
      appealText: appealText ?? this.appealText,
    );
  }
}
