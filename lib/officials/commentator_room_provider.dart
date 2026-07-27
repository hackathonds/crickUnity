import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../matches/scoring_provider.dart';
import 'commentator_room_models.dart';

class CommentatorRoomState {
  /// No real officiating-assignment pipeline exists (same gap as
  /// E14-01/02/03) -- toggleable here rather than derived from a real
  /// assignment record, so the "assigned-only access, denied state"
  /// rule is still genuinely exercisable.
  final bool isAssigned;
  final StreamAudioStatus audioStatus;
  final List<MomentMarker> markers;

  const CommentatorRoomState({
    this.isAssigned = true,
    this.audioStatus = StreamAudioStatus.live,
    this.markers = const [],
  });

  CommentatorRoomState copyWith({
    bool? isAssigned,
    StreamAudioStatus? audioStatus,
    List<MomentMarker>? markers,
  }) {
    return CommentatorRoomState(
      isAssigned: isAssigned ?? this.isAssigned,
      audioStatus: audioStatus ?? this.audioStatus,
      markers: markers ?? this.markers,
    );
  }
}

class CommentatorRoomNotifier extends Notifier<CommentatorRoomState> {
  @override
  CommentatorRoomState build() => const CommentatorRoomState();

  void setAssigned(bool assigned) {
    state = state.copyWith(isAssigned: assigned);
  }

  void toggleMuteSelf() {
    state = state.copyWith(
      audioStatus: state.audioStatus == StreamAudioStatus.muted
          ? StreamAudioStatus.live
          : StreamAudioStatus.muted,
    );
  }

  /// "[Mark moment] ... feeds highlights" -- reuses the real live
  /// innings' current ball count as the marker's ball index rather than
  /// a mock counter.
  void markMoment({DateTime Function() now = DateTime.now}) {
    final ballIndex = ref.read(inningsProvider).deliveries.length;
    state = state.copyWith(
      markers: [
        MomentMarker(ballIndex: ballIndex, markedAt: now()),
        ...state.markers,
      ],
    );
  }
}

final commentatorRoomProvider =
    NotifierProvider<CommentatorRoomNotifier, CommentatorRoomState>(
      CommentatorRoomNotifier.new,
    );
