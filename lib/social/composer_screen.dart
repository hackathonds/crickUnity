import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_segmented_control.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'feed_models.dart';
import 'feed_provider.dart';

const String composerViewerName = 'Deepak Sharma';

/// DS §7-58: "Composer full sheet: text area top, attach rail (media/
/// object/poll/feeling), audience selector row (persistent visible --
/// privacy always one glance away), [Post] disabled-until-content."
/// Doubles as the edit screen when [editingPost] is passed -- PRD §12.2's
/// "Edit window: unlimited" reuses the same composer rather than a
/// second parallel edit UI.
class ComposerScreen extends ConsumerStatefulWidget {
  final FeedPost? editingPost;

  const ComposerScreen({super.key, this.editingPost});

  @override
  ConsumerState<ComposerScreen> createState() => _ComposerScreenState();
}

class _ComposerScreenState extends ConsumerState<ComposerScreen> {
  late final TextEditingController _textController;
  late PostAudience _audience;
  AttachedObject? _attachedObject;
  int _mediaCount = 0;
  bool _showPollBuilder = false;
  final _pollQuestionController = TextEditingController();
  final List<TextEditingController> _pollOptionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  bool get _isEditing => widget.editingPost != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editingPost;
    _textController = TextEditingController(text: editing?.contentText ?? '');
    _audience = editing?.audience ?? ref.read(feedProvider).lastUsedAudience;
    _attachedObject = editing?.attachedObject;
    _mediaCount = editing?.mediaCount ?? 0;
  }

  @override
  void dispose() {
    _textController.dispose();
    _pollQuestionController.dispose();
    for (final c in _pollOptionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _hasContent =>
      _textController.text.trim().isNotEmpty ||
      _attachedObject != null ||
      (_showPollBuilder && _pollQuestionController.text.trim().isNotEmpty);

  void _addPollOption() {
    if (_pollOptionControllers.length >= 4) return;
    setState(() => _pollOptionControllers.add(TextEditingController()));
  }

  void _submit() {
    final notifier = ref.read(feedProvider.notifier);
    if (_isEditing) {
      notifier.editPost(widget.editingPost!.id, _textController.text.trim());
      Navigator.of(context).pop();
      return;
    }

    Poll? poll;
    if (_showPollBuilder && _pollQuestionController.text.trim().isNotEmpty) {
      final options = [
        for (final c in _pollOptionControllers)
          if (c.text.trim().isNotEmpty) PollOption(text: c.text.trim()),
      ];
      if (options.length >= 2) {
        poll = Poll(
          question: _pollQuestionController.text.trim(),
          options: options,
        );
      }
    }

    notifier.addPost(
      FeedPost(
        id: 'post-${DateTime.now().microsecondsSinceEpoch}',
        authorName: composerViewerName,
        contentText: _textController.text.trim(),
        attachedObject: _attachedObject,
        mediaCount: _mediaCount,
        timestamp: DateTime.now(),
        isFollowed: true,
        relationshipScore: 1.0,
        cricketRelevanceScore: 1.0,
        audience: _audience,
        poll: poll,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit post' : 'New post'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: AppButton(
              key: const ValueKey('composerPostButton'),
              variant: AppButtonVariant.primary,
              label: 'Post',
              onPressed: _hasContent ? _submit : null,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          TextField(
            key: const ValueKey('composerTextArea'),
            controller: _textController,
            maxLines: null,
            minLines: 4,
            maxLength: 2000,
            onChanged: (_) => setState(() {}),
            style: AppTypography.body.copyWith(color: colors.textPrimary),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: "What's happening on the pitch?",
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Attach',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final object in mockAttachableObjects)
                ChoiceChip(
                  key: ValueKey('attachObjectChip_${object.title}'),
                  label: Text(object.title),
                  selected: _attachedObject?.title == object.title,
                  onSelected: (selected) => setState(
                    () => _attachedObject = selected ? object : null,
                  ),
                ),
              ActionChip(
                key: const ValueKey('addMediaChip'),
                avatar: const Icon(Icons.photo_outlined, size: 16),
                label: Text('Media ($_mediaCount)'),
                onPressed: () => setState(() => _mediaCount++),
              ),
              if (!_isEditing)
                ChoiceChip(
                  key: const ValueKey('addPollChip'),
                  label: const Text('Poll'),
                  selected: _showPollBuilder,
                  onSelected: (selected) =>
                      setState(() => _showPollBuilder = selected),
                ),
            ],
          ),
          if (_showPollBuilder) ...[
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const ValueKey('pollQuestionField'),
              label: 'Poll question',
              controller: _pollQuestionController,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < _pollOptionControllers.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppTextField(
                  key: ValueKey('pollOptionField_$i'),
                  label: 'Option ${i + 1}',
                  controller: _pollOptionControllers[i],
                ),
              ),
            if (_pollOptionControllers.length < 4)
              AppButton(
                key: const ValueKey('addPollOptionButton'),
                variant: AppButtonVariant.tertiary,
                label: 'Add option',
                onPressed: _addPollOption,
              ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Audience',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppSegmentedControl<PostAudience>(
            key: const ValueKey('composerAudienceSelector'),
            options: PostAudience.values,
            value: _audience,
            onChanged: (value) => setState(() => _audience = value),
            labelBuilder: (audience) => postAudienceLabels[audience]!,
          ),
        ],
      ),
    );
  }
}
