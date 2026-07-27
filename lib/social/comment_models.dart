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
}
