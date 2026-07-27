import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'year_in_review_models.dart';
import 'year_in_review_provider.dart';

/// PRD §14: "Year in Review: auto-generated December story-format
/// recap ... swipeable, music, one-tap share; every stat card
/// individually excludable before sharing." "Music" here is a
/// decorative mute/unmute icon only -- no real audio package exists in
/// this codebase, flagged.
class YearInReviewScreen extends ConsumerStatefulWidget {
  const YearInReviewScreen({super.key});

  @override
  ConsumerState<YearInReviewScreen> createState() => _YearInReviewScreenState();
}

class _YearInReviewScreenState extends ConsumerState<YearInReviewScreen> {
  bool _musicOn = true;
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(yearInReviewProvider.notifier).generate();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _share() {
    final state = ref.read(yearInReviewProvider);
    final lines = [
      'My CricUnity Year in Review',
      for (final card in state.cards)
        if (!card.excluded)
          '${yearInReviewCardTitles[card.type]}: ${card.value}',
    ];
    Clipboard.setData(ClipboardData(text: lines.join('\n')));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Year in Review copied')));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(yearInReviewProvider);

    if (!state.generated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            key: const ValueKey('yearInReviewMusicToggle'),
            icon: Icon(_musicOn ? Icons.music_note : Icons.music_off),
            onPressed: () => setState(() => _musicOn = !_musicOn),
          ),
          IconButton(
            key: const ValueKey('yearInReviewShareButton'),
            icon: const Icon(Icons.share),
            onPressed: _share,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (state.isLightYear)
              Container(
                key: const ValueKey('lightYearBanner'),
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Light year -- fewer activities logged this year, but '
                  'every one counts!',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: PageView(
                key: const ValueKey('yearInReviewPageView'),
                controller: _pageController,
                children: [
                  for (final card in state.cards)
                    _StoryCard(
                      card: card,
                      onToggleExclude: () => ref
                          .read(yearInReviewProvider.notifier)
                          .toggleExclude(card.type),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final YearInReviewCard card;
  final VoidCallback onToggleExclude;

  const _StoryCard({required this.card, required this.onToggleExclude});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            yearInReviewCardTitles[card.type]!,
            style: AppTypography.label.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            card.value,
            textAlign: TextAlign.center,
            style: AppTypography.h1.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppButton(
            key: ValueKey('excludeCardButton_${card.type.name}'),
            variant: AppButtonVariant.secondary,
            label: card.excluded
                ? 'Excluded -- tap to include'
                : 'Exclude from share',
            onPressed: onToggleExclude,
          ),
        ],
      ),
    );
  }
}
