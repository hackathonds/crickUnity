/// PRD §12.6: "Comments (threaded 2 levels), author can pin 1 comment,
/// delete-on-own-post rights, like counts." Reuses the design system's
/// pre-built AppCommentThread/AppCommentComposer (E0-08) for rendering --
/// this is the persisted domain model those components' plain
/// AppCommentData view-glue gets mapped from/to.
class FeedComment {
  final String id;
  final String authorName;
  final String body;
  final DateTime timestamp;
  final int propsCount;
  final bool hasMyProps;
  final List<FeedComment> replies;

  const FeedComment({
    required this.id,
    required this.authorName,
    required this.body,
    required this.timestamp,
    this.propsCount = 0,
    this.hasMyProps = false,
    this.replies = const [],
  });

  FeedComment copyWith({
    int? propsCount,
    bool? hasMyProps,
    List<FeedComment>? replies,
  }) {
    return FeedComment(
      id: id,
      authorName: authorName,
      body: body,
      timestamp: timestamp,
      propsCount: propsCount ?? this.propsCount,
      hasMyProps: hasMyProps ?? this.hasMyProps,
      replies: replies ?? this.replies,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorName': authorName,
    'body': body,
    'timestamp': timestamp.toIso8601String(),
    'propsCount': propsCount,
    'hasMyProps': hasMyProps,
    'replies': [for (final r in replies) r.toJson()],
  };

  factory FeedComment.fromJson(Map<String, dynamic> json) {
    return FeedComment(
      id: json['id'] as String,
      authorName: json['authorName'] as String,
      body: json['body'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      propsCount: json['propsCount'] as int? ?? 0,
      hasMyProps: json['hasMyProps'] as bool? ?? false,
      replies: [
        for (final r in json['replies'] as List)
          FeedComment.fromJson(r as Map<String, dynamic>),
      ],
    );
  }
}
