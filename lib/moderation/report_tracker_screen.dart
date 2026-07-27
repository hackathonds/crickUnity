import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../social/composer_screen.dart';
import 'moderation_provider.dart';
import 'report_models.dart';

/// DS §11.16: "tracker in Settings ('Reviewed — action taken' states)."
class ReportTrackerScreen extends ConsumerWidget {
  const ReportTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final reports = ref
        .watch(moderationProvider)
        .reports
        .where((r) => r.reporterName == composerViewerName)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Your reports')),
      body: reports.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppEmptyState(
                message: "You haven't submitted any reports.",
                primaryLabel: 'Back',
                onPrimary: () => Navigator.of(context).pop(),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                for (final report in reports.reversed)
                  Container(
                    key: ValueKey('reportTrackerRow_${report.id}'),
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${report.targetType}: ${report.targetLabel}',
                                style: AppTypography.body.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                            AppTagChip(
                              label: reportStatusLabels[report.status]!,
                              variant:
                                  report.status ==
                                      ReportStatus.reviewedActionTaken
                                  ? AppTagChipVariant.success
                                  : report.status ==
                                        ReportStatus.reviewedNoAction
                                  ? AppTagChipVariant.neutral
                                  : AppTagChipVariant.warning,
                            ),
                          ],
                        ),
                        Text(
                          reportReasonLabels[report.reason]!,
                          style: AppTypography.caption.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                        if (report.mergedCount > 1)
                          Text(
                            'Merged with ${report.mergedCount - 1} other '
                            'report${report.mergedCount - 1 == 1 ? '' : 's'}',
                            style: AppTypography.caption.copyWith(
                              color: colors.textTertiary,
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
