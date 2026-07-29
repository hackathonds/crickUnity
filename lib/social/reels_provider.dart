import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'reel_models.dart';

class ReelsState {
  final List<Reel> reels;

  const ReelsState({this.reels = const []});

  ReelsState copyWith({List<Reel>? reels}) =>
      ReelsState(reels: reels ?? this.reels);

  Map<String, dynamic> toJson() => {
    'reels': [for (final r in reels) r.toJson()],
  };

  factory ReelsState.fromJson(Map<String, dynamic> json) {
    return ReelsState(
      reels: [
        for (final r in json['reels'] as List)
          Reel.fromJson(r as Map<String, dynamic>),
      ],
    );
  }
}

/// PRD §12.3 -- E7-04's reels engine.
class ReelsNotifier extends PersistedNotifier<ReelsState> {
  @override
  String get persistenceKey => 'reels_v1';

  @override
  ReelsState seed() => const ReelsState();

  @override
  Map<String, dynamic> toJson(ReelsState value) => value.toJson();

  @override
  ReelsState fromJson(Map<String, dynamic> json) => ReelsState.fromJson(json);

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
