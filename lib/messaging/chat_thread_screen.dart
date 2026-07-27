import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../expenses/expenses_provider.dart';
import '../social/feed_models.dart' show AttachedObject, AttachedObjectType;
import 'chat_models.dart';
import 'chat_provider.dart';
import 'voice_note_recorder.dart';

/// DS §62: "thread: bubbles r-lg (own primary-tinted), object-cards
/// interactive (expense card shows live paid state), voice-note
/// hold-to-record with slide-cancel affordance."
class ChatThreadScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatThreadScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _textController = TextEditingController();
  ChatMessage? _replyTo;
  bool _showStarredOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(chatsProvider.notifier).markAllRead(widget.chatId);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    ref
        .read(chatsProvider.notifier)
        .sendText(widget.chatId, text, replyToMessageId: _replyTo?.id);
    _textController.clear();
    setState(() => _replyTo = null);
  }

  void _showAttachSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.emoji_emotions_outlined),
            title: const Text('Sticker'),
            onTap: () {
              Navigator.of(context).pop();
              _pickFromLabels(mockStickerLabels, (label) {
                ref
                    .read(chatsProvider.notifier)
                    .sendSticker(widget.chatId, label);
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.gif_box_outlined),
            title: const Text('GIF'),
            onTap: () {
              Navigator.of(context).pop();
              _pickFromLabels(mockGifLabels, (label) {
                ref.read(chatsProvider.notifier).sendGif(widget.chatId, label);
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Expense card (live)'),
            onTap: () {
              Navigator.of(context).pop();
              _pickExpenseCard();
            },
          ),
          ListTile(
            leading: const Icon(Icons.sports_cricket_outlined),
            title: const Text('Cricket object card'),
            onTap: () {
              Navigator.of(context).pop();
              _pickObjectCard();
            },
          ),
        ],
      ),
    );
  }

  void _pickFromLabels(List<String> labels, ValueChanged<String> onPick) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final label in labels)
            ListTile(
              title: Text(label),
              onTap: () {
                Navigator.of(context).pop();
                onPick(label);
              },
            ),
        ],
      ),
    );
  }

  void _pickExpenseCard() {
    final expenses = ref.read(expensesProvider).expenses;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (expenses.isEmpty) const ListTile(title: Text('No expenses yet')),
          for (final e in expenses.take(10))
            ListTile(
              title: Text(e.title),
              subtitle: Text('₹${e.paidTotal} of ₹${e.amount} paid'),
              onTap: () {
                Navigator.of(context).pop();
                ref
                    .read(chatsProvider.notifier)
                    .sendObjectCard(widget.chatId, expenseId: e.id);
              },
            ),
        ],
      ),
    );
  }

  void _pickObjectCard() {
    const options = [
      AttachedObject(
        type: AttachedObjectType.match,
        title: 'Strikers vs Warriors',
        subtitle: 'Won by 4 wickets',
        verified: true,
      ),
      AttachedObject(
        type: AttachedObjectType.ground,
        title: 'Green Valley Ground',
        subtitle: '4.6 stars',
      ),
    ];
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final object in options)
            ListTile(
              title: Text(object.title),
              subtitle: Text(object.subtitle),
              onTap: () {
                Navigator.of(context).pop();
                ref
                    .read(chatsProvider.notifier)
                    .sendObjectCard(widget.chatId, object: object);
              },
            ),
        ],
      ),
    );
  }

  void _showChatSettings(Chat chat) {
    final nicknameController = TextEditingController(
      text: chat.nicknames[chat.participantNames.firstOrNull ?? ''] ?? '',
    );
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final color in ['Default', 'Ocean', 'Sunset'])
                  ChoiceChip(
                    label: Text(color),
                    selected: chat.wallpaper == color,
                    onSelected: (_) => ref
                        .read(chatsProvider.notifier)
                        .setWallpaper(chat.id, color),
                  ),
              ],
            ),
            if (chat.type == ChatType.direct) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: nicknameController,
                decoration: const InputDecoration(labelText: 'Nickname'),
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Disappearing messages'),
                value: chat.disappearingMessages,
                onChanged: (_) => ref
                    .read(chatsProvider.notifier)
                    .toggleDisappearing(chat.id),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (chat.type == ChatType.direct &&
                  chat.participantNames.isNotEmpty) {
                ref
                    .read(chatsProvider.notifier)
                    .setNickname(
                      chat.id,
                      chat.participantNames.first,
                      nicknameController.text.trim(),
                    );
              }
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showForwardSheet(ChatMessage message, String fromChatName) {
    final otherChats = ref
        .read(chatsProvider)
        .chats
        .where((c) => c.id != widget.chatId && !c.isConnectionRequest)
        .toList();
    final selected = <String>{};
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Forward to (max $maxForwardChats)',
                style: AppTypography.h2,
              ),
              for (final c in otherChats)
                CheckboxListTile(
                  title: Text(c.name),
                  value: selected.contains(c.id),
                  onChanged: (v) => setSheetState(() {
                    if (v == true) {
                      if (selected.length < maxForwardChats) selected.add(c.id);
                    } else {
                      selected.remove(c.id);
                    }
                  }),
                ),
              TextButton(
                onPressed: selected.isEmpty
                    ? null
                    : () {
                        ref
                            .read(chatsProvider.notifier)
                            .forwardMessage(
                              message,
                              fromChatName,
                              selected.toList(),
                            );
                        Navigator.of(context).pop();
                      },
                child: const Text('Forward'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final chatsState = ref.watch(chatsProvider);
    final chat = chatsState.chatById(widget.chatId);
    final notifier = ref.read(chatsProvider.notifier);

    if (chat == null) {
      return const Scaffold(body: Center(child: Text('Chat not found')));
    }

    final isTyping = chatsState.typingChatIds.contains(chat.id);
    final messages = _showStarredOnly
        ? chat.messages.where((m) => m.isStarred).toList()
        : chat.messages;

    return Scaffold(
      appBar: AppBar(
        title: Text(chat.name),
        actions: [
          IconButton(
            key: const ValueKey('simulateTypingButton'),
            icon: const Icon(Icons.keyboard_outlined),
            tooltip: 'Simulate typing (debug)',
            onPressed: () => notifier.setTyping(chat.id, !isTyping),
          ),
          IconButton(
            key: const ValueKey('starredFilterButton'),
            icon: Icon(_showStarredOnly ? Icons.star : Icons.star_border),
            onPressed: () =>
                setState(() => _showStarredOnly = !_showStarredOnly),
          ),
          IconButton(
            key: const ValueKey('chatSettingsButton'),
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showChatSettings(chat),
          ),
        ],
      ),
      body: Column(
        children: [
          if (isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${chat.name} is typing...',
                  style: AppTypography.caption.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                for (final message in messages)
                  _MessageBubble(
                    key: ValueKey('chatMessage_${message.id}'),
                    message: message,
                    isMine: message.senderName == messengerViewerName,
                    receiptsEnabled: chatsState.receiptsEnabled,
                    replyToText: message.replyToMessageId == null
                        ? null
                        : chat.messages
                              .firstWhere(
                                (m) => m.id == message.replyToMessageId,
                                orElse: () => message,
                              )
                              .text,
                    onReply: () => setState(() => _replyTo = message),
                    onStar: () => notifier.toggleStar(chat.id, message.id),
                    onForward: () => _showForwardSheet(message, chat.name),
                  ),
              ],
            ),
          ),
          if (_replyTo != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              color: colors.surfaceAlt,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Replying to: ${_replyTo!.text ?? _messageKindLabel(_replyTo!)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() => _replyTo = null),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                IconButton(
                  key: const ValueKey('attachButton'),
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _showAttachSheet,
                ),
                Expanded(
                  child: TextField(
                    key: const ValueKey('chatTextField'),
                    controller: _textController,
                    decoration: const InputDecoration(hintText: 'Message'),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                VoiceNoteRecordButton(
                  onRecorded: (duration) =>
                      notifier.sendVoiceNote(chat.id, duration),
                ),
                IconButton(
                  key: const ValueKey('sendMessageButton'),
                  icon: const Icon(Icons.send),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _messageKindLabel(ChatMessage message) => switch (message.type) {
    MessageType.voice => 'Voice note',
    MessageType.sticker => 'Sticker',
    MessageType.gif => 'GIF',
    MessageType.objectCard => 'Card',
    _ => '',
  };
}

class _MessageBubble extends ConsumerWidget {
  final ChatMessage message;
  final bool isMine;
  final bool receiptsEnabled;
  final String? replyToText;
  final VoidCallback onReply;
  final VoidCallback onStar;
  final VoidCallback onForward;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.receiptsEnabled,
    required this.replyToText,
    required this.onReply,
    required this.onStar,
    required this.onForward,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageActions(context),
        child: Container(
          key: ValueKey('bubble_${message.id}'),
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.sm),
          constraints: const BoxConstraints(maxWidth: 260),
          decoration: BoxDecoration(
            color: isMine
                ? colors.primary.withValues(alpha: 0.15)
                : colors.surfaceAlt,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.forwardedFromChatName != null)
                Text(
                  'Forwarded from ${message.forwardedFromChatName}',
                  style: AppTypography.caption.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              if (replyToText != null)
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: colors.primary, width: 2),
                    ),
                  ),
                  child: Text(
                    replyToText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ),
              _buildContent(context, ref),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.isStarred)
                    Icon(Icons.star, size: 12, color: colors.coin),
                  if (isMine && receiptsEnabled) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 14,
                      color: message.isRead
                          ? colors.primary
                          : colors.textTertiary,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    switch (message.type) {
      case MessageType.text:
        return Text(message.text ?? '');
      case MessageType.sticker:
        return Text('🏏 ${message.text}');
      case MessageType.gif:
        return Text('GIF: ${message.text}');
      case MessageType.voice:
        return VoiceNoteBubble(
          durationSeconds: message.voiceDurationSeconds ?? 1,
        );
      case MessageType.image:
        return const Icon(Icons.image_outlined);
      case MessageType.video:
        return const Icon(Icons.videocam_outlined);
      case MessageType.poll:
        return const Text('Poll');
      case MessageType.objectCard:
        if (message.expenseId != null) {
          final expenses = ref.watch(expensesProvider).expenses;
          final expense = expenses
              .where((e) => e.id == message.expenseId)
              .firstOrNull;
          if (expense == null) return const Text('Expense not found');
          return Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
                Text(
                  '₹${expense.paidTotal} of ₹${expense.amount} paid',
                  key: ValueKey('liveExpenseCardStatus_${expense.id}'),
                  style: AppTypography.caption.copyWith(
                    color: expense.paidRemainder > 0
                        ? colors.textTertiary
                        : colors.success,
                  ),
                ),
              ],
            ),
          );
        }
        final object = message.objectCard;
        if (object == null) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(object.title),
              Text(
                object.subtitle,
                style: AppTypography.caption.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        );
    }
  }

  void _showMessageActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.reply),
            title: const Text('Reply'),
            onTap: () {
              Navigator.of(context).pop();
              onReply();
            },
          ),
          ListTile(
            leading: const Icon(Icons.star_border),
            title: Text(message.isStarred ? 'Unstar' : 'Star'),
            onTap: () {
              Navigator.of(context).pop();
              onStar();
            },
          ),
          ListTile(
            leading: const Icon(Icons.forward),
            title: const Text('Forward'),
            onTap: () {
              Navigator.of(context).pop();
              onForward();
            },
          ),
        ],
      ),
    );
  }
}
