import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_bottom_sheet.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'scoring_models.dart';
import 'scoring_provider.dart';

List<MapEntry<int, List<int>>> _groupIndicesByOver(List<Delivery> deliveries) {
  final groups = <int, List<int>>{};
  var legalCount = 0;
  for (var i = 0; i < deliveries.length; i++) {
    groups.putIfAbsent(legalCount ~/ 6, () => []).add(i);
    if (deliveries[i].isLegal) legalCount++;
  }
  return groups.entries.toList();
}

/// PRD §2.6 (Scorer): "edit balls within the correction window (last 2
/// overs freely; older balls require both captains' acknowledgment)."
/// Every ball ever bowled, grouped by over; tapping one outside the
/// free window opens a correction request that needs both captains'
/// acknowledgment before it applies -- one inside the window corrects
/// immediately. AC: corrected balls carry an audit marker here.
class BallTimelineScreen extends ConsumerWidget {
  const BallTimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(inningsProvider);
    final groups = _groupIndicesByOver(state.deliveries);

    return Scaffold(
      appBar: AppBar(title: const Text('Ball timeline')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (state.timelineEntries.isNotEmpty) ...[
            Text(
              'Match log',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final entry in state.timelineEntries.reversed)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  entry,
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xxl),
          ],
          if (state.pendingCorrections.isNotEmpty) ...[
            Text(
              'Pending corrections',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final request in state.pendingCorrections)
              _PendingCorrectionCard(
                request: request,
                original: state.deliveries[request.deliveryIndex],
              ),
            const SizedBox(height: AppSpacing.xxl),
          ],
          for (final group in groups)
            Padding(
              key: ValueKey('overGroup_${group.key}'),
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Over ${group.key + 1}',
                    style: AppTypography.label.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final index in group.value)
                        _BallChip(
                          index: index,
                          delivery: state.deliveries[index],
                          withinFreeWindow: state.isWithinFreeCorrectionWindow(
                            index,
                          ),
                          hasPendingCorrection: state.pendingCorrections.any(
                            (r) => r.deliveryIndex == index,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BallChip extends ConsumerWidget {
  final int index;
  final Delivery delivery;
  final bool withinFreeWindow;
  final bool hasPendingCorrection;

  const _BallChip({
    required this.index,
    required this.delivery,
    required this.withinFreeWindow,
    required this.hasPendingCorrection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return GestureDetector(
      key: ValueKey('ballChip_$index'),
      onTap: delivery.isManualSwap || hasPendingCorrection
          ? null
          : () => _showCorrectionSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: delivery.isWicket
              ? colors.error.withValues(alpha: 0.15)
              : colors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: delivery.isCorrected
              ? Border.all(color: colors.warning)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              deliveryLabel(delivery),
              style: AppTypography.caption.copyWith(
                color: delivery.isWicket ? colors.error : colors.textPrimary,
              ),
            ),
            if (delivery.isCorrected) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.edit, size: 12, color: colors.warning),
            ],
            if (hasPendingCorrection) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.hourglass_top, size: 12, color: colors.textTertiary),
            ],
          ],
        ),
      ),
    );
  }

  void _showCorrectionSheet(BuildContext context) {
    showAppBottomSheet<void>(
      context: context,
      title: withinFreeWindow ? 'Correct this ball' : 'Request correction',
      contentBuilder: (context) => _CorrectionRequestContent(
        deliveryIndex: index,
        delivery: delivery,
        withinFreeWindow: withinFreeWindow,
      ),
    );
  }
}

class _CorrectionRequestContent extends ConsumerStatefulWidget {
  final int deliveryIndex;
  final Delivery delivery;
  final bool withinFreeWindow;

  const _CorrectionRequestContent({
    required this.deliveryIndex,
    required this.delivery,
    required this.withinFreeWindow,
  });

  @override
  ConsumerState<_CorrectionRequestContent> createState() =>
      _CorrectionRequestContentState();
}

class _CorrectionRequestContentState
    extends ConsumerState<_CorrectionRequestContent> {
  late final _runsController = TextEditingController(
    text: '${widget.delivery.runs}',
  );
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _runsController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.withinFreeWindow
                ? 'Within the last 2 overs -- this applies immediately.'
                : 'Older than the last 2 overs -- both captains must '
                      'acknowledge before this applies.',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: const ValueKey('correctedRunsField'),
            label: 'Correct runs',
            controller: _runsController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            key: const ValueKey('correctionReasonField'),
            label: 'Reason',
            controller: _reasonController,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            key: const ValueKey('submitCorrectionButton'),
            variant: AppButtonVariant.primary,
            label: widget.withinFreeWindow
                ? 'Correct'
                : 'Send for acknowledgment',
            fullWidth: true,
            onPressed: () {
              ref
                  .read(inningsProvider.notifier)
                  .requestCorrection(
                    deliveryIndex: widget.deliveryIndex,
                    proposedRuns:
                        int.tryParse(_runsController.text) ??
                        widget.delivery.runs,
                    reason: _reasonController.text.trim(),
                  );
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _PendingCorrectionCard extends ConsumerWidget {
  final CorrectionRequest request;
  final Delivery original;

  const _PendingCorrectionCard({required this.request, required this.original});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final notifier = ref.read(inningsProvider.notifier);

    return Container(
      key: ValueKey('pendingCorrection_${request.deliveryIndex}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${original.runs} -> ${request.proposedRuns} runs',
            style: AppTypography.subtitle.copyWith(color: colors.textPrimary),
          ),
          Text(
            request.reason,
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  key: ValueKey('ackComposerCaptain_${request.deliveryIndex}'),
                  variant: request.composerCaptainAcked
                      ? AppButtonVariant.secondary
                      : AppButtonVariant.primary,
                  label: request.composerCaptainAcked
                      ? 'Composer acked'
                      : 'Composer captain ack',
                  onPressed: request.composerCaptainAcked
                      ? null
                      : () => notifier.acknowledgeCorrection(
                          request.deliveryIndex,
                          asComposerCaptain: true,
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  key: ValueKey('ackOpponentCaptain_${request.deliveryIndex}'),
                  variant: request.opponentCaptainAcked
                      ? AppButtonVariant.secondary
                      : AppButtonVariant.primary,
                  label: request.opponentCaptainAcked
                      ? 'Opponent acked'
                      : 'Opponent captain ack',
                  onPressed: request.opponentCaptainAcked
                      ? null
                      : () => notifier.acknowledgeCorrection(
                          request.deliveryIndex,
                          asComposerCaptain: false,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
