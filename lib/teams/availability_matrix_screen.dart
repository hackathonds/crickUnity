import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'availability_matrix_models.dart';
import 'availability_matrix_provider.dart';

const double _headerRowHeight = 56;
const double _cellRowHeight = 44;
const double _footerRowHeight = 32;
const double _eventColumnWidth = 120;
const double _nameColumnWidth = 120;

/// DS §7 screen 13 (Availability Matrix, captain/VC): "Sticky first
/// column names, columns=events, cells 44 tri-state glyphs; tap cell =
/// detail popover; header per column [Nudge pending] (disabled if <12h
/// since last, tooltip why); footer summary '9 ✔ · 3 ❓ · 2 ✖'."
class AvailabilityMatrixScreen extends ConsumerWidget {
  final DateTime Function() now;

  const AvailabilityMatrixScreen({super.key, this.now = DateTime.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(availabilityMatrixProvider);
    final notifier = ref.read(availabilityMatrixProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Availability matrix')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sticky first column.
            SizedBox(
              width: _nameColumnWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: _headerRowHeight),
                  for (final member in state.members)
                    SizedBox(
                      height: _cellRowHeight,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          member,
                          style: AppTypography.body.copyWith(
                            color: colors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  const SizedBox(height: _footerRowHeight),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final event in state.events)
                      _EventColumn(
                        event: event,
                        state: state,
                        canNudge: notifier.canNudge(event.id, now: now),
                        onNudge: () =>
                            notifier.nudgePending(event.id, now: now),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventColumn extends StatelessWidget {
  final AvailabilityEvent event;
  final AvailabilityMatrixState state;
  final bool canNudge;
  final VoidCallback onNudge;

  const _EventColumn({
    required this.event,
    required this.state,
    required this.canNudge,
    required this.onNudge,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    var yes = 0;
    var maybe = 0;
    var no = 0;
    for (final member in state.members) {
      switch (state.responseFor(member, event.id)) {
        case AvailabilityResponse.yes:
          yes++;
        case AvailabilityResponse.maybe:
          maybe++;
        case AvailabilityResponse.no:
          no++;
        case null:
          break;
      }
    }

    return SizedBox(
      width: _eventColumnWidth,
      child: Column(
        children: [
          SizedBox(
            height: _headerRowHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.label,
                  style: AppTypography.label.copyWith(
                    color: colors.textTertiary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Tooltip(
                  message: canNudge
                      ? 'Nudge everyone who hasn\'t responded'
                      : 'Already nudged within the last '
                            '$nudgeCooldownHours hours',
                  child: TextButton(
                    key: ValueKey('nudgeButton_${event.id}'),
                    onPressed: canNudge ? onNudge : null,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Nudge pending'),
                  ),
                ),
              ],
            ),
          ),
          for (final member in state.members)
            _ResponseCell(
              member: member,
              event: event,
              response: state.responseFor(member, event.id),
            ),
          SizedBox(
            height: _footerRowHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                key: ValueKey('matrixFooter_${event.id}'),
                '$yes ✔ · $maybe ❓ · $no ✖',
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponseCell extends StatelessWidget {
  final String member;
  final AvailabilityEvent event;
  final AvailabilityResponse? response;

  const _ResponseCell({
    required this.member,
    required this.event,
    required this.response,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return GestureDetector(
      key: ValueKey('matrixCell_${member}_${event.id}'),
      onTap: () => _showDetail(context),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _eventColumnWidth,
        height: _cellRowHeight,
        child: Center(
          child: Text(
            response != null ? availabilityResponseGlyphs[response]! : '',
            style: AppTypography.stat.copyWith(color: colors.textPrimary),
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key: const ValueKey('matrixCellDetailDialog'),
        title: Text(member),
        content: Text(
          '${event.label}: '
          '${response != null ? availabilityResponseLabels[response]! : 'No response yet'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
