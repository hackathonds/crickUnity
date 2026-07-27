import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../social/feed_models.dart' show AttachedObject;
import 'chat_models.dart';

class ChatsState {
  final List<Chat> chats;
  final bool receiptsEnabled;
  final Set<String> typingChatIds;

  const ChatsState({
    this.chats = const [],
    this.receiptsEnabled = true,
    this.typingChatIds = const {},
  });

  Chat? chatById(String id) {
    for (final c in chats) {
      if (c.id == id) return c;
    }
    return null;
  }

  ChatsState copyWith({
    List<Chat>? chats,
    bool? receiptsEnabled,
    Set<String>? typingChatIds,
  }) {
    return ChatsState(
      chats: chats ?? this.chats,
      receiptsEnabled: receiptsEnabled ?? this.receiptsEnabled,
      typingChatIds: typingChatIds ?? this.typingChatIds,
    );
  }
}

/// PRD §12.9 -- E7-05's Messenger engine (list/thread/requests/voice/
/// object-cards, per the backlog's own named split).
class ChatsNotifier extends Notifier<ChatsState> {
  @override
  ChatsState build() => ChatsState(chats: _seedChats());

  static List<Chat> _seedChats() {
    final now = DateTime.now();
    return [
      Chat(
        id: 'chat-team',
        type: ChatType.team,
        name: 'Strikers CC (Team chat)',
        teamId: 'team-strikers',
        participantNames: const ['Arjun Rao', 'Priya Nair', 'Kabir Singh'],
        isPinned: true,
        messages: [
          ChatMessage(
            id: 'msg-team-1',
            senderName: 'Arjun Rao',
            type: MessageType.text,
            text: 'Practice moved to 6pm tomorrow.',
            timestamp: now.subtract(const Duration(hours: 2)),
          ),
        ],
      ),
      Chat(
        id: 'chat-priya',
        type: ChatType.direct,
        name: 'Priya Nair',
        participantNames: const ['Priya Nair'],
        messages: [
          ChatMessage(
            id: 'msg-priya-1',
            senderName: 'Priya Nair',
            type: MessageType.text,
            text: 'Great knock today!',
            timestamp: now.subtract(const Duration(minutes: 30)),
          ),
        ],
      ),
      Chat(
        id: 'chat-squad',
        type: ChatType.group,
        name: 'Weekend Squad',
        participantNames: const ['Arjun Rao', 'Ananya Iyer', 'Kabir Singh'],
        messages: [
          ChatMessage(
            id: 'msg-squad-1',
            senderName: 'Ananya Iyer',
            type: MessageType.text,
            text: 'Who is free Sunday?',
            timestamp: now.subtract(const Duration(hours: 5)),
          ),
        ],
      ),
      Chat(
        id: 'chat-request-1',
        type: ChatType.direct,
        name: 'Farah Khan',
        participantNames: const ['Farah Khan'],
        isConnectionRequest: true,
        messages: [
          ChatMessage(
            id: 'msg-request-1',
            senderName: 'Farah Khan',
            type: MessageType.text,
            text: "Hey, saw your match -- great umpiring today!",
            timestamp: now.subtract(const Duration(hours: 8)),
          ),
        ],
      ),
    ];
  }

  void sendText(String chatId, String text, {String? replyToMessageId}) {
    _appendMessage(
      chatId,
      ChatMessage(
        id: 'msg-${DateTime.now().microsecondsSinceEpoch}',
        senderName: messengerViewerName,
        type: MessageType.text,
        text: text,
        replyToMessageId: replyToMessageId,
        timestamp: DateTime.now(),
      ),
    );
  }

  void sendSticker(String chatId, String label) {
    _appendMessage(
      chatId,
      ChatMessage(
        id: 'msg-${DateTime.now().microsecondsSinceEpoch}',
        senderName: messengerViewerName,
        type: MessageType.sticker,
        text: label,
        timestamp: DateTime.now(),
      ),
    );
  }

  void sendGif(String chatId, String label) {
    _appendMessage(
      chatId,
      ChatMessage(
        id: 'msg-${DateTime.now().microsecondsSinceEpoch}',
        senderName: messengerViewerName,
        type: MessageType.gif,
        text: label,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// DS §62: "voice-note hold-to-record with slide-cancel affordance."
  void sendVoiceNote(String chatId, int durationSeconds) {
    _appendMessage(
      chatId,
      ChatMessage(
        id: 'msg-${DateTime.now().microsecondsSinceEpoch}',
        senderName: messengerViewerName,
        type: MessageType.voice,
        voiceDurationSeconds: durationSeconds,
        timestamp: DateTime.now(),
      ),
    );
  }

  void sendObjectCard(
    String chatId, {
    AttachedObject? object,
    String? expenseId,
  }) {
    _appendMessage(
      chatId,
      ChatMessage(
        id: 'msg-${DateTime.now().microsecondsSinceEpoch}',
        senderName: messengerViewerName,
        type: MessageType.objectCard,
        objectCard: object,
        expenseId: expenseId,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// PRD: "forward (limit 5 chats at once)."
  void forwardMessage(
    ChatMessage message,
    String fromChatName,
    List<String> toChatIds,
  ) {
    final targets = toChatIds.take(maxForwardChats);
    for (final chatId in targets) {
      _appendMessage(
        chatId,
        ChatMessage(
          id: 'msg-${DateTime.now().microsecondsSinceEpoch}-$chatId',
          senderName: messengerViewerName,
          type: message.type,
          text: message.text,
          voiceDurationSeconds: message.voiceDurationSeconds,
          objectCard: message.objectCard,
          expenseId: message.expenseId,
          forwardedFromChatName: fromChatName,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  void toggleStar(String chatId, String messageId) {
    _updateChat(chatId, (chat) {
      return chat.copyWith(
        messages: [
          for (final m in chat.messages)
            if (m.id == messageId) m.copyWith(isStarred: !m.isStarred) else m,
        ],
      );
    });
  }

  void markAllRead(String chatId) {
    _updateChat(
      chatId,
      (chat) => chat.copyWith(
        messages: [for (final m in chat.messages) m.copyWith(isRead: true)],
      ),
    );
  }

  /// PRD: "pinned chats (max 5)." Silently no-ops past the cap --
  /// callers (chat_list_screen.dart) check `canPinMore` first to show
  /// an inline reason instead.
  bool get canPinMore =>
      state.chats.where((c) => c.isPinned).length < maxPinnedChats;

  void togglePin(String chatId) {
    final chat = state.chatById(chatId);
    if (chat == null) return;
    if (!chat.isPinned && !canPinMore) return;
    _updateChat(chatId, (c) => c.copyWith(isPinned: !c.isPinned));
  }

  void toggleMute(String chatId) {
    _updateChat(chatId, (c) => c.copyWith(isMuted: !c.isMuted));
  }

  void setWallpaper(String chatId, String wallpaper) {
    _updateChat(chatId, (c) => c.copyWith(wallpaper: wallpaper));
  }

  void setNickname(String chatId, String participantName, String nickname) {
    _updateChat(chatId, (c) {
      return c.copyWith(nicknames: {...c.nicknames, participantName: nickname});
    });
  }

  /// PRD: "disappearing-messages toggle for 1:1." Guarded to 1:1 --
  /// group/team chats never expose the toggle.
  void toggleDisappearing(String chatId) {
    final chat = state.chatById(chatId);
    if (chat == null || chat.type != ChatType.direct) return;
    _updateChat(
      chatId,
      (c) => c.copyWith(disappearingMessages: !c.disappearingMessages),
    );
  }

  void acceptRequest(String chatId) {
    _updateChat(chatId, (c) => c.copyWith(isConnectionRequest: false));
  }

  void declineRequest(String chatId) {
    state = state.copyWith(
      chats: state.chats.where((c) => c.id != chatId).toList(),
    );
  }

  /// PRD: "delivered/read receipts (per-user toggle; turning off hides
  /// others' too)." One global toggle for the viewer's own account --
  /// no second real account exists to genuinely demonstrate the
  /// reciprocity rule both ways, but the same flag is checked
  /// symmetrically wherever receipts render (chat_thread_screen.dart).
  void setReceiptsEnabled(bool enabled) {
    state = state.copyWith(receiptsEnabled: enabled);
  }

  /// No real presence/typing-event pipeline exists -- a debug control
  /// simulates the other party typing.
  void setTyping(String chatId, bool typing) {
    final updated = {...state.typingChatIds};
    if (typing) {
      updated.add(chatId);
    } else {
      updated.remove(chatId);
    }
    state = state.copyWith(typingChatIds: updated);
  }

  void _appendMessage(String chatId, ChatMessage message) {
    _updateChat(chatId, (c) => c.copyWith(messages: [...c.messages, message]));
  }

  void _updateChat(String chatId, Chat Function(Chat) transform) {
    state = state.copyWith(
      chats: [
        for (final c in state.chats)
          if (c.id == chatId) transform(c) else c,
      ],
    );
  }
}

final chatsProvider = NotifierProvider<ChatsNotifier, ChatsState>(
  ChatsNotifier.new,
);
