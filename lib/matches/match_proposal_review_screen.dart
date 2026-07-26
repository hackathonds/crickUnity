import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'match_models.dart';
import 'matches_provider.dart';

/// AC: "Given opponent proposes a change, Then I see a field-level diff
/// and one-tap accept." This is the composer's screen for that.
class MatchProposalReviewScreen extends ConsumerWidget {
  final String matchId;

  const MatchProposalReviewScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final match = ref
        .watch(matchesProvider)
        .matches
        .firstWhere((m) => m.id == matchId);

    if (match.status != MatchStatus.changesProposedToComposer) {
      return Scaffold(
        appBar: AppBar(title: const Text('Proposed changes')),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Text(
            key: const ValueKey('proposalReviewNoChangesState'),
            match.status == MatchStatus.accepted
                ? 'This match is confirmed -- no changes pending.'
                : 'No proposed changes are pending for this match.',
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
        ),
      );
    }

    final diffRows = <(String, String, String)>[
      if (match.proposedGroundName != null &&
          match.proposedGroundName != match.draft.groundName)
        ('Ground', match.draft.groundName, match.proposedGroundName!),
      if (match.proposedDateTime != null &&
          match.proposedDateTime != match.draft.dateTime)
        (
          'Date/time',
          _formatDateTime(match.draft.dateTime),
          _formatDateTime(match.proposedDateTime!),
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Proposed changes')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${match.composerTeamName}\'s opponent proposed:',
              style: AppTypography.subtitle.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final (label, oldValue, newValue) in diffRows)
              Container(
                key: ValueKey('diffRow_$label'),
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
                      label,
                      style: AppTypography.label.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                    Text(
                      oldValue,
                      style: AppTypography.body.copyWith(
                        color: colors.textTertiary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      newValue,
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            AppButton(
              key: const ValueKey('acceptProposedChangesButton'),
              variant: AppButtonVariant.primary,
              label: 'Accept changes',
              fullWidth: true,
              onPressed: () => ref
                  .read(matchesProvider.notifier)
                  .acceptProposedChanges(matchId),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}
