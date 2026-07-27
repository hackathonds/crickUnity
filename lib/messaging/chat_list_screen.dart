import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_avatar.dart';
import '../design_system/components/app_tag_chip.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'chat_models.dart';
import 'chat_provider.dart';
import 'chat_thread_screen.dart';
import 'message_requests_screen.dart';

String _relativeTime(DateTime? timestamp) {
  if (timestamp == null) return '';
  final diff = DateTime.now().difference(timestamp);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  return '${diff.inDays}d';
}

/// DS §62: "Messenger thread list (swipe read/mute)." The pre-built
/// AppSwipeActionRow component (E0-08) needs an AppIconId for each
/// action -- no mute/pin/read icon exists in that closed enum, and
/// forcing a mismatched icon onto a shared design-system component for
/// one caller is worse than flagging the gap -- so this list uses a
/// plain Dismissible (confirmDismiss toggles the action, then snaps
/// back rather than removing the row) for the swipe gesture instead.
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(chatsProvider);
    final notifier = ref.read(chatsProvider.notifier);

    final requestCount = state.chats.where((c) => c.isConnectionRequest).length;
    final visibleChats =
        state.chats.where((c) => !c.isConnectionRequest).toList()..sort((a, b) {
          if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
          final aTime = a.lastMessage?.timestamp;
          final bTime = b.lastMessage?.timestamp;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            key: const ValueKey('messageRequestsButton'),
            icon: Badge(
              label: Text('$requestCount'),
              isLabelVisible: requestCount > 0,
              child: const Icon(Icons.inbox_outlined),
            ),
            tooltip: 'Requests',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MessageRequestsScreen()),
            ),
          ),
          IconButton(
            key: const ValueKey('receiptsToggleButton'),
            icon: Icon(
              state.receiptsEnabled ? Icons.done_all : Icons.done_all_outlined,
            ),
            tooltip: state.receiptsEnabled
                ? 'Read receipts on'
                : 'Read receipts off',
            onPressed: () =>
                notifier.setReceiptsEnabled(!state.receiptsEnabled),
          ),
        ],
      ),
      body: ListView(
        children: [
          for (final chat in visibleChats)
            Dismissible(
              key: ValueKey('chatDismissible_${chat.id}'),
              direction: DismissDirection.horizontal,
              background: Container(
                color: colors.primary.withValues(alpha: 0.15),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(chat.isPinned ? 'Unpin' : 'Pin'),
              ),
              secondaryBackground: Container(
                color: colors.textTertiary.withValues(alpha: 0.15),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(chat.isMuted ? 'Unmute' : 'Mute'),
              ),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  notifier.togglePin(chat.id);
                } else {
                  notifier.toggleMute(chat.id);
                }
                return false;
              },
              child: ListTile(
                key: ValueKey('chatRow_${chat.id}'),
                leading: AppAvatar(size: AppAvatarSize.md, name: chat.name),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        chat.name,
                        style: AppTypography.subtitle.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    if (chat.isPinned) const Icon(Icons.push_pin, size: 14),
                    if (chat.isMuted) const Icon(Icons.volume_off, size: 14),
                  ],
                ),
                subtitle: Text(
                  chat.lastMessage?.text ?? _messageTypeLabel(chat.lastMessage),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _relativeTime(chat.lastMessage?.timestamp),
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                    if (chat.unreadCount > 0)
                      AppTagChip(
                        label: '${chat.unreadCount}',
                        variant: AppTagChipVariant.success,
                      ),
                  ],
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatThreadScreen(chatId: chat.id),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _messageTypeLabel(ChatMessage? message) {
    if (message == null) return 'No messages yet';
    return switch (message.type) {
      MessageType.text => '',
      MessageType.image => '📷 Photo',
      MessageType.video => '🎥 Video',
      MessageType.voice => '🎤 Voice note',
      MessageType.gif => 'GIF',
      MessageType.sticker => 'Sticker',
      MessageType.poll => '📊 Poll',
      MessageType.objectCard => 'Shared a card',
    };
  }
}
