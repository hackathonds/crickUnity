import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_state_scaffolds.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'peer_rating_models.dart';
import 'peer_rating_provider.dart';

/// PRD §6.27: aggregate is "visible to rated player only... after >=3
/// raters"; the same aggregate rolls into "a private 'coach's view' for
/// Captain" -- one screen, two viewer contexts, matching how this app
/// renders every other viewer-relative screen (e.g. [InsightsScreen]).
enum PeerRatingViewerRole { self, captain }

class PeerRatingAggregateScreen extends ConsumerWidget {
  final PeerRatingViewerRole mode;
  final bool viewerIsCaptain;

  /// Rated player to show, in [PeerRatingViewerRole.self] mode.
  final String? selfPlayerName;

  /// Full team roster to show, in [PeerRatingViewerRole.captain] mode.
  final List<String> teamRoster;

  const PeerRatingAggregateScreen({
    super.key,
    required this.mode,
    required this.viewerIsCaptain,
    this.selfPlayerName,
    this.teamRoster = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = mode == PeerRatingViewerRole.self
        ? 'Your peer rating'
        : 'Team ratings (Captain)';

    if (mode == PeerRatingViewerRole.captain && !viewerIsCaptain) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppEmptyState(
            key: const ValueKey('peerRatingPermissionDenied'),
            message: 'Team ratings are only visible to your team\'s Captain.',
            primaryLabel: 'Back',
            onPrimary: () => Navigator.of(context).maybePop(),
          ),
        ),
      );
    }

    final ratings = ref.watch(peerRatingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: mode == PeerRatingViewerRole.self
          ? _buildSelf(context, ratings)
          : _buildCaptain(context, ratings),
    );
  }

  Widget _buildSelf(BuildContext context, List<PeerRating> ratings) {
    final aggregate = aggregateRatingsFor(selfPlayerName!, ratings);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: _AggregateCard(aggregate: aggregate),
    );
  }

  Widget _buildCaptain(BuildContext context, List<PeerRating> ratings) {
    if (teamRoster.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: AppEmptyState(
          key: const ValueKey('peerRatingCaptainEmpty'),
          message: 'No roster to rate yet.',
          primaryLabel: 'Back',
          onPrimary: () => Navigator.of(context).maybePop(),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        for (final player in teamRoster)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: _AggregateCard(
              key: ValueKey('captainAggregateCard_$player'),
              playerLabel: player,
              aggregate: aggregateRatingsFor(player, ratings),
            ),
          ),
      ],
    );
  }
}

class _AggregateCard extends StatelessWidget {
  final AggregatedPlayerRating aggregate;
  final String? playerLabel;

  const _AggregateCard({super.key, required this.aggregate, this.playerLabel});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (playerLabel != null) ...[
            Text(
              playerLabel!,
              style: AppTypography.subtitle.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (!aggregate.isRevealed)
            Text(
              'Ratings unlock after 3 teammates rate -- '
              '${aggregate.ratersCount}/$peerRatingAnonymityThreshold so far.',
              key: const ValueKey('peerRatingPreThreshold'),
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            )
          else ...[
            Row(
              key: const ValueKey('peerRatingRevealedStars'),
              children: [
                for (var i = 1; i <= 5; i++)
                  Icon(
                    i <= aggregate.averageStars!.round()
                        ? Icons.star
                        : Icons.star_border,
                    size: 20,
                    color: i <= aggregate.averageStars!.round()
                        ? colors.coin
                        : colors.textTertiary,
                  ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  aggregate.averageStars!.toStringAsFixed(1),
                  style: AppTypography.stat.copyWith(color: colors.textPrimary),
                ),
              ],
            ),
            if (aggregate.topTags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final tag in aggregate.topTags)
                    AppTagChip(label: tag, variant: AppTagChipVariant.neutral),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
