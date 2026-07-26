import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_avatar.dart';

/// DS §3.13's composer: "docked bottom 56h (grows to 3 lines), avatar 28,
/// send icon activates on input." DS §3.23's own avatar scale is a closed
/// list -- "Sizes 24/32/40/48/64/96" -- with no 28 step; this is a
/// genuine, flagged mismatch, not silently guessed. `AppAvatarSize.xs`
/// (24, the nearest smaller step) is used here rather than inventing a
/// new size on the shared avatar scale for one caller.
class AppCommentComposer extends StatefulWidget {
  final String authorName;
  final ImageProvider? avatarImage;
  final String hintText;
  final ValueChanged<String> onSubmit;

  const AppCommentComposer({
    super.key,
    required this.authorName,
    required this.onSubmit,
    this.avatarImage,
    this.hintText = 'Add a comment...',
  });

  @override
  State<AppCommentComposer> createState() => AppCommentComposerState();
}

class AppCommentComposerState extends State<AppCommentComposer> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      key: const ValueKey('appCommentComposerBox'),
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AppAvatar(
            size: AppAvatarSize.xs,
            name: widget.authorName,
            image: widget.avatarImage,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              key: const ValueKey('appCommentComposerInput'),
              controller: _controller,
              minLines: 1,
              maxLines: 3,
              style: AppTypography.body.copyWith(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: AppTypography.body.copyWith(
                  color: colors.textTertiary,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // No "send" glyph exists in DS §2.5's icon families -- a plain
          // arrow character, not a new hand-drawn icon for one use.
          GestureDetector(
            key: const ValueKey('appCommentComposerSend'),
            onTap: _hasText ? _submit : null,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Text(
                  '➤',
                  style: TextStyle(
                    fontSize: 20,
                    color: _hasText ? colors.primary : colors.disabledFg,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single comment's data — kept separate from the row widget so replies
/// (also `AppCommentData`) can be rendered by the same row builder at an
/// indent.
class AppCommentData {
  final String authorName;
  final ImageProvider? avatarImage;
  final String timeAgo;
  final String body;
  final int propsCount;
  final List<AppCommentData> replies;

  const AppCommentData({
    required this.authorName,
    required this.timeAgo,
    required this.body,
    this.avatarImage,
    this.propsCount = 0,
    this.replies = const [],
  });
}

/// DS §3.13's thread rows: "avatar 32, name+time row, body, action row
/// (Props · Reply) 13; replies indent 40 with 2px rail; 'View 4 replies'
/// expands inline 240ms."
class AppCommentThread extends StatelessWidget {
  final List<AppCommentData> comments;
  final ValueChanged<AppCommentData>? onPropsTap;
  final ValueChanged<AppCommentData>? onReplyTap;

  const AppCommentThread({
    super.key,
    required this.comments,
    this.onPropsTap,
    this.onReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final comment in comments)
          _CommentRow(
            comment: comment,
            onPropsTap: onPropsTap,
            onReplyTap: onReplyTap,
          ),
      ],
    );
  }
}

class _CommentRow extends StatefulWidget {
  final AppCommentData comment;
  final ValueChanged<AppCommentData>? onPropsTap;
  final ValueChanged<AppCommentData>? onReplyTap;
  final bool isReply;

  const _CommentRow({
    required this.comment,
    this.onPropsTap,
    this.onReplyTap,
    this.isReply = false,
  });

  @override
  State<_CommentRow> createState() => _CommentRowState();
}

class _CommentRowState extends State<_CommentRow> {
  bool _repliesExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final comment = widget.comment;

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppAvatar(
          size: AppAvatarSize.sm,
          name: comment.authorName,
          image: comment.avatarImage,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.authorName,
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    comment.timeAgo,
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                comment.body,
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  GestureDetector(
                    onTap: widget.onPropsTap == null
                        ? null
                        : () => widget.onPropsTap!(comment),
                    child: Text(
                      comment.propsCount > 0
                          ? 'Props · ${comment.propsCount}'
                          : 'Props',
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  GestureDetector(
                    onTap: widget.onReplyTap == null
                        ? null
                        : () => widget.onReplyTap!(comment),
                    child: Text(
                      'Reply',
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              if (comment.replies.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                GestureDetector(
                  key: const ValueKey('appCommentViewRepliesToggle'),
                  onTap: () =>
                      setState(() => _repliesExpanded = !_repliesExpanded),
                  child: Text(
                    _repliesExpanded
                        ? 'Hide replies'
                        : 'View ${comment.replies.length} replies',
                    style: AppTypography.caption.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: AppMotion.resolveDuration(
                    context,
                    AppMotionToken.standard,
                  ),
                  curve: AppMotionCurves.standard,
                  child: _repliesExpanded
                      ? Column(
                          key: const ValueKey('appCommentRepliesColumn'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final reply in comment.replies)
                              _CommentRow(
                                comment: reply,
                                onPropsTap: widget.onPropsTap,
                                onReplyTap: widget.onReplyTap,
                                isReply: true,
                              ),
                          ],
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    // A Stack rather than IntrinsicHeight -- the rail is a Positioned
    // child (doesn't affect the Stack's own sizing), while `content`
    // determines the Stack's height. Avoids IntrinsicHeight's per-child
    // intrinsic-size computation, which recurses expensively (and each
    // reply is itself a `_CommentRow`, so nesting would compound it) --
    // especially awkward alongside `AnimatedSize`-driven replies.
    final row = widget.isReply
        ? Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  key: const ValueKey('appCommentReplyRail'),
                  width: 2,
                  color: colors.divider,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.md),
                child: content,
              ),
            ],
          )
        : content;

    return Padding(
      padding: EdgeInsets.only(
        left: widget.isReply ? 40 : 0,
        top: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: row,
    );
  }
}
