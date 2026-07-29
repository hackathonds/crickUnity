import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../matches/scoring_provider.dart';
import '../persistence/persisted_notifier.dart';
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

  Map<String, dynamic> toJson() => {
    'isAssigned': isAssigned,
    'audioStatus': audioStatus.name,
    'markers': [for (final m in markers) m.toJson()],
  };

  factory CommentatorRoomState.fromJson(Map<String, dynamic> json) {
    return CommentatorRoomState(
      isAssigned: json['isAssigned'] as bool? ?? true,
      audioStatus: StreamAudioStatus.values.byName(
        json['audioStatus'] as String,
      ),
      markers: [
        for (final m in json['markers'] as List)
          MomentMarker.fromJson(m as Map<String, dynamic>),
      ],
    );
  }
}

class CommentatorRoomNotifier extends PersistedNotifier<CommentatorRoomState> {
  @override
  String get persistenceKey => 'commentator_room_v1';

  @override
  CommentatorRoomState seed() => const CommentatorRoomState();

  @override
  Map<String, dynamic> toJson(CommentatorRoomState value) => value.toJson();

  @override
  CommentatorRoomState fromJson(Map<String, dynamic> json) =>
      CommentatorRoomState.fromJson(json);

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
