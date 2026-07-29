import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../matches/match_models.dart';
import '../persistence/persisted_notifier.dart';
import 'report_models.dart';

class ModerationState {
  final List<Report> reports;
  final Map<String, int> offenderStrikes;
  final Set<String> blockedNames;
  final bool hideOffensiveComments;
  final List<AuditLogEntry> auditLog;

  const ModerationState({
    this.reports = const [],
    this.offenderStrikes = const {},
    this.blockedNames = const {},
    this.hideOffensiveComments = true,
    this.auditLog = const [],
  });

  ModerationState copyWith({
    List<Report>? reports,
    Map<String, int>? offenderStrikes,
    Set<String>? blockedNames,
    bool? hideOffensiveComments,
    List<AuditLogEntry>? auditLog,
  }) {
    return ModerationState(
      reports: reports ?? this.reports,
      offenderStrikes: offenderStrikes ?? this.offenderStrikes,
      blockedNames: blockedNames ?? this.blockedNames,
      hideOffensiveComments:
          hideOffensiveComments ?? this.hideOffensiveComments,
      auditLog: auditLog ?? this.auditLog,
    );
  }

  Map<String, dynamic> toJson() => {
    'reports': [for (final r in reports) r.toJson()],
    'offenderStrikes': offenderStrikes,
    'blockedNames': blockedNames.toList(),
    'hideOffensiveComments': hideOffensiveComments,
    'auditLog': [for (final a in auditLog) a.toJson()],
  };

  factory ModerationState.fromJson(Map<String, dynamic> json) {
    return ModerationState(
      reports: [
        for (final r in json['reports'] as List)
          Report.fromJson(r as Map<String, dynamic>),
      ],
      offenderStrikes: {
        for (final entry
            in (json['offenderStrikes'] as Map<String, dynamic>).entries)
          entry.key: entry.value as int,
      },
      blockedNames: {for (final n in json['blockedNames'] as List) n as String},
      hideOffensiveComments: json['hideOffensiveComments'] as bool? ?? true,
      auditLog: [
        for (final a in json['auditLog'] as List)
          AuditLogEntry.fromJson(a as Map<String, dynamic>),
      ],
    );
  }
}

/// PRD §12.10 -- E7-07's moderation engine.
class ModerationNotifier extends PersistedNotifier<ModerationState> {
  @override
  String get persistenceKey => 'moderation_v1';

  @override
  ModerationState seed() => const ModerationState();

  @override
  Map<String, dynamic> toJson(ModerationState value) => value.toJson();

  @override
  ModerationState fromJson(Map<String, dynamic> json) =>
      ModerationState.fromJson(json);

  /// DS §11.16: "duplicate-report merge notice inline." Returns true if
  /// this merged into an existing pending report rather than creating a
  /// new one.
  bool submitReport({
    required String targetType,
    required String targetLabel,
    String? targetUserName,
    required ReportReason reason,
    String? subReason,
    bool hasEvidence = false,
    bool anonymous = false,
    required String reporterName,
    String? reportedExcerpt,
    DateTime Function() now = DateTime.now,
  }) {
    final existingIndex = state.reports.indexWhere(
      (r) =>
          r.status == ReportStatus.pending &&
          r.targetType == targetType &&
          r.targetLabel == targetLabel &&
          r.reason == reason,
    );
    if (existingIndex >= 0) {
      final existing = state.reports[existingIndex];
      final updated = [...state.reports];
      updated[existingIndex] = existing.copyWith(
        mergedCount: existing.mergedCount + 1,
      );
      state = state.copyWith(reports: updated);
      return true;
    }

    state = state.copyWith(
      reports: [
        ...state.reports,
        Report(
          id: 'report-${now().microsecondsSinceEpoch}',
          targetType: targetType,
          targetLabel: targetLabel,
          targetUserName: targetUserName,
          reason: reason,
          subReason: subReason,
          hasEvidence: hasEvidence,
          anonymous: anonymous,
          reporterName: reporterName,
          createdAt: now(),
          reportedExcerpt: reportedExcerpt,
        ),
      ],
    );
    return false;
  }

  /// E16-11's real Admin console (admin_console_screen.dart) always
  /// passes an explicit [reasonCode] -- DS §7-69: "action sheet (reason
  /// codes mandatory) ... audit log." moderation_settings_screen.dart's
  /// own debug control predates that console and has no reason-code UI,
  /// so [reasonCode] stays optional here with a generic fallback rather
  /// than breaking that call site.
  /// PRD: "repeat-offender ladder: warn -> mute 24h -> suspend 7d ->
  /// ban (each with notice + appeal)." [offenderStageFor] existed
  /// (report_models.dart) but nothing ever called it -- this is that
  /// call: every actioned report against a named user now advances
  /// their strike count and bakes the resulting ladder stage into both
  /// the report (surfaced to the reported user as a real notice, see
  /// notification_catalog.dart's `_moderationCards`) and the audit log
  /// (surfaced to Super Admin). The "appeal" half of the PRD line has
  /// no real dispute-review backend anywhere in this app (same flagged
  /// gap `band_breakdown_screen.dart` already names for the Trust/
  /// Sportsmanship score's own appeal link) -- the notice's Dispute
  /// action marks read like every other non-Pay notification action in
  /// this app rather than claiming a review flow that doesn't exist.
  void resolveReport(
    String reportId, {
    required bool actionTaken,
    String? reasonCode,
    String adminName = 'Admin',
    DateTime Function() now = DateTime.now,
  }) {
    final index = state.reports.indexWhere((r) => r.id == reportId);
    if (index < 0) return;
    final report = state.reports[index];

    String? ladderStage;
    var strikes = state.offenderStrikes;
    if (actionTaken && report.targetUserName != null) {
      final name = report.targetUserName!;
      final newStrikeCount = (strikes[name] ?? 0) + 1;
      strikes = {...strikes, name: newStrikeCount};
      ladderStage = offenderStageFor(newStrikeCount);
    }

    final updated = [...state.reports];
    updated[index] = report.copyWith(
      status: actionTaken
          ? ReportStatus.reviewedActionTaken
          : ReportStatus.reviewedNoAction,
      ladderStageApplied: ladderStage,
    );
    final resolvedReasonCode =
        reasonCode ??
        (actionTaken
            ? adminActionReasonCodes.first
            : adminActionReasonCodes[2]);
    state = state.copyWith(
      reports: updated,
      offenderStrikes: strikes,
      auditLog: [
        AuditLogEntry(
          reportId: reportId,
          targetLabel: report.targetLabel,
          actionTaken: actionTaken,
          reasonCode: resolvedReasonCode,
          decidedAt: now(),
          ladderStageApplied: ladderStage,
        ),
        ...state.auditLog,
      ],
    );
  }

  /// PRD §13: "anomaly checks (same 4 players 'playing' daily) flag to
  /// review." [detectDailyLineupAnomalies] (match_models.dart) is the
  /// detection; this is the "flag to review" half -- one system report
  /// per anomalous lineup, into the exact same queue/action-sheet/audit
  /// log Admin already uses for real user reports. Reuses [submitReport]'s
  /// own duplicate-merge logic (same targetLabel+reason) so a lineup
  /// that's still anomalous on the next sweep just bumps `mergedCount`
  /// rather than spawning a second tracker entry for it. No
  /// `targetUserName` is set -- the anomaly implicates a *group*, and
  /// PRD's own wording is "flag to review," not "auto-punish," so this
  /// intentionally does not pre-assign a repeat-offender strike to
  /// anyone; that stays a human decision made through the normal
  /// resolveReport action sheet.
  void sweepLineupAnomalies(
    List<MatchRecord> matches, {
    DateTime Function() now = DateTime.now,
  }) {
    for (final anomaly in detectDailyLineupAnomalies(matches, now: now)) {
      submitReport(
        targetType: 'Match lineup',
        targetLabel: anomaly.squad.join(', '),
        reason: ReportReason.fakeScore,
        subReason: 'Same lineup playing daily',
        reporterName: systemFraudDetectionReporterName,
        now: now,
      );
    }
  }

  /// PRD: "Blocking: blocker & blocked become invisible to each other
  /// everywhere except co-membership surfaces." Comprehensive
  /// invisibility across every existing screen this session built is a
  /// far larger retrofit than this one story -- only
  /// blocked_users_screen.dart's list and the shared-team-exception
  /// banner genuinely check `blockedNames`, flagged rather than
  /// silently claimed complete.
  void blockUser(String name) {
    state = state.copyWith(blockedNames: {...state.blockedNames, name});
  }

  void unblockUser(String name) {
    final updated = {...state.blockedNames}..remove(name);
    state = state.copyWith(blockedNames: updated);
  }

  void toggleHideOffensiveComments(bool value) {
    state = state.copyWith(hideOffensiveComments: value);
  }
}

final moderationProvider =
    NotifierProvider<ModerationNotifier, ModerationState>(
      ModerationNotifier.new,
    );
