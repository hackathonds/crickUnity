import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../profile/achievements_wall_screen.dart';
import 'achievements_models.dart';
import 'achievements_provider.dart';

/// E6-04 "engine surfaces" -- same minimal-reachable-surface convention
/// as rewards_summary_screen.dart (E6-01)/streaks_summary_screen.dart
/// (E6-02): shows the 3 tiered badges' live counters/tiers/history, a
/// debug control for the one counter with no real source module yet
/// (Ground Collector -- no Ground/booking module exists), and a link
/// into the existing E2-05 AchievementsWallScreen fed with live data.
class BadgeEngineScreen extends ConsumerWidget {
  const BadgeEngineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(achievementsProvider);
    final notifier = ref.read(achievementsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Badge engine'),
        actions: [
          IconButton(
            key: const ValueKey('viewAchievementsWallButton'),
            icon: const Icon(Icons.grid_view_outlined),
            tooltip: 'Achievements wall',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    AchievementsWallScreen(badges: dataDrivenBadges(state)),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          for (final id in TieredBadgeId.values)
            _TieredBadgeCard(id: id, progress: state.progressFor(id)),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            key: const ValueKey('recordGroundVisitButton'),
            variant: AppButtonVariant.secondary,
            label: 'Record ground visit (debug -- Ground module not built)',
            fullWidth: true,
            onPressed: notifier.recordGroundVisited,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Timeline',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (state.timeline.isEmpty)
            Text(
              'No badge tier-ups yet.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else
            for (final entry in state.timeline.reversed)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs / 2,
                ),
                child: Text(
                  entry,
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _TieredBadgeCard extends StatelessWidget {
  final TieredBadgeId id;
  final TieredBadgeProgress progress;

  const _TieredBadgeCard({required this.id, required this.progress});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final name = tieredBadgeNames[id]!;
    final tier = progress.tierAt(id);
    final next = progress.nextTierFor(id);

    return Container(
      key: ValueKey('tieredBadgeCard_${id.name}'),
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
            name,
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            tier == null
                ? 'No tier yet · ${progress.counter} so far'
                : '${tier.label} tier · ${progress.counter} so far',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
          if (next != null) ...[
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (progress.counter / next.threshold).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: colors.border,
                color: colors.coin,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Next: ${next.label} at ${next.threshold}',
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}
