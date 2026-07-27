import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'commentator_room_models.dart';
import 'commentator_room_provider.dart';

/// DS §11.4: "Commentator room: stream-audio status tile, [Mark moment]
/// oversized 64 primary (feeds highlights), marker history list,
/// mute-self toggle; assigned-only access, denied state explains
/// assigner path." See commentator_room_models.dart's top-of-file note
/// on this being the *only* real spec text for the whole feature.
class CommentatorRoomScreen extends ConsumerWidget {
  const CommentatorRoomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(commentatorRoomProvider);
    final notifier = ref.read(commentatorRoomProvider.notifier);

    if (!state.isAssigned) {
      return Scaffold(
        appBar: AppBar(title: const Text('Commentator room')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 40, color: colors.textTertiary),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'You are not assigned to commentate this match.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Ask the tournament organizer or team captain to assign '
                  'you as commentator.',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  key: const ValueKey('debugSimulateAssignedButton'),
                  onPressed: () => notifier.setAssigned(true),
                  child: const Text('(QA) Simulate assignment'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Commentator room')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            key: const ValueKey('streamAudioStatusTile'),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  state.audioStatus == StreamAudioStatus.live
                      ? Icons.podcasts
                      : Icons.mic_off,
                  color: state.audioStatus == StreamAudioStatus.live
                      ? colors.live
                      : colors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    streamAudioStatusLabels[state.audioStatus]!,
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Switch(
                  key: const ValueKey('muteSelfToggle'),
                  value: state.audioStatus == StreamAudioStatus.muted,
                  onChanged: (_) => notifier.toggleMuteSelf(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: SizedBox(
              width: 64,
              height: 64,
              child: FilledButton(
                key: const ValueKey('markMomentButton'),
                onPressed: notifier.markMoment,
                style: FilledButton.styleFrom(shape: const CircleBorder()),
                child: const Icon(Icons.bolt, size: 28),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'Mark moment',
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Marker history',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.markers.isEmpty)
            Text(
              'No moments marked yet.',
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            )
          else
            for (final marker in state.markers)
              Padding(
                key: ValueKey('momentMarkerRow_${marker.markedAt}'),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ball ${marker.ballIndex}',
                        style: AppTypography.body.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${marker.markedAt.hour.toString().padLeft(2, '0')}:'
                      '${marker.markedAt.minute.toString().padLeft(2, '0')}',
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
