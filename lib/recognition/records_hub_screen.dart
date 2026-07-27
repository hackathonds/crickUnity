import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_segmented_control.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'record_models.dart';
import 'records_provider.dart';

/// Backlog (E8-02): "Records hub ... Appx F categories data-driven,
/// vacant 'be first', provenance links, live approach alerts, record-
/// transfer flow with respectful prior-holder notice." See
/// record_models.dart's top-of-file note: "Appx F" doesn't exist in the
/// frozen PRD, so the category list here is a flagged curated stand-in.
class RecordsHubScreen extends ConsumerStatefulWidget {
  const RecordsHubScreen({super.key});

  @override
  ConsumerState<RecordsHubScreen> createState() => _RecordsHubScreenState();
}

class _RecordsHubScreenState extends ConsumerState<RecordsHubScreen> {
  RecordScope _scope = RecordScope.ground;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final records = ref
        .watch(recordsProvider)
        .records
        .where((r) => r.scope == _scope)
        .toList();
    final notifier = ref.read(recordsProvider.notifier);
    final approaching = notifier.approachingRecord();

    return Scaffold(
      appBar: AppBar(title: const Text('Records')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppSegmentedControl<RecordScope>(
            key: const ValueKey('recordScopeSelector'),
            options: RecordScope.values,
            value: _scope,
            onChanged: (v) => setState(() => _scope = v),
            labelBuilder: (s) => recordScopeLabels[s]!,
          ),
          if (approaching != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              key: const ValueKey('nearRecordAlertBanner'),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.live.withValues(alpha: 0.12),
                border: Border.all(color: colors.live),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Approaching the ${approaching.scopeLabel} record for '
                '${recordCategoryLabels[approaching.category]} '
                '(${approaching.value}) -- live!',
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          for (final record in records)
            Container(
              key: ValueKey(
                'recordCard_${record.category.name}_${record.scope.name}',
              ),
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
                    recordCategoryLabels[record.category]!,
                    style: AppTypography.label.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (record.isVacant)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Vacant -- be the first!',
                            style: AppTypography.body.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                        AppButton(
                          key: ValueKey(
                            'setFirstRecordButton_${record.category.name}',
                          ),
                          variant: AppButtonVariant.tertiary,
                          label: 'Simulate first (debug)',
                          onPressed: () => notifier.transferRecord(
                            record.category,
                            record.scope,
                            'Deepak Sharma',
                            50,
                            provenanceLabel: 'Simulated debug entry',
                          ),
                        ),
                      ],
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${record.holderName} -- ${record.value}',
                            style: AppTypography.stat.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        AppButton(
                          key: ValueKey(
                            'transferRecordButton_${record.category.name}',
                          ),
                          variant: AppButtonVariant.tertiary,
                          label: 'Beat it (debug)',
                          onPressed: () => notifier.transferRecord(
                            record.category,
                            record.scope,
                            'Deepak Sharma',
                            record.value + 1,
                            provenanceLabel: 'Simulated debug entry',
                          ),
                        ),
                      ],
                    ),
                    if (record.provenanceLabel != null)
                      GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Would open match provenance'),
                          ),
                        ),
                        child: Text(
                          record.provenanceLabel!,
                          style: AppTypography.caption.copyWith(
                            color: colors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                  ],
                  if (record.transferHistory.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        record.transferHistory.last.priorHolderNotice,
                        style: AppTypography.caption.copyWith(
                          color: colors.textTertiary,
                        ),
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
