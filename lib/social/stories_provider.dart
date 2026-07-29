import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'feed_models.dart';
import 'story_models.dart';

class StoriesState {
  final List<Story> stories;
  final List<String> dmLog;

  const StoriesState({this.stories = const [], this.dmLog = const []});

  StoriesState copyWith({List<Story>? stories, List<String>? dmLog}) {
    return StoriesState(
      stories: stories ?? this.stories,
      dmLog: dmLog ?? this.dmLog,
    );
  }

  Map<String, dynamic> toJson() => {
    'stories': [for (final s in stories) s.toJson()],
    'dmLog': dmLog,
  };

  factory StoriesState.fromJson(Map<String, dynamic> json) {
    return StoriesState(
      stories: [
        for (final s in json['stories'] as List)
          Story.fromJson(s as Map<String, dynamic>),
      ],
      dmLog: [for (final d in json['dmLog'] as List) d as String],
    );
  }
}

/// PRD §12.3 -- E7-04's stories engine.
class StoriesNotifier extends PersistedNotifier<StoriesState> {
  @override
  String get persistenceKey => 'stories_v1';

  @override
  StoriesState seed() => const StoriesState();

  @override
  Map<String, dynamic> toJson(StoriesState value) => value.toJson();

  @override
  StoriesState fromJson(Map<String, dynamic> json) =>
      StoriesState.fromJson(json);

  void postStory({
    required String authorName,
    required String mediaLabel,
    LiveScoreSticker? scoreSticker,
    Poll? pollSticker,
    DateTime Function() now = DateTime.now,
  }) {
    state = state.copyWith(
      stories: [
        ...state.stories,
        Story(
          id: 'story-${now().microsecondsSinceEpoch}',
          authorName: authorName,
          mediaLabel: mediaLabel,
          createdAt: now(),
          scoreSticker: scoreSticker,
          pollSticker: pollSticker,
        ),
      ],
    );
  }

  void recordView(String storyId, String viewerName) {
    _update(storyId, (s) {
      if (s.viewerNames.contains(viewerName)) return s;
      return s.copyWith(viewerNames: [...s.viewerNames, viewerName]);
    });
  }

  /// "Highlight-save" -- keeps the story visible past its 24h window,
  /// same intent as Instagram-style Highlights (permanent collection).
  void saveHighlight(String storyId) {
    _update(storyId, (s) => s.copyWith(highlightSaved: true));
  }

  void votePollSticker(String storyId, int optionIndex) {
    _update(storyId, (s) {
      if (s.pollSticker == null) return s;
      return s.copyWith(pollSticker: s.pollSticker!.withVote(optionIndex));
    });
  }

  /// PRD §12.3: "reply-via-DM." No real Messenger module exists yet
  /// (that's E7-05's separate, larger scope) -- logged here rather than
  /// silently dropped, same convention as every other missing-
  /// integration gap this session.
  void replyViaDm(String storyId, String message) {
    state = state.copyWith(
      dmLog: [...state.dmLog, 'Reply to story $storyId: $message'],
    );
  }

  void pruneExpiredStories({DateTime Function() now = DateTime.now}) {
    final n = now();
    final kept = state.stories.where((s) => !s.isExpired(n)).toList();
    if (kept.length != state.stories.length) {
      state = state.copyWith(stories: kept);
    }
  }

  void _update(String storyId, Story Function(Story) transform) {
    state = state.copyWith(
      stories: [
        for (final s in state.stories)
          if (s.id == storyId) transform(s) else s,
      ],
    );
  }
}

final storiesProvider = NotifierProvider<StoriesNotifier, StoriesState>(
  StoriesNotifier.new,
);
