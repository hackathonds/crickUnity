import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'reel_models.dart';

class ReelsState {
  final List<Reel> reels;

  const ReelsState({this.reels = const []});

  ReelsState copyWith({List<Reel>? reels}) =>
      ReelsState(reels: reels ?? this.reels);
}

/// PRD §12.3 -- E7-04's reels engine.
class ReelsNotifier extends Notifier<ReelsState> {
  @override
  ReelsState build() => const ReelsState();

  void publishReel({
    required String authorName,
    required int durationSeconds,
    required String audioTrack,
    required bool remixAllowed,
    String? sourceClipLabel,
    DateTime Function() now = DateTime.now,
  }) {
    state = state.copyWith(
      reels: [
        Reel(
          id: 'reel-${now().microsecondsSinceEpoch}',
          authorName: authorName,
          durationSeconds: durationSeconds.clamp(1, maxReelDurationSeconds),
          audioTrack: audioTrack,
          remixAllowed: remixAllowed,
          sourceClipLabel: sourceClipLabel,
          createdAt: now(),
        ),
        ...state.reels,
      ],
    );
  }
}

final reelsProvider = NotifierProvider<ReelsNotifier, ReelsState>(
  ReelsNotifier.new,
);
