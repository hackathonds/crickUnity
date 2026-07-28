import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

/// PRD §12.10 -- E7-07's moderation engine.
class ModerationNotifier extends Notifier<ModerationState> {
  @override
  ModerationState build() => const ModerationState();

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
    final updated = [...state.reports];
    updated[index] = report.copyWith(
      status: actionTaken
          ? ReportStatus.reviewedActionTaken
          : ReportStatus.reviewedNoAction,
    );
    final resolvedReasonCode =
        reasonCode ??
        (actionTaken
            ? adminActionReasonCodes.first
            : adminActionReasonCodes[2]);
    state = state.copyWith(
      reports: updated,
      auditLog: [
        AuditLogEntry(
          reportId: reportId,
          targetLabel: report.targetLabel,
          actionTaken: actionTaken,
          reasonCode: resolvedReasonCode,
          decidedAt: now(),
        ),
        ...state.auditLog,
      ],
    );

    if (actionTaken && report.targetUserName != null) {
      final name = report.targetUserName!;
      state = state.copyWith(
        offenderStrikes: {
          ...state.offenderStrikes,
          name: (state.offenderStrikes[name] ?? 0) + 1,
        },
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
