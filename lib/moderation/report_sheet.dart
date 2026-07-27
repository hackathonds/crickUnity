import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'moderation_provider.dart';
import 'report_models.dart';

/// DS §11.16: "Report flow (global modal): reason tree (2 levels max),
/// optional evidence attach, anonymity note, submit -> tracker in
/// Settings; duplicate-report merge notice inline." Callable from any
/// object's menu (feed posts, comments, profiles, ...) without each
/// caller rebuilding this flow.
void showReportSheet(
  BuildContext context, {
  required String targetType,
  required String targetLabel,
  String? targetUserName,
  required String reporterName,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ReportSheetContent(
      targetType: targetType,
      targetLabel: targetLabel,
      targetUserName: targetUserName,
      reporterName: reporterName,
    ),
  );
}

class _ReportSheetContent extends ConsumerStatefulWidget {
  final String targetType;
  final String targetLabel;
  final String? targetUserName;
  final String reporterName;

  const _ReportSheetContent({
    required this.targetType,
    required this.targetLabel,
    required this.targetUserName,
    required this.reporterName,
  });

  @override
  ConsumerState<_ReportSheetContent> createState() =>
      _ReportSheetContentState();
}

class _ReportSheetContentState extends ConsumerState<_ReportSheetContent> {
  ReportReason? _reason;
  String? _subReason;
  bool _hasEvidence = false;
  bool _anonymous = false;

  @override
  Widget build(BuildContext context) {
    final subReasons = _reason == null ? const [] : reportSubReasons[_reason]!;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Report ${widget.targetType}', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final reason in ReportReason.values)
                ChoiceChip(
                  key: ValueKey('reportReasonChip_${reason.name}'),
                  label: Text(reportReasonLabels[reason]!),
                  selected: _reason == reason,
                  onSelected: (_) => setState(() {
                    _reason = reason;
                    _subReason = null;
                  }),
                ),
            ],
          ),
          if (subReasons.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final sub in subReasons)
                  ChoiceChip(
                    key: ValueKey('reportSubReasonChip_$sub'),
                    label: Text(sub),
                    selected: _subReason == sub,
                    onSelected: (_) => setState(() => _subReason = sub),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          CheckboxListTile(
            key: const ValueKey('reportEvidenceCheckbox'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Attach evidence (mock)'),
            value: _hasEvidence,
            onChanged: (v) => setState(() => _hasEvidence = v ?? false),
          ),
          CheckboxListTile(
            key: const ValueKey('reportAnonymousCheckbox'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Report anonymously'),
            value: _anonymous,
            onChanged: (v) => setState(() => _anonymous = v ?? false),
          ),
          Text(
            'Your identity is only shared with reviewers unless you '
            'choose anonymous, which limits follow-up.',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            key: const ValueKey('submitReportButton'),
            variant: AppButtonVariant.primary,
            label: 'Submit report',
            fullWidth: true,
            onPressed: _reason == null
                ? null
                : () {
                    final merged = ref
                        .read(moderationProvider.notifier)
                        .submitReport(
                          targetType: widget.targetType,
                          targetLabel: widget.targetLabel,
                          targetUserName: widget.targetUserName,
                          reason: _reason!,
                          subReason: _subReason,
                          hasEvidence: _hasEvidence,
                          anonymous: _anonymous,
                          reporterName: widget.reporterName,
                        );
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          merged
                              ? 'Already reported -- merged with existing report'
                              : 'Reported. We review within 24h.',
                        ),
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }
}
