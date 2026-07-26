import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'selection_board_models.dart';
import 'selection_board_provider.dart';

/// DS §7 screen 14 (Selection Board, captain/VC): "Two panes: Available
/// pool (top, chips-grid of Player Cards mini) / XI list (bottom,
/// drag-target slots 56 numbered 1–11 +12th); drag with lift+haptic;
/// role-balance meter strip (WK/bowler counts) warns amber; {Publish
/// lineup} sticky primary; post-lock entry switches to Replacement flow
/// banner."
///
/// No real Match/Create-match flow exists yet (E4-01, a separate future
/// epic) -- this uses a self-contained mock squad pool rather than a
/// real match's roster; the selection *mechanics* are this story's own
/// scope.
class SelectionBoardScreen extends ConsumerWidget {
  const SelectionBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(selectionBoardProvider);
    final notifier = ref.read(selectionBoardProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Selection board')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  'Available pool',
                  style: AppTypography.label.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final player in state.pool)
                      Draggable<PlayerCandidate>(
                        key: ValueKey('poolCard_${player.name}'),
                        data: player,
                        onDragStarted: () => HapticFeedback.lightImpact(),
                        feedback: Material(
                          color: Colors.transparent,
                          child: _PlayerChip(player: player, dragging: true),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: _PlayerChip(player: player),
                        ),
                        child: _PlayerChip(player: player),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                Container(
                  key: const ValueKey('roleBalanceMeter'),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: state.hasWicketKeeper
                        ? colors.surfaceAlt
                        : colors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    state.hasWicketKeeper
                        ? 'Wicketkeeper selected'
                        : 'No wicketkeeper selected',
                    style: AppTypography.caption.copyWith(
                      color: state.hasWicketKeeper
                          ? colors.textSecondary
                          : colors.warning,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Playing XI',
                  style: AppTypography.label.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (var i = 0; i < xiSlotCount; i++)
                      _XiSlot(index: i, player: state.xi[i]),
                  ],
                ),
                if (state.locked) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  const _ReplacementFlowBanner(),
                ],
              ],
            ),
          ),
          if (!state.locked)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  AppButton(
                    key: const ValueKey('publishLineupButton'),
                    variant: AppButtonVariant.primary,
                    label: state.published ? 'Published' : 'Publish lineup',
                    fullWidth: true,
                    onPressed: state.canPublish ? notifier.publishLineup : null,
                  ),
                  if (state.published) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      key: const ValueKey('lockAtTossButton'),
                      variant: AppButtonVariant.secondary,
                      label: 'Lock at toss',
                      fullWidth: true,
                      onPressed: notifier.lockAtToss,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  final PlayerCandidate player;
  final bool dragging;

  const _PlayerChip({required this.player, this.dragging = false});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: dragging ? Border.all(color: colors.primary) : null,
      ),
      child: Text(
        player.name,
        style: AppTypography.body.copyWith(color: colors.textPrimary),
      ),
    );
  }
}

class _XiSlot extends ConsumerWidget {
  final int index;
  final PlayerCandidate? player;

  const _XiSlot({required this.index, required this.player});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final notifier = ref.read(selectionBoardProvider.notifier);
    final label = index == xiSlotCount - 1 ? '12th' : '${index + 1}';

    return DragTarget<PlayerCandidate>(
      onWillAcceptWithDetails: (details) => player == null,
      onAcceptWithDetails: (details) =>
          notifier.selectToSlot(details.data, index),
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          key: ValueKey('xiSlot_$index'),
          onTap: player != null ? () => notifier.removeFromSlot(index) : null,
          child: Container(
            width: 72,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: candidateData.isNotEmpty
                  ? colors.primary.withValues(alpha: 0.15)
                  : colors.surfaceAlt,
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              player?.name ?? label,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: colors.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}

class _ReplacementFlowBanner extends ConsumerStatefulWidget {
  const _ReplacementFlowBanner();

  @override
  ConsumerState<_ReplacementFlowBanner> createState() =>
      _ReplacementFlowBannerState();
}

class _ReplacementFlowBannerState
    extends ConsumerState<_ReplacementFlowBanner> {
  String? _outgoing;
  String? _incoming;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(selectionBoardProvider);
    final notifier = ref.read(selectionBoardProvider.notifier);

    return Container(
      key: const ValueKey('replacementFlowBanner'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lineup locked -- replacements need opponent-captain '
            'acknowledgment.',
            style: AppTypography.subtitle.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final player in state.xi)
                if (player != null)
                  ChoiceChip(
                    key: ValueKey('replaceOutgoing_${player.name}'),
                    label: Text(player.name),
                    selected: _outgoing == player.name,
                    onSelected: (_) => setState(() => _outgoing = player.name),
                  ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final player in state.pool)
                ChoiceChip(
                  key: ValueKey('replaceIncoming_${player.name}'),
                  label: Text(player.name),
                  selected: _incoming == player.name,
                  onSelected: (_) => setState(() => _incoming = player.name),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            key: const ValueKey('replacementReasonField'),
            label: 'Reason',
            controller: _reasonController,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            key: const ValueKey('submitReplacementButton'),
            variant: AppButtonVariant.primary,
            label: 'Request replacement',
            fullWidth: true,
            onPressed: _outgoing != null && _incoming != null
                ? () {
                    notifier.requestReplacement(
                      outgoingName: _outgoing!,
                      incomingName: _incoming!,
                      reason: _reasonController.text,
                    );
                    setState(() {
                      _outgoing = null;
                      _incoming = null;
                      _reasonController.clear();
                    });
                  }
                : null,
          ),
          for (final request in state.replacementRequests)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${request.outgoingName} -> ${request.incomingName}'
                      '${request.acknowledged ? ' (acknowledged)' : ''}',
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  if (!request.acknowledged)
                    AppButton(
                      key: ValueKey('acknowledgeReplacement_${request.id}'),
                      variant: AppButtonVariant.tertiary,
                      label: 'Acknowledge',
                      onPressed: () =>
                          notifier.acknowledgeReplacement(request.id),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
