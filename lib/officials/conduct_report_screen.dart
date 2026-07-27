import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../teams/selection_board_models.dart' show mockSelectionPool;
import 'conduct_report_models.dart';
import 'conduct_report_provider.dart';

/// DS §11.4 "Conduct report (umpire, from match menu)" stepped sheet,
/// collapsed into one scrollable form (proportionate to an "M" story --
/// every field DS names is present: incident type grid, player picker
/// scoped to the match roster, min-30-char description, severity,
/// relationship auto-disclosure) rather than a multi-screen wizard.
class ConductReportScreen extends ConsumerWidget {
  const ConductReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final reports = ref.watch(conductReportProvider).reports;

    return Scaffold(
      appBar: AppBar(title: const Text('Conduct reports')),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('fileConductReportButton'),
        onPressed: () => _showFileSheet(context, ref),
        label: const Text('File report'),
        icon: const Icon(Icons.flag_outlined),
      ),
      body: reports.isEmpty
          ? Center(
              child: Text(
                'No conduct reports.',
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                for (final report in reports)
                  _ConductReportCard(
                    key: ValueKey('conductReport_${report.id}'),
                    report: report,
                  ),
              ],
            ),
    );
  }

  void _showFileSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _FileConductReportSheet(),
    );
  }
}

class _ConductReportCard extends ConsumerWidget {
  final ConductReport report;

  const _ConductReportCard({super.key, required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                  '${conductIncidentTypeLabels[report.incidentType]} -- '
                  '${report.reportedPlayerName}',
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ),
              Text(
                conductSeverityLabels[report.severity]!,
                style: AppTypography.caption.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            report.matchLabel,
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            report.description,
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
          if (report.relationshipDisclosed)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Chip(
                label: const Text('Relationship disclosed'),
                backgroundColor: colors.surface,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                conductReportStatusLabels[report.status]!,
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const Spacer(),
              if (report.status == ConductReportStatus.actionTaken)
                TextButton(
                  key: ValueKey('appealButton_${report.id}'),
                  onPressed: () => _showAppealDialog(context, ref, report.id),
                  child: const Text('Appeal'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAppealDialog(BuildContext context, WidgetRef ref, String reportId) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appeal this report'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Why are you appealing?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(conductReportProvider.notifier)
                  .appeal(reportId, controller.text);
              Navigator.of(context).pop();
            },
            child: const Text('Submit appeal'),
          ),
        ],
      ),
    );
  }
}

class _FileConductReportSheet extends ConsumerStatefulWidget {
  const _FileConductReportSheet();

  @override
  ConsumerState<_FileConductReportSheet> createState() =>
      _FileConductReportSheetState();
}

class _FileConductReportSheetState
    extends ConsumerState<_FileConductReportSheet> {
  ConductIncidentType? _incidentType;
  String? _playerName;
  ConductSeverity? _severity;
  bool _relationshipDisclosed = false;
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _incidentType != null &&
      _playerName != null &&
      _severity != null &&
      _descriptionController.text.trim().length >=
          conductReportMinDescriptionLength;

  void _submit() {
    ref
        .read(conductReportProvider.notifier)
        .fileReport(
          matchLabel: 'Current match',
          reporterName: 'Match umpire',
          reportedPlayerName: _playerName!,
          incidentType: _incidentType!,
          description: _descriptionController.text.trim(),
          severity: _severity!,
          relationshipDisclosed: _relationshipDisclosed,
        );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report submitted -- goes to organizer review'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final roster = mockSelectionPool();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      expand: false,
      builder: (context, controller) => StatefulBuilder(
        builder: (context, setSheetState) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'File a conduct report',
              style: AppTypography.title.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Incident type',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final type in ConductIncidentType.values)
                  ChoiceChip(
                    key: ValueKey('incidentTypeChip_${type.name}'),
                    label: Text(conductIncidentTypeLabels[type]!),
                    selected: _incidentType == type,
                    onSelected: (_) =>
                        setSheetState(() => _incidentType = type),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Involved player (match roster)',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final player in roster)
                  ChoiceChip(
                    key: ValueKey('rosterPlayerChip_${player.name}'),
                    label: Text(player.name),
                    selected: _playerName == player.name,
                    onSelected: (_) =>
                        setSheetState(() => _playerName = player.name),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Description (min $conductReportMinDescriptionLength chars)',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const ValueKey('conductDescriptionField'),
              controller: _descriptionController,
              maxLines: 4,
              onChanged: (_) => setSheetState(() {}),
              decoration: InputDecoration(
                hintText: 'Describe what happened...',
                helperText:
                    '${_descriptionController.text.trim().length}/'
                    '$conductReportMinDescriptionLength',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Severity',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final severity in ConductSeverity.values)
                  ChoiceChip(
                    key: ValueKey('severityChip_${severity.name}'),
                    label: Text(conductSeverityLabels[severity]!),
                    selected: _severity == severity,
                    onSelected: (_) =>
                        setSheetState(() => _severity = severity),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            CheckboxListTile(
              key: const ValueKey('relationshipDisclosureCheckbox'),
              value: _relationshipDisclosed,
              onChanged: (v) =>
                  setSheetState(() => _relationshipDisclosed = v ?? false),
              title: const Text('I follow this player/team socially'),
              subtitle: const Text(
                'Auto-discloses a relationship tag on the report',
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              key: const ValueKey('submitConductReportButton'),
              onPressed: _canSubmit ? _submit : null,
              child: const Text('Submit -- goes to organizer review'),
            ),
          ],
        ),
      ),
    );
  }
}
