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
