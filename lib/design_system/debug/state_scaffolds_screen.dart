import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../offline/is_online_provider.dart';
import '../../offline/queued_action.dart';
import '../components/app_pending_pill.dart';
import '../components/app_state_scaffolds.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// QA tool for E0-06: view each state scaffold, toggle simulated
/// connectivity, and submit queued actions to see the pending-pill →
/// resolved/error sequence — this story's AC.
class StateScaffoldsScreen extends ConsumerWidget {
  const StateScaffoldsScreen({super.key});

  void _push(BuildContext context, String title, Widget body) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: body,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isOnline = ref.watch(isOnlineProvider);
    final queued = ref.watch(queuedActionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('State scaffolds (QA)')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Scaffolds',
            style: AppTypography.h2.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            onPressed: () => _push(
              context,
              'Empty',
              AppEmptyState(
                message: 'No upcoming matches — find a game or create one.',
                primaryLabel: 'Find a game',
                onPrimary: () {},
                tertiaryLabel: 'Create a match',
                onTertiary: () {},
              ),
            ),
            child: const Text('View Empty state'),
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            onPressed: () => _push(
              context,
              'Loading — list',
              const AppLoadingState(shape: AppSkeletonShape.list),
            ),
            child: const Text('View Loading state (list)'),
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            onPressed: () => _push(
              context,
              'Loading — card',
              const AppLoadingState(shape: AppSkeletonShape.card),
            ),
            child: const Text('View Loading state (card)'),
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            onPressed: () => _push(
              context,
              'Error',
              AppErrorState(
                message: "Couldn't load your matches.",
                onRetry: () {},
                onReportProblem: () {},
              ),
            ),
            child: const Text('View Error state'),
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            onPressed: () => _push(
              context,
              'Error — offline',
              AppErrorState(
                message: "You're offline.",
                onRetry: () {},
                isOffline: true,
                lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
              ),
            ),
            child: const Text('View Error state (offline)'),
          ),
          const Divider(height: AppSpacing.xxl),
          Text(
            'Connectivity',
            style: AppTypography.h2.copyWith(color: colors.textPrimary),
          ),
          SwitchListTile(
            title: const Text('Online'),
            value: isOnline,
            onChanged: (value) =>
                ref.read(isOnlineProvider.notifier).state = value,
          ),
          const Divider(height: AppSpacing.xxl),
          Text(
            'Queued actions',
            style: AppTypography.h2.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            onPressed: () => ref
                .read(queuedActionsProvider.notifier)
                .submit(
                  label: 'Availability: Yes (Sun match)',
                  isMoneyAction: false,
                  perform: () async {
                    await Future.delayed(const Duration(milliseconds: 400));
                  },
                ),
            child: const Text('Submit availability response'),
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            onPressed: () => ref
                .read(queuedActionsProvider.notifier)
                .submit(
                  label: 'Pay ground fee ₹300',
                  isMoneyAction: true,
                  perform: () async {
                    await Future.delayed(const Duration(milliseconds: 400));
                  },
                ),
            child: const Text('Submit payment (money action)'),
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            onPressed: () => ref
                .read(queuedActionsProvider.notifier)
                .submit(
                  label: 'Sync a note (will fail)',
                  isMoneyAction: false,
                  perform: () async {
                    await Future.delayed(const Duration(milliseconds: 400));
                    throw Exception('simulated failure');
                  },
                ),
            child: const Text('Submit an action that will fail on resolve'),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final action in queued)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppPendingPill(
                action: action,
                onRetry: () =>
                    ref.read(queuedActionsProvider.notifier).retry(action.id),
              ),
            ),
        ],
      ),
    );
  }
}
