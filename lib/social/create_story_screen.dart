import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/components/app_text_field.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'composer_screen.dart';
import 'feed_models.dart';
import 'stories_provider.dart';
import 'story_models.dart';

/// PRD §12.3: "Stories: 24h, media + stickers ... poll/quiz stickers."
/// No real camera/media capture exists -- a text label stands in for
/// the media, same convention as every other missing-media-pipeline
/// gap this session (feed media is likewise a count, not real files).
class CreateStoryScreen extends ConsumerStatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  ConsumerState<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends ConsumerState<CreateStoryScreen> {
  final _mediaController = TextEditingController(text: 'My story');
  bool _attachScoreSticker = false;
  bool _attachPoll = false;
  final _pollQuestionController = TextEditingController();
  final _pollOption1Controller = TextEditingController();
  final _pollOption2Controller = TextEditingController();

  @override
  void dispose() {
    _mediaController.dispose();
    _pollQuestionController.dispose();
    _pollOption1Controller.dispose();
    _pollOption2Controller.dispose();
    super.dispose();
  }

  void _submit() {
    Poll? poll;
    if (_attachPoll && _pollQuestionController.text.trim().isNotEmpty) {
      poll = Poll(
        question: _pollQuestionController.text.trim(),
        options: [
          if (_pollOption1Controller.text.trim().isNotEmpty)
            PollOption(text: _pollOption1Controller.text.trim()),
          if (_pollOption2Controller.text.trim().isNotEmpty)
            PollOption(text: _pollOption2Controller.text.trim()),
        ],
      );
    }
    ref
        .read(storiesProvider.notifier)
        .postStory(
          authorName: composerViewerName,
          mediaLabel: _mediaController.text.trim().isEmpty
              ? 'My story'
              : _mediaController.text.trim(),
          scoreSticker: _attachScoreSticker
              ? const LiveScoreSticker(matchLabel: 'Live match')
              : null,
          pollSticker: (poll != null && poll.options.length >= 2) ? poll : null,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New story'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: AppButton(
              key: const ValueKey('postStoryButton'),
              variant: AppButtonVariant.primary,
              label: 'Post',
              onPressed: _submit,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppTextField(
            key: const ValueKey('storyMediaLabelField'),
            label: 'Story caption',
            controller: _mediaController,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Stickers',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              ChoiceChip(
                key: const ValueKey('scoreStickerChip'),
                label: const Text('Live score'),
                selected: _attachScoreSticker,
                onSelected: (v) => setState(() => _attachScoreSticker = v),
              ),
              ChoiceChip(
                key: const ValueKey('pollStickerChip'),
                label: const Text('Poll'),
                selected: _attachPoll,
                onSelected: (v) => setState(() => _attachPoll = v),
              ),
            ],
          ),
          if (_attachPoll) ...[
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const ValueKey('storyPollQuestionField'),
              label: 'Poll question',
              controller: _pollQuestionController,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              key: const ValueKey('storyPollOption1Field'),
              label: 'Option 1',
              controller: _pollOption1Controller,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              key: const ValueKey('storyPollOption2Field'),
              label: 'Option 2',
              controller: _pollOption2Controller,
            ),
          ],
        ],
      ),
    );
  }
}
