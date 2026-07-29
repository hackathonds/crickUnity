import 'feed_models.dart';

const Duration storyLifetime = Duration(hours: 24);

/// PRD §12.3: "score sticker pulls live match score into the story and
/// stays live." Genuinely reads scoring_provider.dart's real
/// InningsState at render time (story_viewer_screen.dart) rather than
/// freezing a snapshot -- the same live match this session's other
/// stories already track, not a second mocked score.
class LiveScoreSticker {
  final String matchLabel;

  const LiveScoreSticker({required this.matchLabel});

  Map<String, dynamic> toJson() => {'matchLabel': matchLabel};

  factory LiveScoreSticker.fromJson(Map<String, dynamic> json) {
    return LiveScoreSticker(matchLabel: json['matchLabel'] as String);
  }
}

class Story {
  final String id;
  final String authorName;
  final String mediaLabel;
  final DateTime createdAt;
  final LiveScoreSticker? scoreSticker;
  final Poll? pollSticker;
  final List<String> viewerNames;
  final bool highlightSaved;

  const Story({
    required this.id,
    required this.authorName,
    required this.mediaLabel,
    required this.createdAt,
    this.scoreSticker,
    this.pollSticker,
    this.viewerNames = const [],
    this.highlightSaved = false,
  });

  DateTime get expiresAt => createdAt.add(storyLifetime);

  bool isExpired(DateTime now) => !highlightSaved && now.isAfter(expiresAt);

  Story copyWith({
    List<String>? viewerNames,
    bool? highlightSaved,
    Poll? pollSticker,
  }) {
    return Story(
      id: id,
      authorName: authorName,
      mediaLabel: mediaLabel,
      createdAt: createdAt,
      scoreSticker: scoreSticker,
      pollSticker: pollSticker ?? this.pollSticker,
      viewerNames: viewerNames ?? this.viewerNames,
      highlightSaved: highlightSaved ?? this.highlightSaved,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorName': authorName,
    'mediaLabel': mediaLabel,
    'createdAt': createdAt.toIso8601String(),
    'scoreSticker': scoreSticker?.toJson(),
    'pollSticker': pollSticker?.toJson(),
    'viewerNames': viewerNames,
    'highlightSaved': highlightSaved,
  };

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as String,
      authorName: json['authorName'] as String,
      mediaLabel: json['mediaLabel'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      scoreSticker: json['scoreSticker'] != null
          ? LiveScoreSticker.fromJson(
              json['scoreSticker'] as Map<String, dynamic>,
            )
          : null,
      pollSticker: json['pollSticker'] != null
          ? Poll.fromJson(json['pollSticker'] as Map<String, dynamic>)
          : null,
      viewerNames: [for (final v in json['viewerNames'] as List) v as String],
      highlightSaved: json['highlightSaved'] as bool? ?? false,
    );
  }
}
