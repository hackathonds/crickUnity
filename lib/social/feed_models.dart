import '../design_system/components/app_reaction_picker.dart';

/// PRD §12.1 (Feed) + §12.2 ("attach cricket object"). DS §7-57's card
/// anatomy: "author row -> attached-object rich card (match/performance
/// verified chip) -> media -> reaction bar -> top comment." Also reused
/// by Messenger's object-cards (chat_provider.dart's sendObjectCard) --
/// [gearListing] (E15-05, DS §11.12: "[Chat with seller] opens
/// Messenger thread templated with listing card") is a chat-only card,
/// never composable from the Feed composer.
enum AttachedObjectType {
  match,
  performance,
  ground,
  tournament,
  achievement,
  gearListing,
}

const Map<AttachedObjectType, String> attachedObjectTypeLabels = {
  AttachedObjectType.match: 'Match',
  AttachedObjectType.performance: 'Performance',
  AttachedObjectType.ground: 'Ground',
  AttachedObjectType.tournament: 'Tournament',
  AttachedObjectType.achievement: 'Achievement',
  AttachedObjectType.gearListing: 'Gear listing',
};

/// "attaching renders a rich live card, e.g., a performance attachment
/// shows verified stat chip" -- [verified] mirrors DS Pillar 2's
/// verified-vs-unverified visual distinction (non-negotiable #8).
class AttachedObject {
  final AttachedObjectType type;
  final String title;
  final String subtitle;
  final bool verified;

  const AttachedObject({
    required this.type,
    required this.title,
    required this.subtitle,
    this.verified = false,
  });
}

/// PRD §12.2: "audience selector (Public / Followers / Teams (pick) /
/// Only me) -- audience is per-post sticky-default."
enum PostAudience { public, followers, teams, onlyMe }

const Map<PostAudience, String> postAudienceLabels = {
  PostAudience.public: 'Public',
  PostAudience.followers: 'Followers',
  PostAudience.teams: 'Teams',
  PostAudience.onlyMe: 'Only me',
};

/// DS §7-58's attach rail includes "poll" alongside media/object/
/// feeling -- PRD §12.2's own prose doesn't detail poll mechanics (that
/// lives conceptually under §12.5's Polls/Events section), so vote
/// counts/percentages here are this story's own minimal, genuine
/// interaction rather than a full separate poll module.
class PollOption {
  final String text;
  final int votes;

  const PollOption({required this.text, this.votes = 0});

  PollOption withVote() => PollOption(text: text, votes: votes + 1);
}

class Poll {
  final String question;
  final List<PollOption> options;
  final int? votedOptionIndex;

  const Poll({
    required this.question,
    required this.options,
    this.votedOptionIndex,
  });

  int get totalVotes => options.fold(0, (sum, o) => sum + o.votes);

  Poll withVote(int optionIndex) {
    if (votedOptionIndex != null) return this;
    return Poll(
      question: question,
      options: [
        for (var i = 0; i < options.length; i++)
          i == optionIndex ? options[i].withVote() : options[i],
      ],
      votedOptionIndex: optionIndex,
    );
  }
}

/// PRD §12.1: "Ranking = relationship closeness x cricket relevance x
/// recency." [relationshipScore]/[cricketRelevanceScore] stand in for
/// the 2 non-recency inputs (no real social graph/interest model
/// exists yet) -- 0.0-1.0, mock-authored per post for variety.
///
/// PRD §12.2: "Edit window: unlimited, 'Edited' label with version
/// history viewable by tapper. Delete: soft (author) with 30-day
/// self-restore." [editHistory] holds every prior content version (not
/// just the latest), [deletedAt] non-null means soft-deleted --
/// callers filter those out of the main feed and list them in a
/// recently-deleted screen instead (same convention as expenses'
/// recently_deleted_screen.dart, E5-09).
class FeedPost {
  final String id;
  final String authorName;
  final String contentText;
  final AttachedObject? attachedObject;
  final int mediaCount;
  final Map<AppReactionType, int> reactions;
  final AppReactionType? myReaction;
  final String? topCommentAuthor;
  final String? topCommentText;
  final DateTime timestamp;
  final bool isFollowed;
  final double relationshipScore;
  final double cricketRelevanceScore;
  final String? sponsoredLabel;
  final PostAudience audience;
  final Poll? poll;
  final List<String> editHistory;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final String? resharedPostId;

  const FeedPost({
    required this.id,
    required this.authorName,
    required this.contentText,
    this.attachedObject,
    this.mediaCount = 0,
    this.reactions = const {},
    this.myReaction,
    this.topCommentAuthor,
    this.topCommentText,
    required this.timestamp,
    this.isFollowed = true,
    this.relationshipScore = 0.5,
    this.cricketRelevanceScore = 0.5,
    this.sponsoredLabel,
    this.audience = PostAudience.public,
    this.poll,
    this.editHistory = const [],
    this.editedAt,
    this.deletedAt,
    this.resharedPostId,
  });

  bool get isEdited => editHistory.isNotEmpty;

  int get totalReactionCount => reactions.values.fold(0, (sum, v) => sum + v);

  FeedPost copyWith() {
    return FeedPost(
      id: id,
      authorName: authorName,
      contentText: contentText,
      attachedObject: attachedObject,
      mediaCount: mediaCount,
      reactions: reactions,
      myReaction: myReaction,
      topCommentAuthor: topCommentAuthor,
      topCommentText: topCommentText,
      timestamp: timestamp,
      isFollowed: isFollowed,
      relationshipScore: relationshipScore,
      cricketRelevanceScore: cricketRelevanceScore,
      sponsoredLabel: sponsoredLabel,
      audience: audience,
      poll: poll,
      editHistory: editHistory,
      editedAt: editedAt,
      deletedAt: deletedAt,
      resharedPostId: resharedPostId,
    );
  }

  /// DS §3.14: tapping a reaction already chosen removes it (toggle
  /// off); tapping a different one replaces the count.
  FeedPost withReaction(AppReactionType? newReaction) {
    final updated = {...reactions};
    if (myReaction != null) {
      final current = updated[myReaction] ?? 0;
      if (current <= 1) {
        updated.remove(myReaction);
      } else {
        updated[myReaction!] = current - 1;
      }
    }
    if (newReaction != null) {
      updated[newReaction] = (updated[newReaction] ?? 0) + 1;
    }
    return FeedPost(
      id: id,
      authorName: authorName,
      contentText: contentText,
      attachedObject: attachedObject,
      mediaCount: mediaCount,
      reactions: updated,
      myReaction: newReaction,
      topCommentAuthor: topCommentAuthor,
      topCommentText: topCommentText,
      timestamp: timestamp,
      isFollowed: isFollowed,
      relationshipScore: relationshipScore,
      cricketRelevanceScore: cricketRelevanceScore,
      sponsoredLabel: sponsoredLabel,
      audience: audience,
      poll: poll,
      editHistory: editHistory,
      editedAt: editedAt,
      deletedAt: deletedAt,
      resharedPostId: resharedPostId,
    );
  }

  FeedPost withEdit(String newText, DateTime now) {
    return FeedPost(
      id: id,
      authorName: authorName,
      contentText: newText,
      attachedObject: attachedObject,
      mediaCount: mediaCount,
      reactions: reactions,
      myReaction: myReaction,
      topCommentAuthor: topCommentAuthor,
      topCommentText: topCommentText,
      timestamp: timestamp,
      isFollowed: isFollowed,
      relationshipScore: relationshipScore,
      cricketRelevanceScore: cricketRelevanceScore,
      sponsoredLabel: sponsoredLabel,
      audience: audience,
      poll: poll,
      editHistory: [...editHistory, contentText],
      editedAt: now,
      deletedAt: deletedAt,
      resharedPostId: resharedPostId,
    );
  }

  FeedPost withDeleted(DateTime now) {
    return FeedPost(
      id: id,
      authorName: authorName,
      contentText: contentText,
      attachedObject: attachedObject,
      mediaCount: mediaCount,
      reactions: reactions,
      myReaction: myReaction,
      topCommentAuthor: topCommentAuthor,
      topCommentText: topCommentText,
      timestamp: timestamp,
      isFollowed: isFollowed,
      relationshipScore: relationshipScore,
      cricketRelevanceScore: cricketRelevanceScore,
      sponsoredLabel: sponsoredLabel,
      audience: audience,
      poll: poll,
      editHistory: editHistory,
      editedAt: editedAt,
      deletedAt: now,
      resharedPostId: resharedPostId,
    );
  }

  FeedPost withRestored() {
    return FeedPost(
      id: id,
      authorName: authorName,
      contentText: contentText,
      attachedObject: attachedObject,
      mediaCount: mediaCount,
      reactions: reactions,
      myReaction: myReaction,
      topCommentAuthor: topCommentAuthor,
      topCommentText: topCommentText,
      timestamp: timestamp,
      isFollowed: isFollowed,
      relationshipScore: relationshipScore,
      cricketRelevanceScore: cricketRelevanceScore,
      sponsoredLabel: sponsoredLabel,
      audience: audience,
      poll: poll,
      editHistory: editHistory,
      editedAt: editedAt,
      deletedAt: null,
      resharedPostId: resharedPostId,
    );
  }

  FeedPost withPollVote(int optionIndex) {
    if (poll == null) return this;
    return FeedPost(
      id: id,
      authorName: authorName,
      contentText: contentText,
      attachedObject: attachedObject,
      mediaCount: mediaCount,
      reactions: reactions,
      myReaction: myReaction,
      topCommentAuthor: topCommentAuthor,
      topCommentText: topCommentText,
      timestamp: timestamp,
      isFollowed: isFollowed,
      relationshipScore: relationshipScore,
      cricketRelevanceScore: cricketRelevanceScore,
      sponsoredLabel: sponsoredLabel,
      audience: audience,
      poll: poll!.withVote(optionIndex),
      editHistory: editHistory,
      editedAt: editedAt,
      deletedAt: deletedAt,
      resharedPostId: resharedPostId,
    );
  }
}

double _recencyScore(DateTime timestamp, DateTime now) {
  final hoursAgo = now.difference(timestamp).inMinutes / 60;
  if (hoursAgo <= 0) return 1.0;
  // Halves roughly every 12h -- no PRD formula given, a flagged
  // judgment call same as the weights below.
  return 1 / (1 + hoursAgo / 12);
}

/// PRD names the 3 ranking inputs, not their weights -- an even 1/3
/// split is the flagged judgment call standing in for a real relevance
/// model.
double rankedScore(FeedPost post, DateTime now) {
  return post.relationshipScore * (1 / 3) +
      post.cricketRelevanceScore * (1 / 3) +
      _recencyScore(post.timestamp, now) * (1 / 3);
}

/// "Why am I seeing this?" explainer -- names whichever of the 3
/// factors is dominant for this post, since there's no real per-post
/// reasoning log to surface.
String whyAmISeeingThis(FeedPost post, DateTime now) {
  final recency = _recencyScore(post.timestamp, now);
  final scores = {
    'your relationship with ${post.authorName}': post.relationshipScore,
    'how relevant this is to your cricket interests':
        post.cricketRelevanceScore,
    'how recent this post is': recency,
  };
  final dominant = scores.entries.reduce((a, b) => a.value >= b.value ? a : b);
  return "You're seeing this mostly because of ${dominant.key}.";
}

/// Composer's object-attach rail (PRD §12.2): no real picker over the
/// viewer's own matches/performances/achievements exists yet -- a fixed
/// "your recent objects" mock list stands in.
const List<AttachedObject> mockAttachableObjects = [
  AttachedObject(
    type: AttachedObjectType.match,
    title: 'Strikers vs Warriors',
    subtitle: 'Won by 4 wickets',
    verified: true,
  ),
  AttachedObject(
    type: AttachedObjectType.performance,
    title: '54* (38)',
    subtitle: 'vs Riverside CC',
    verified: true,
  ),
  AttachedObject(
    type: AttachedObjectType.achievement,
    title: 'Scorer Supreme -- Silver',
    subtitle: '50 dispute-free scored matches',
    verified: true,
  ),
];

/// No real social graph/content pipeline exists -- a fixed mock feed
/// stands in, same convention as every other missing-backend gap.
List<FeedPost> mockFeedPosts({required DateTime now}) => [
  FeedPost(
    id: 'post-1',
    authorName: 'Arjun Rao',
    contentText: 'What a run chase! Proud of the boys tonight.',
    attachedObject: const AttachedObject(
      type: AttachedObjectType.match,
      title: 'Strikers vs Warriors',
      subtitle: 'Won by 4 wickets',
      verified: true,
    ),
    mediaCount: 2,
    reactions: const {
      AppReactionType.clap: 10,
      AppReactionType.heart: 5,
      AppReactionType.fire: 3,
    },
    myReaction: AppReactionType.clap,
    topCommentAuthor: 'Priya Nair',
    topCommentText: 'That last over was insane 🔥',
    timestamp: now.subtract(const Duration(minutes: 20)),
    isFollowed: true,
    relationshipScore: 0.9,
    cricketRelevanceScore: 0.8,
  ),
  FeedPost(
    id: 'post-2',
    authorName: 'Deepak Sharma',
    contentText: 'Fifty on debut for the club! Grateful.',
    attachedObject: const AttachedObject(
      type: AttachedObjectType.performance,
      title: '54* (38)',
      subtitle: 'vs Riverside CC',
      verified: true,
    ),
    mediaCount: 1,
    reactions: const {
      AppReactionType.clap: 20,
      AppReactionType.heart: 8,
      AppReactionType.fire: 4,
    },
    topCommentAuthor: 'Kabir Singh',
    topCommentText: 'Legend!',
    timestamp: now.subtract(const Duration(hours: 3)),
    isFollowed: true,
    relationshipScore: 0.7,
    cricketRelevanceScore: 0.9,
  ),
  FeedPost(
    id: 'post-3',
    authorName: 'Green Valley Ground',
    contentText: 'New nets installed this week -- come try them out.',
    attachedObject: const AttachedObject(
      type: AttachedObjectType.ground,
      title: 'Green Valley Ground',
      subtitle: '4.6 ★ · 120 matches hosted',
    ),
    mediaCount: 3,
    reactions: const {AppReactionType.clap: 6, AppReactionType.heart: 3},
    timestamp: now.subtract(const Duration(hours: 6)),
    isFollowed: false,
    relationshipScore: 0.2,
    cricketRelevanceScore: 0.6,
  ),
  FeedPost(
    id: 'post-4',
    authorName: 'City Premier League',
    contentText: 'Semi-final fixtures are out -- check the bracket.',
    attachedObject: const AttachedObject(
      type: AttachedObjectType.tournament,
      title: 'City Premier League',
      subtitle: 'Semi-finals this weekend',
      verified: true,
    ),
    reactions: const {
      AppReactionType.clap: 25,
      AppReactionType.heart: 10,
      AppReactionType.wow: 6,
    },
    timestamp: now.subtract(const Duration(hours: 10)),
    isFollowed: false,
    relationshipScore: 0.1,
    cricketRelevanceScore: 0.7,
    sponsoredLabel: 'Sponsored -- shown because you follow City Premier League',
  ),
  FeedPost(
    id: 'post-5',
    authorName: 'Priya Nair',
    contentText: 'Unlocked a new badge today!',
    attachedObject: const AttachedObject(
      type: AttachedObjectType.achievement,
      title: 'Scorer Supreme -- Silver',
      subtitle: '50 dispute-free scored matches',
      verified: true,
    ),
    reactions: const {AppReactionType.clap: 8, AppReactionType.heart: 4},
    topCommentAuthor: 'Ananya Iyer',
    topCommentText: 'Well deserved!',
    timestamp: now.subtract(const Duration(hours: 14)),
    isFollowed: true,
    relationshipScore: 0.6,
    cricketRelevanceScore: 0.5,
  ),
  FeedPost(
    id: 'post-6',
    authorName: 'Kabir Singh',
    contentText: 'Anyone up for a nets session this Sunday morning?',
    reactions: const {AppReactionType.clap: 5},
    timestamp: now.subtract(const Duration(hours: 20)),
    isFollowed: true,
    relationshipScore: 0.5,
    cricketRelevanceScore: 0.3,
  ),
  FeedPost(
    id: 'post-7',
    authorName: 'Nearby: Riverside CC',
    contentText: 'Looking for a free-agent keeper for Saturday.',
    reactions: const {AppReactionType.clap: 3},
    timestamp: now.subtract(const Duration(hours: 30)),
    isFollowed: false,
    relationshipScore: 0.1,
    cricketRelevanceScore: 0.4,
  ),
  FeedPost(
    id: 'post-8',
    authorName: 'Ananya Iyer',
    contentText: 'Throwback to last season\'s final. What a day.',
    mediaCount: 4,
    reactions: const {
      AppReactionType.clap: 15,
      AppReactionType.heart: 9,
      AppReactionType.laugh: 3,
    },
    topCommentAuthor: 'Arjun Rao',
    topCommentText: 'Miss this team 🥲',
    timestamp: now.subtract(const Duration(days: 2)),
    isFollowed: true,
    relationshipScore: 0.8,
    cricketRelevanceScore: 0.4,
  ),
];
