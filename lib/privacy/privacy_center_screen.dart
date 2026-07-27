import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_dropdown_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'privacy_models.dart';
import 'privacy_provider.dart';

/// PRD §17 (Privacy): "Model: every surface has an audience dial
/// (Everyone -> Members -> Followers -> Teammates/Friends -> Only me),
/// sensible defaults per sensitivity, previews to verify, and minors
/// get locked-stricter defaults." Reuses the real AppDropdownField (DS
/// §3.7: bottom-sheet select) per row rather than a custom picker.
class PrivacyCenterScreen extends ConsumerWidget {
  const PrivacyCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(privacyProvider);
    final notifier = ref.read(privacyProvider.notifier);

    final rankedStatsWarning =
        state.viewerIsRankedPlayer &&
        state.settings[PrivacySurface.statistics] == AudienceLevel.onlyMe;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy center')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Preview as',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppDropdownField<AudienceLevel>(
            key: const ValueKey('previewAsDropdown'),
            label: 'Viewing as',
            value: state.previewAsLevel,
            options: AudienceLevel.values,
            labelBuilder: (l) => audienceLevelLabels[l]!,
            onChanged: notifier.setPreviewAsLevel,
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(
            key: const ValueKey('viewerIsMinorSwitch'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Minor account (QA)'),
            subtitle: const Text('Applies locked-stricter defaults'),
            value: state.viewerIsMinor,
            onChanged: notifier.setViewerIsMinor,
          ),
          SwitchListTile(
            key: const ValueKey('viewerIsRankedPlayerSwitch'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Ranked player (QA)'),
            subtitle: const Text('Shows the leaderboard fairness-rule warning'),
            value: state.viewerIsRankedPlayer,
            onChanged: notifier.setViewerIsRankedPlayer,
          ),
          if (rankedStatsWarning)
            Container(
              key: const ValueKey('rankedStatsFairnessWarning'),
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Setting Statistics to Only me removes you from public '
                'leaderboards -- ranked players\' ranking stats must stay '
                'public.',
                style: AppTypography.caption.copyWith(color: colors.warning),
              ),
            ),
          for (final config in privacySurfaceConfigs)
            Padding(
              key: ValueKey('privacyRow_${config.surface.name}'),
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          privacySurfaceLabels[config.surface]!,
                          style: AppTypography.body.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        notifier.visibleInPreview(config.surface)
                            ? Icons.visibility
                            : Icons.visibility_off,
                        size: 16,
                        color: colors.textTertiary,
                      ),
                    ],
                  ),
                  if (config.rulesNote != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        config.rulesNote!,
                        style: AppTypography.caption.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  if (config.isHardRuleLocked)
                    Chip(
                      key: ValueKey(
                        'hardRuleLockedChip_${config.surface.name}',
                      ),
                      avatar: const Icon(Icons.lock, size: 14),
                      label: const Text('Locked -- hard rule'),
                    )
                  else
                    AppDropdownField<AudienceLevel>(
                      label: 'Visible to',
                      value: state.settings[config.surface],
                      options: config.allowedLevels,
                      labelBuilder: (l) => audienceLevelLabels[l]!,
                      onChanged: (level) =>
                          notifier.setLevel(config.surface, level),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
