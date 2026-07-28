import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/theme/app_theme.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'moderation_provider.dart';
import 'report_models.dart';

/// PRD §16 (Admin): "Review reports; suspend content/accounts with
/// reason codes." DS §7-69: "Admin/Moderation — queue rows with
/// evidence preview, action sheet (reason codes mandatory), audit log;
/// SLA countdown chips; intentionally utilitarian styling (Theme-5
/// forced)." Reuses the real report queue (moderation_provider.dart,
/// E7-07) rather than a parallel one -- this is the genuine
/// moderator-facing console that file's own doc comment flagged as
/// missing ("real review requires a moderator role/queue this session
/// hasn't built").
///
/// [isSuperAdmin] backs PRD §2.16's restriction that admin actions are
/// "logged and visible to Super Admin" -- the audit log is only
/// reachable from that role's view of this same console, not Admin's.
class AdminConsoleScreen extends StatelessWidget {
  final bool isSuperAdmin;

  const AdminConsoleScreen({super.key, this.isSuperAdmin = false});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.themes[AppThemeId.theme5]!,
      child: _AdminConsoleBody(isSuperAdmin: isSuperAdmin),
    );
  }
}

class _AdminConsoleBody extends ConsumerWidget {
  final bool isSuperAdmin;

  const _AdminConsoleBody({required this.isSuperAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(moderationProvider);
    final pending = state.reports
        .where((r) => r.status == ReportStatus.pending)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSuperAdmin ? 'Admin console — Super Admin' : 'Admin console',
        ),
        actions: [
          if (isSuperAdmin)
            IconButton(
              key: const ValueKey('auditLogButton'),
              icon: const Icon(Icons.history),
              tooltip: 'Audit log',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _AuditLogScreen()),
              ),
            ),
        ],
      ),
      body: pending.isEmpty
          ? Center(
              child: Text(
                'No pending reports.',
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                for (final report in pending)
                  _QueueRow(
                    key: ValueKey('queueRow_${report.id}'),
                    report: report,
                  ),
              ],
            ),
    );
  }
}

class _QueueRow extends ConsumerWidget {
  final Report report;

  const _QueueRow({super.key, required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final remaining =
        reportSlaWindow - DateTime.now().difference(report.createdAt);
    final overdue = remaining.isNegative;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${report.targetType}: ${report.targetLabel}',
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ),
              Chip(
                key: const ValueKey('slaChip'),
                label: Text(overdue ? 'Overdue' : '${remaining.inHours}h left'),
                backgroundColor: overdue
                    ? colors.error.withValues(alpha: 0.15)
                    : colors.surfaceAlt,
              ),
            ],
          ),
          Text(
            '${reportReasonLabels[report.reason]}'
            '${report.subReason != null ? ' -- ${report.subReason}' : ''}'
            '${report.mergedCount > 1 ? ' (${report.mergedCount} reports)' : ''}',
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
          if (report.targetUserName != null) ...[
            const SizedBox(height: 2),
            Text(
              key: ValueKey('ladderPreview_${report.id}'),
              '${report.targetUserName}: ${_strikesFor(ref, report.targetUserName!)} '
              'strike${_strikesFor(ref, report.targetUserName!) == 1 ? '' : 's'} so '
              'far -- taking action here escalates to '
              '"${offenderStageFor(_strikesFor(ref, report.targetUserName!) + 1)}".',
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
          ],
          Row(
            children: [
              Icon(
                report.hasEvidence
                    ? Icons.attachment
                    : Icons.attachment_outlined,
                size: 14,
                color: colors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                report.hasEvidence ? 'Evidence attached' : 'No evidence',
                style: AppTypography.caption.copyWith(
                  color: colors.textTertiary,
                ),
              ),
              if (report.anonymous) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Anonymous report',
                  style: AppTypography.caption.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
          if (report.targetType == 'message' &&
              report.reportedExcerpt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              key: const ValueKey('reportedExcerptCard'),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"${report.reportedExcerpt}"',
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Reported excerpt only -- full message thread is not '
                    'accessible (PRD §2.16).',
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            key: ValueKey('reviewButton_${report.id}'),
            onPressed: () => _showActionSheet(context, ref),
            child: const Text('Review'),
          ),
        ],
      ),
    );
  }

  int _strikesFor(WidgetRef ref, String name) =>
      ref.watch(moderationProvider).offenderStrikes[name] ?? 0;

  void _showActionSheet(BuildContext context, WidgetRef ref) {
    String? selectedReason;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final colors = Theme.of(sheetContext).extension<AppColors>()!;
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) => Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.lg,
              bottom:
                  MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reason code (required)',
                  style: AppTypography.label.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final code in adminActionReasonCodes)
                  InkWell(
                    key: ValueKey('reasonCodeOption_$code'),
                    onTap: () => setSheetState(() => selectedReason = code),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedReason == code
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            size: 20,
                            color: selectedReason == code
                                ? colors.primary
                                : colors.textTertiary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              code,
                              style: AppTypography.body.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const ValueKey('noActionButton'),
                        onPressed: selectedReason == null
                            ? null
                            : () {
                                ref
                                    .read(moderationProvider.notifier)
                                    .resolveReport(
                                      report.id,
                                      actionTaken: false,
                                      reasonCode: selectedReason,
                                    );
                                Navigator.of(sheetContext).pop();
                              },
                        child: const Text('No action'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton(
                        key: const ValueKey('actionTakenButton'),
                        onPressed: selectedReason == null
                            ? null
                            : () {
                                ref
                                    .read(moderationProvider.notifier)
                                    .resolveReport(
                                      report.id,
                                      actionTaken: true,
                                      reasonCode: selectedReason,
                                    );
                                Navigator.of(sheetContext).pop();
                              },
                        child: const Text('Action taken'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AuditLogScreen extends ConsumerWidget {
  const _AuditLogScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final auditLog = ref.watch(moderationProvider).auditLog;

    return Scaffold(
      appBar: AppBar(title: const Text('Audit log')),
      body: auditLog.isEmpty
          ? Center(
              child: Text(
                'No decisions logged yet.',
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                for (final entry in auditLog)
                  Container(
                    key: ValueKey(
                      'auditLogEntry_${entry.reportId}_${entry.decidedAt}',
                    ),
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.targetLabel,
                          style: AppTypography.body.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          '${entry.actionTaken ? 'Action taken' : 'No action'} '
                          '-- ${entry.reasonCode}'
                          '${entry.ladderStageApplied != null ? ' -- ladder: ${entry.ladderStageApplied}' : ''}',
                          style: AppTypography.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
