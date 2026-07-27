import '../social/feed_models.dart' show AttachedObject;

const String messengerViewerName = 'Deepak Sharma';
const int maxPinnedChats = 5;
const int maxForwardChats = 5;

/// PRD §12.9: "1:1 + group chats (team chat auto-provisioned per team;
/// membership syncs with roster)." Team-chat membership genuinely
/// syncing with the real roster (join/leave events) needs a live
/// roster-membership event bus that doesn't exist yet -- flagged, the
/// team chat here is seeded once, not kept in sync.
enum ChatType { direct, group, team }

enum MessageType { text, image, video, voice, gif, sticker, poll, objectCard }

/// PRD: "share any app object as rich card (expense card in chat shows
/// live paid/pending state!)." [expenseId] is the one genuinely LIVE
/// object card (looked up from expensesProvider at render time,
/// chat_thread_screen.dart) -- [objectCard] reuses feed_models.dart's
/// AttachedObject for the other (static) cricket-object types, same
/// taxonomy the Feed composer already attaches.
class ChatMessage {
  final String id;
  final String senderName;
  final MessageType type;
  final String? text;
  final int? voiceDurationSeconds;
  final AttachedObject? objectCard;
  final String? expenseId;
  final String? replyToMessageId;
  final String? forwardedFromChatName;
  final bool isStarred;
  final bool isDelivered;
  final bool isRead;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.senderName,
    required this.type,
    this.text,
    this.voiceDurationSeconds,
    this.objectCard,
    this.expenseId,
    this.replyToMessageId,
    this.forwardedFromChatName,
    this.isStarred = false,
    this.isDelivered = true,
    this.isRead = false,
    required this.timestamp,
  });

  ChatMessage copyWith({bool? isStarred, bool? isRead}) {
    return ChatMessage(
      id: id,
      senderName: senderName,
      type: type,
      text: text,
      voiceDurationSeconds: voiceDurationSeconds,
      objectCard: objectCard,
      expenseId: expenseId,
      replyToMessageId: replyToMessageId,
      forwardedFromChatName: forwardedFromChatName,
      isStarred: isStarred ?? this.isStarred,
      isDelivered: isDelivered,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp,
    );
  }
}

/// PRD: "pinned chats (max 5) ... per-chat mute/wallpaper/nickname,
/// disappearing-messages toggle for 1:1." [isConnectionRequest] chats
/// live in the requests inbox (message_requests_screen.dart) rather
/// than the main list until accepted.
class Chat {
  final String id;
  final ChatType type;
  final String name;
  final List<String> participantNames;
  final bool isPinned;
  final bool isMuted;
  final String? wallpaper;
  final Map<String, String> nicknames;
  final bool disappearingMessages;
  final bool isConnectionRequest;
  final String? teamId;
  final List<ChatMessage> messages;

  const Chat({
    required this.id,
    required this.type,
    required this.name,
    this.participantNames = const [],
    this.isPinned = false,
    this.isMuted = false,
    this.wallpaper,
    this.nicknames = const {},
    this.disappearingMessages = false,
    this.isConnectionRequest = false,
    this.teamId,
    this.messages = const [],
  });

  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;

  int get unreadCount => messages
      .where((m) => m.senderName != messengerViewerName && !m.isRead)
      .length;

  Chat copyWith({
    bool? isPinned,
    bool? isMuted,
    String? wallpaper,
    Map<String, String>? nicknames,
    bool? disappearingMessages,
    bool? isConnectionRequest,
    List<ChatMessage>? messages,
  }) {
    return Chat(
      id: id,
      type: type,
      name: name,
      participantNames: participantNames,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      wallpaper: wallpaper ?? this.wallpaper,
      nicknames: nicknames ?? this.nicknames,
      disappearingMessages: disappearingMessages ?? this.disappearingMessages,
      isConnectionRequest: isConnectionRequest ?? this.isConnectionRequest,
      teamId: teamId,
      messages: messages ?? this.messages,
    );
  }
}

/// PRD: "cricket sticker packs." No real sticker/GIF asset library
/// exists -- a small labeled set stands in, same flagged-mock
/// convention as every other missing-asset gap this session.
const List<String> mockStickerLabels = [
  'Six! 🏏',
  'Well Played 👏',
  'On Strike',
  'Catch!',
];

const List<String> mockGifLabels = ['Celebration', 'Facepalm', 'Clapping'];
