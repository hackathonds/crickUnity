import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'blocked_users_screen.dart';
import 'moderation_provider.dart';
import 'report_models.dart';
import 'report_tracker_screen.dart';

/// PRD §12.10: "Profanity auto-filter with user-level 'hide offensive
/// comments' default ON." Plus links to the report tracker and blocked
/// accounts list, and a debug panel to resolve pending reports (no real
/// moderator review queue exists).
class ModerationSettingsScreen extends ConsumerWidget {
  const ModerationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(moderationProvider);
    final notifier = ref.read(moderationProvider.notifier);
    final pendingReports = state.reports
        .where((r) => r.status == ReportStatus.pending)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Moderation')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          SwitchListTile(
            key: const ValueKey('hideOffensiveCommentsSwitch'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Hide offensive comments'),
            value: state.hideOffensiveComments,
            onChanged: notifier.toggleHideOffensiveComments,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            key: const ValueKey('openReportTrackerButton'),
            variant: AppButtonVariant.secondary,
            label: 'Your reports',
            fullWidth: true,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReportTrackerScreen()),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            key: const ValueKey('openBlockedUsersButton'),
            variant: AppButtonVariant.secondary,
            label: 'Blocked accounts',
            fullWidth: true,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Pending reports (debug review)',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (pendingReports.isEmpty)
            Text(
              'No pending reports.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else
            for (final report in pendingReports)
              Container(
                key: ValueKey('pendingReportRow_${report.id}'),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${report.targetType}: ${report.targetLabel}'
                      '${report.mergedCount > 1 ? " (x${report.mergedCount})" : ""}',
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      '${reportReasonLabels[report.reason]}'
                      '${report.targetUserName != null ? " · ${report.targetUserName}" : ""}',
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                    if (report.targetUserName != null)
                      Text(
                        'Current stage: ${offenderStageFor(state.offenderStrikes[report.targetUserName!] ?? 0)}',
                        style: AppTypography.caption.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => notifier.resolveReport(
                            report.id,
                            actionTaken: true,
                          ),
                          child: const Text('Action taken'),
                        ),
                        TextButton(
                          onPressed: () => notifier.resolveReport(
                            report.id,
                            actionTaken: false,
                          ),
                          child: const Text('No action'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
