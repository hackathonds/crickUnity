import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../officials/gig_board_models.dart' show officialRoleLabels;
import '../officials/officials_console_models.dart'
    show CredentialTier, credentialTierLabels;
import 'officials_directory_models.dart';
import 'officials_directory_provider.dart';

/// AC amendment #11 (PRD §2.6): "tournament official filters honor
/// tier + certification." See officials_directory_models.dart's doc
/// comment for why this is a new screen rather than a retrofit.
class OfficialsDirectoryScreen extends ConsumerWidget {
  const OfficialsDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(officialsDirectoryProvider);
    final notifier = ref.read(officialsDirectoryProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Officials directory')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Role',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final role in officialRoleLabels.entries)
                ChoiceChip(
                  key: ValueKey('directoryRoleChip_${role.key.name}'),
                  label: Text(role.value),
                  selected: state.filters.role == role.key,
                  onSelected: (selected) => notifier.updateFilters(
                    (f) => f.copyWith(
                      role: selected ? role.key : null,
                      clearRole: !selected,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Minimum tier',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final tier in CredentialTier.values)
                ChoiceChip(
                  key: ValueKey('directoryTierChip_${tier.name}'),
                  label: Text(credentialTierLabels[tier]!),
                  selected: state.filters.minTier == tier,
                  onSelected: (selected) => notifier.updateFilters(
                    (f) => f.copyWith(
                      minTier: selected ? tier : null,
                      clearMinTier: !selected,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Certification',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final cert in certificationTrackLabels.entries)
                ChoiceChip(
                  key: ValueKey('directoryCertChip_${cert.key}'),
                  label: Text(cert.value),
                  selected: state.filters.requiredCertificationId == cert.key,
                  onSelected: (selected) => notifier.updateFilters(
                    (f) => f.copyWith(
                      requiredCertificationId: selected ? cert.key : null,
                      clearCertification: !selected,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (state.filtered.isEmpty)
            Text(
              'No officials match these filters.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else
            for (final official in state.filtered)
              Container(
                key: ValueKey('directoryOfficialRow_${official.name}'),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            official.name,
                            style: AppTypography.body.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            '${officialRoleLabels[official.role]} · '
                            '${credentialTierLabels[official.tier]} · '
                            '${official.averageRating} avg',
                            style: AppTypography.caption.copyWith(
                              color: colors.textSecondary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          if (official.certifiedTrackIds.isNotEmpty)
                            Text(
                              official.certifiedTrackIds
                                  .map((id) => certificationTrackLabels[id])
                                  .whereType<String>()
                                  .join(', '),
                              style: AppTypography.caption.copyWith(
                                color: colors.verified,
                              ),
                            ),
                        ],
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
