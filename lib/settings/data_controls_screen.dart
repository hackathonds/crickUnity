import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'data_controls_models.dart';
import 'data_controls_provider.dart';

/// PRD §17 "Data controls": view/download my data summary, deactivate,
/// delete account.
class DataControlsScreen extends ConsumerWidget {
  const DataControlsScreen({super.key});

  void _exportData(BuildContext context, DataExportSummary summary) {
    final lines = [
      'My CricUnity data summary',
      'Posts: ${summary.postsCount}',
      'Matches played: ${summary.matchesPlayed}',
      'Expenses tracked: ${summary.expensesTracked}',
      'Coins earned (lifetime): ${summary.coinsEarnedLifetime}',
      'Followers: ${summary.followersCount}',
    ];
    Clipboard.setData(ClipboardData(text: lines.join('\n')));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Data summary copied')));
  }

  void _confirmDeactivate(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate account?'),
        content: const Text(
          'Your profile will be hidden. Your stats are preserved in '
          'opponents\' verified records as "Deactivated player" -- a '
          'competitive-integrity rule disclosed at signup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('confirmDeactivateButton'),
            onPressed: () {
              ref.read(dataControlsProvider.notifier).deactivate();
              Navigator.of(context).pop();
            },
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          '$deletionGraceDays-day grace period, then personal content is '
          'removed. Verified scorecard lines persist anonymized, since a '
          'match\'s opponents own the shared record too.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('confirmDeleteButton'),
            onPressed: () {
              ref.read(dataControlsProvider.notifier).requestDeletion();
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(dataControlsProvider);
    final notifier = ref.read(dataControlsProvider.notifier);

    Widget sectionLabel(String text) => Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm,
        top: AppSpacing.xxl,
      ),
      child: Text(
        text,
        style: AppTypography.label.copyWith(color: colors.textTertiary),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Data controls')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (state.status == AccountLifecycleStatus.deactivated)
            Container(
              key: const ValueKey('deactivatedBanner'),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Your account is deactivated.',
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('reactivateButton'),
                    onPressed: notifier.reactivate,
                    child: const Text('Reactivate'),
                  ),
                ],
              ),
            ),
          if (state.status == AccountLifecycleStatus.pendingDeletion)
            Container(
              key: const ValueKey('pendingDeletionBanner'),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deletion scheduled for '
                    '${state.deletionCompletesAt!.toLocal().toString().split(' ').first}.',
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  OutlinedButton(
                    key: const ValueKey('cancelDeletionButton'),
                    onPressed: notifier.cancelDeletion,
                    child: const Text('Cancel deletion'),
                  ),
                ],
              ),
            ),
          sectionLabel('My data'),
          OutlinedButton(
            key: const ValueKey('exportDataButton'),
            onPressed: () => _exportData(context, state.exportSummary),
            child: const Text('View / download my data summary'),
          ),
          sectionLabel('Deactivate'),
          Text(
            'Hide your profile. Stats stay in opponents\' verified '
            'records as "Deactivated player."',
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            key: const ValueKey('deactivateButton'),
            onPressed: state.status == AccountLifecycleStatus.active
                ? () => _confirmDeactivate(context, ref)
                : null,
            child: const Text('Deactivate account'),
          ),
          sectionLabel('Delete account'),
          Text(
            '$deletionGraceDays-day grace period. Personal content is '
            'removed; verified scorecard lines persist anonymized.',
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            key: const ValueKey('deleteAccountButton'),
            onPressed: state.status == AccountLifecycleStatus.pendingDeletion
                ? null
                : () => _confirmDelete(context, ref),
            style: OutlinedButton.styleFrom(foregroundColor: colors.error),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
  }
}
