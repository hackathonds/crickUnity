import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'gig_board_models.dart';
import 'gig_board_provider.dart';

/// DS §11.4 (Officials suite) Gig Board. PRD §2.6/§2.7: scorers and
/// umpires both browse the same board, scoped by [role].
class GigBoardScreen extends ConsumerWidget {
  final OfficialRole role;

  const GigBoardScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(gigBoardProvider);
    final notifier = ref.read(gigBoardProvider.notifier);
    final gigs = state.filtered.where((g) => g.role == role).toList();

    return Scaffold(
      appBar: AppBar(title: Text('${officialRoleLabels[role]} gig board')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Within ${state.filters.maxDistanceKm.round()} km',
                  style: AppTypography.label.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
                Slider(
                  key: const ValueKey('gigDistanceSlider'),
                  value: state.filters.maxDistanceKm,
                  min: 5,
                  max: 50,
                  divisions: 9,
                  onChanged: (v) => notifier.updateFilters(
                    state.filters.copyWith(maxDistanceKm: v),
                  ),
                ),
                Text(
                  'Min fee: ₹${state.filters.minFeeRupees}',
                  style: AppTypography.label.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
                Slider(
                  key: const ValueKey('gigMinFeeSlider'),
                  value: state.filters.minFeeRupees.toDouble(),
                  min: 0,
                  max: 1500,
                  divisions: 15,
                  onChanged: (v) => notifier.updateFilters(
                    state.filters.copyWith(minFeeRupees: v.round()),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: gigs.isEmpty
                ? _EmptyState(onWidenRadius: notifier.widenRadius)
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    children: [
                      for (final gig in gigs)
                        _GigCard(
                          key: ValueKey('gigCard_${gig.id}'),
                          gig: gig,
                          accepted: state.acceptedGigIds.contains(gig.id),
                          onAccept: () => _accept(context, notifier, gig),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _accept(
    BuildContext context,
    GigBoardNotifier notifier,
    GigListing gig,
  ) {
    notifier.accept(gig.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Accepted -- added to your calendar (${gig.matchLabel})'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onWidenRadius;

  const _EmptyState({required this.onWidenRadius});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No gigs match your filters.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              key: const ValueKey('gigWidenRadiusButton'),
              onPressed: onWidenRadius,
              child: const Text('Widen radius by 10 km'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GigCard extends StatelessWidget {
  final GigListing gig;
  final bool accepted;
  final VoidCallback onAccept;

  const _GigCard({
    super.key,
    required this.gig,
    required this.accepted,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            gig.matchLabel,
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            gig.teamsLine,
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${gig.groundName} -- ${gig.distanceKm.toStringAsFixed(0)} km',
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                '₹${gig.feeRupees}',
                style: AppTypography.stat.copyWith(
                  color: colors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              TextButton(onPressed: () {}, child: const Text('Details')),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                key: ValueKey('acceptGigButton_${gig.id}'),
                onPressed: accepted ? null : onAccept,
                child: Text(accepted ? 'Accepted' : 'Accept'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
