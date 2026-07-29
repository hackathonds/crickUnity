/// PRD §12.10: "report flows on every object (reason tree: spam/abuse/
/// nudity/harassment/fake score/other)." DS §11.16: "reason tree (2
/// levels max)."
enum ReportReason { spam, abuse, nudity, harassment, fakeScore, other }

/// PRD §13's anti-fraud "anomaly checks" flag matches into this same
/// queue with no reporting user behind them -- this name in
/// [Report.reporterName] is how the admin console tells a system-
/// generated flag apart from a real person's report.
const systemFraudDetectionReporterName = 'CricUnity Fraud Detection';

const Map<ReportReason, String> reportReasonLabels = {
  ReportReason.spam: 'Spam',
  ReportReason.abuse: 'Abuse',
  ReportReason.nudity: 'Nudity',
  ReportReason.harassment: 'Harassment',
  ReportReason.fakeScore: 'Fake score',
  ReportReason.other: 'Other',
};

/// The reason tree's 2nd level -- PRD names only the top-level
/// categories, so these sub-reasons are a flagged judgment call filling
/// in plausible detail under each.
const Map<ReportReason, List<String>> reportSubReasons = {
  ReportReason.spam: ['Repetitive posting', 'Unrelated link/ad'],
  ReportReason.abuse: ['Hate speech', 'Threats'],
  ReportReason.nudity: ['Explicit image', 'Suggestive content'],
  ReportReason.harassment: ['Targeted at me', 'Targeted at someone else'],
  ReportReason.fakeScore: ['Manipulated scorecard', 'Impossible stats'],
  ReportReason.other: [],
};

enum ReportStatus { pending, reviewedActionTaken, reviewedNoAction }

const Map<ReportStatus, String> reportStatusLabels = {
  ReportStatus.pending: 'Reviewed within 24h',
  ReportStatus.reviewedActionTaken: 'Reviewed -- action taken',
  ReportStatus.reviewedNoAction: 'Reviewed -- no action',
};

/// [mergedCount] backs DS's "duplicate-report merge notice inline" --
/// a 2nd report on the same target+reason increments this rather than
/// creating a second tracker entry.
///
/// [reportedExcerpt] backs PRD §2.16's Admin restriction: "cannot
/// access private messages except reported threads (reported excerpt
/// only)." For message-type reports this is the only message content
/// ever surfaced to Admin/Super Admin -- the console never reads the
/// full chat_provider.dart thread.
class Report {
  final String id;
  final String targetType;
  final String targetLabel;
  final String? targetUserName;
  final ReportReason reason;
  final String? subReason;
  final bool hasEvidence;
  final bool anonymous;
  final String reporterName;
  final ReportStatus status;
  final int mergedCount;
  final DateTime createdAt;
  final String? reportedExcerpt;

  /// The repeat-offender ladder stage ([offenderStageFor]) this
  /// specific resolution moved [targetUserName] to -- baked in at
  /// resolution time rather than recomputed from the live
  /// `offenderStrikes` total, since that total keeps changing as later
  /// reports resolve and would misrepresent what this report's own
  /// action actually was.
  final String? ladderStageApplied;

  const Report({
    required this.id,
    required this.targetType,
    required this.targetLabel,
    this.targetUserName,
    required this.reason,
    this.subReason,
    this.hasEvidence = false,
    this.anonymous = false,
    required this.reporterName,
    this.status = ReportStatus.pending,
    this.mergedCount = 1,
    required this.createdAt,
    this.reportedExcerpt,
    this.ladderStageApplied,
  });

  Report copyWith({
    ReportStatus? status,
    int? mergedCount,
    String? ladderStageApplied,
  }) {
    return Report(
      id: id,
      targetType: targetType,
      targetLabel: targetLabel,
      targetUserName: targetUserName,
      reason: reason,
      subReason: subReason,
      hasEvidence: hasEvidence,
      anonymous: anonymous,
      reporterName: reporterName,
      status: status ?? this.status,
      mergedCount: mergedCount ?? this.mergedCount,
      createdAt: createdAt,
      reportedExcerpt: reportedExcerpt,
      ladderStageApplied: ladderStageApplied ?? this.ladderStageApplied,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'targetType': targetType,
    'targetLabel': targetLabel,
    'targetUserName': targetUserName,
    'reason': reason.name,
    'subReason': subReason,
    'hasEvidence': hasEvidence,
    'anonymous': anonymous,
    'reporterName': reporterName,
    'status': status.name,
    'mergedCount': mergedCount,
    'createdAt': createdAt.toIso8601String(),
    'reportedExcerpt': reportedExcerpt,
    'ladderStageApplied': ladderStageApplied,
  };

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      targetType: json['targetType'] as String,
      targetLabel: json['targetLabel'] as String,
      targetUserName: json['targetUserName'] as String?,
      reason: ReportReason.values.byName(json['reason'] as String),
      subReason: json['subReason'] as String?,
      hasEvidence: json['hasEvidence'] as bool? ?? false,
      anonymous: json['anonymous'] as bool? ?? false,
      reporterName: json['reporterName'] as String,
      status: ReportStatus.values.byName(json['status'] as String),
      mergedCount: json['mergedCount'] as int? ?? 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
      reportedExcerpt: json['reportedExcerpt'] as String?,
      ladderStageApplied: json['ladderStageApplied'] as String?,
    );
  }
}

/// PRD: "repeat-offender ladder: warn -> mute 24h -> suspend 7d -> ban
/// (each with notice + appeal)."
const List<String> offenderLadderStages = [
  'Warn',
  'Mute 24h',
  'Suspend 7d',
  'Ban',
];

String offenderStageFor(int strikes) {
  if (strikes <= 0) return 'No strikes';
  final index = (strikes - 1).clamp(0, offenderLadderStages.length - 1);
  return offenderLadderStages[index];
}

/// PRD §16 (Admin): "Review reports; suspend content/accounts with
/// reason codes." DS §7-69: "action sheet (reason codes mandatory) ...
/// audit log." No PRD/DS list of exact reason codes exists -- flagged
/// judgment call, one code per plausible outcome.
const List<String> adminActionReasonCodes = [
  'Policy violation -- content removed',
  'Policy violation -- account actioned',
  'Insufficient evidence -- no action',
  'Duplicate/resolved elsewhere',
];

class AuditLogEntry {
  final String reportId;
  final String targetLabel;
  final bool actionTaken;
  final String reasonCode;
  final DateTime decidedAt;

  /// Mirrors [Report.ladderStageApplied] -- PRD §2.16: admin actions
  /// are "logged and visible to Super Admin," and the ladder stage
  /// reached is the one piece of that action Super Admin most needs to
  /// see (whether this decision was a first warning or an escalation).
  final String? ladderStageApplied;

  const AuditLogEntry({
    required this.reportId,
    required this.targetLabel,
    required this.actionTaken,
    required this.reasonCode,
    required this.decidedAt,
    this.ladderStageApplied,
  });

  Map<String, dynamic> toJson() => {
    'reportId': reportId,
    'targetLabel': targetLabel,
    'actionTaken': actionTaken,
    'reasonCode': reasonCode,
    'decidedAt': decidedAt.toIso8601String(),
    'ladderStageApplied': ladderStageApplied,
  };

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      reportId: json['reportId'] as String,
      targetLabel: json['targetLabel'] as String,
      actionTaken: json['actionTaken'] as bool,
      reasonCode: json['reasonCode'] as String,
      decidedAt: DateTime.parse(json['decidedAt'] as String),
      ladderStageApplied: json['ladderStageApplied'] as String?,
    );
  }
}

/// DS §7-69: "SLA countdown chips." PRD names "reviewed within 24h" as
/// the target, not a hard rule elsewhere -- reused here as the SLA
/// window.
const Duration reportSlaWindow = Duration(hours: 24);
