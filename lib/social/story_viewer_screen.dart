import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_tag_chip.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import '../matches/scoring_provider.dart';
import 'composer_screen.dart';
import 'feed_models.dart';
import 'stories_provider.dart';

/// DS §60: "standard viewers; score-sticker live-updating outlined
/// `live`." PRD §12.3: "score sticker pulls live match score into the
/// story and stays live." Reads the real inningsProvider on every
/// build (not a frozen snapshot) so the score genuinely updates if the
/// underlying match state changes while the story is open.
class StoryViewerScreen extends ConsumerStatefulWidget {
  final String authorName;

  const StoryViewerScreen({super.key, required this.authorName});

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen> {
  int _index = 0;
  final _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final stories = ref
        .watch(storiesProvider)
        .stories
        .where((s) => s.authorName == widget.authorName && !s.isExpired(now))
        .toList();
    final notifier = ref.read(storiesProvider.notifier);

    if (stories.isEmpty) {
      return const Scaffold(body: Center(child: Text('No active stories')));
    }
    final index = _index.clamp(0, stories.length - 1);
    final story = stories[index];
    final isOwnStory = story.authorName == composerViewerName;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isOwnStory) notifier.recordView(story.id, composerViewerName);
    });

    final innings = ref.watch(inningsProvider);
    final scoreLine =
        '${innings.battingTeamName} ${innings.totalRuns}/${innings.wicketsLost} '
        '(${innings.completedOvers}.${innings.legalBallsThisOver} ov)';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTapUp: (details) {
            final half = MediaQuery.of(context).size.width / 2;
            setState(() {
              if (details.globalPosition.dx < half) {
                if (index > 0) _index = index - 1;
              } else {
                if (index < stories.length - 1) {
                  _index = index + 1;
                } else {
                  Navigator.of(context).pop();
                }
              }
            });
          },
          child: Column(
            children: [
              Row(
                children: [
                  for (var i = 0; i < stories.length; i++)
                    Expanded(
                      child: Container(
                        key: ValueKey('storySegment_$i'),
                        height: 3,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: AppSpacing.sm,
                        ),
                        color: i <= index ? Colors.white : Colors.white24,
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        story.authorName,
                        style: AppTypography.subtitle.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (isOwnStory)
                      IconButton(
                        key: const ValueKey('viewersListButton'),
                        icon: const Icon(Icons.visibility, color: Colors.white),
                        onPressed: () =>
                            _showViewers(context, story.viewerNames),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        story.mediaLabel,
                        style: AppTypography.h2.copyWith(color: Colors.white),
                      ),
                      if (story.scoreSticker != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        AppTagChip(
                          key: const ValueKey('storyScoreSticker'),
                          label:
                              '${story.scoreSticker!.matchLabel} · $scoreLine',
                          variant: AppTagChipVariant.error,
                        ),
                      ],
                      if (story.pollSticker != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _StoryPollSticker(
                          key: const ValueKey('storyPollSticker'),
                          poll: story.pollSticker!,
                          onVote: (i) => notifier.votePollSticker(story.id, i),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (!isOwnStory)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const ValueKey('storyReplyField'),
                          controller: _replyController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Reply via DM...',
                            hintStyle: TextStyle(color: Colors.white54),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('storyReplySendButton'),
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () {
                          if (_replyController.text.trim().isEmpty) return;
                          notifier.replyViaDm(
                            story.id,
                            _replyController.text.trim(),
                          );
                          _replyController.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reply sent')),
                          );
                        },
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: TextButton.icon(
                    key: const ValueKey('saveHighlightButton'),
                    onPressed: story.highlightSaved
                        ? null
                        : () => notifier.saveHighlight(story.id),
                    icon: const Icon(
                      Icons.bookmark_outline,
                      color: Colors.white,
                    ),
                    label: Text(
                      story.highlightSaved
                          ? 'Saved to Highlights'
                          : 'Save highlight',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showViewers(BuildContext context, List<String> viewers) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Viewers (${viewers.length})', style: AppTypography.label),
            const SizedBox(height: AppSpacing.sm),
            if (viewers.isEmpty)
              const Text('No views yet.')
            else
              for (final v in viewers) Text(v),
          ],
        ),
      ),
    );
  }
}

class _StoryPollSticker extends StatelessWidget {
  final Poll poll;
  final ValueChanged<int> onVote;

  const _StoryPollSticker({
    super.key,
    required this.poll,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final voted = poll.votedOptionIndex != null;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(poll.question, style: AppTypography.body),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < poll.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: OutlinedButton(
                onPressed: voted ? null : () => onVote(i),
                child: Text(poll.options[i].text),
              ),
            ),
        ],
      ),
    );
  }
}
