import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'scoring_models.dart';
import 'scoring_provider.dart';

/// PRD §7.16: "MVP auto-suggested (performance-index) but decided by:
/// opposing captain pick (preferred, prompts them) or auto. Additional:
/// Best Batter/Bowler/Fielder optional. Awards mint profile entries +
/// coins." No dedicated DS screen anatomy exists for Awards -- it's
/// folded into Post-Match Summary's MVP card (DS §7-30), which this
/// screen is reached from via an "Awards" link. Layout follows the same
/// card conventions as the rest of that screen for consistency.
class AwardsScreen extends ConsumerWidget {
  /// Whether the viewer is the opposing captain -- only they get the
  /// "Pick MVP" action; everyone else sees a read-only view.
  final bool isOpposingCaptain;

  const AwardsScreen({super.key, required this.isOpposingCaptain});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(inningsProvider);
    final notifier = ref.read(inningsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Awards')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _AwardCard(
            key: const ValueKey('mvpAwardCard'),
            label: awardTypeLabels[AwardType.mvp]!,
            name: state.finalMvp,
            caption: state.mvpIsCaptainPick
                ? 'Picked by opposing captain'
                : 'Auto-suggested (performance-index)',
            trailing: isOpposingCaptain
                ? AppButton(
                    key: const ValueKey('pickMvpButton'),
                    variant: AppButtonVariant.secondary,
                    label: 'Pick MVP',
                    onPressed: () => _showPickMvpSheet(context, state),
                  )
                : null,
          ),
          _AwardCard(
            key: const ValueKey('bestBatterAwardCard'),
            label: awardTypeLabels[AwardType.bestBatter]!,
            name: state.bestBatterName ?? '-',
            caption: 'Auto-suggested',
          ),
          _AwardCard(
            key: const ValueKey('bestBowlerAwardCard'),
            label: awardTypeLabels[AwardType.bestBowler]!,
            name: state.bestBowlerName ?? '-',
            caption: 'Auto-suggested',
          ),
          _AwardCard(
            key: const ValueKey('bestFielderAwardCard'),
            label: awardTypeLabels[AwardType.bestFielder]!,
            name: state.bestFielderName ?? '-',
            caption: 'Auto-suggested',
          ),
          const SizedBox(height: AppSpacing.lg),
          if (state.awardsMinted)
            Container(
              key: const ValueKey('awardsMintedCard'),
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.coin.withValues(alpha: 0.12),
                border: Border.all(color: colors.coin),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Minted',
                    style: AppTypography.title.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final entry in state.awardsLog)
                    Text(
                      '• $entry',
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            )
          else
            AppButton(
              key: const ValueKey('mintAwardsButton'),
              variant: AppButtonVariant.primary,
              label: 'Mint awards',
              fullWidth: true,
              onPressed: state.rippleFired
                  ? notifier.mintAwards
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Awards mint once the scorecard is fully '
                          'confirmed (PRD §13 anti-fraud gate).',
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  void _showPickMvpSheet(BuildContext context, InningsState state) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Pick MVP',
      contentBuilder: (context) =>
          _PickMvpSheetContent(candidates: state.battingOrder),
    );
  }
}

class _AwardCard extends StatelessWidget {
  final String label;
  final String name;
  final String caption;
  final Widget? trailing;

  const _AwardCard({
    super.key,
    required this.label,
    required this.name,
    required this.caption,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
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
                  name,
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
                Text(
                  caption,
                  style: AppTypography.caption.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Plain rows rather than [ListTile], matching this codebase's
/// established sheet-content convention.
class _PickMvpSheetContent extends ConsumerWidget {
  final List<String> candidates;

  const _PickMvpSheetContent({required this.candidates});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final name in candidates)
            GestureDetector(
              key: ValueKey('mvpCandidate_$name'),
              behavior: HitTestBehavior.opaque,
              onTap: () {
                ref.read(inningsProvider.notifier).pickMvp(name);
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  name,
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
