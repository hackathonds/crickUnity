/// PRD §12.10: "report flows on every object (reason tree: spam/abuse/
/// nudity/harassment/fake score/other)." DS §11.16: "reason tree (2
/// levels max)."
enum ReportReason { spam, abuse, nudity, harassment, fakeScore, other }

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
  });

  Report copyWith({ReportStatus? status, int? mergedCount}) {
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

  const AuditLogEntry({
    required this.reportId,
    required this.targetLabel,
    required this.actionTaken,
    required this.reasonCode,
    required this.decidedAt,
  });
}

/// DS §7-69: "SLA countdown chips." PRD names "reviewed within 24h" as
/// the target, not a hard rule elsewhere -- reused here as the SLA
/// window.
const Duration reportSlaWindow = Duration(hours: 24);
