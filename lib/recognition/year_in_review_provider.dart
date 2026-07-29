import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_reaction_picker.dart';
import '../persistence/persisted_notifier.dart';
import '../rewards/achievements_provider.dart';
import '../rewards/streaks_provider.dart';
import '../social/composer_screen.dart';
import '../social/feed_provider.dart';
import 'year_in_review_models.dart';

class YearInReviewState {
  final List<YearInReviewCard> cards;
  final bool generated;

  const YearInReviewState({this.cards = const [], this.generated = false});

  bool get isLightYear {
    // PRD: "<5 activities: 'light year' variant." Counts only the
    // genuinely-derived (non-mocked) activity signals.
    final realCards = cards.where((c) => !c.isMocked);
    var total = 0;
    for (final card in realCards) {
      total += int.tryParse(card.value) ?? 0;
    }
    return total < 5;
  }

  YearInReviewState copyWith({List<YearInReviewCard>? cards, bool? generated}) {
    return YearInReviewState(
      cards: cards ?? this.cards,
      generated: generated ?? this.generated,
    );
  }

  Map<String, dynamic> toJson() => {
    'cards': [for (final c in cards) c.toJson()],
    'generated': generated,
  };

  factory YearInReviewState.fromJson(Map<String, dynamic> json) {
    return YearInReviewState(
      cards: [
        for (final c in json['cards'] as List)
          YearInReviewCard.fromJson(c as Map<String, dynamic>),
      ],
      generated: json['generated'] as bool? ?? false,
    );
  }
}

/// PRD §14 -- E8-06's Year in Review engine. Pulls genuinely real
/// numbers where this session's existing providers make it possible;
/// the rest is clearly flagged mock since no season-long stats
/// aggregator exists anywhere in this codebase.
class YearInReviewNotifier extends PersistedNotifier<YearInReviewState> {
  @override
  String get persistenceKey => 'year_in_review_v1';

  @override
  YearInReviewState seed() => const YearInReviewState();

  @override
  Map<String, dynamic> toJson(YearInReviewState value) => value.toJson();

  @override
  YearInReviewState fromJson(Map<String, dynamic> json) =>
      YearInReviewState.fromJson(json);

  void generate() {
    final streaks = ref.read(streaksProvider);
    final achievements = ref.read(achievementsProvider);
    final feed = ref.read(feedProvider);

    final badgesEarned = achievements.progress.values.fold(
      0,
      (sum, p) => sum + p.history.length,
    );

    var propsReceived = 0;
    for (final post in feed.posts) {
      if (post.authorName == composerViewerName) {
        propsReceived += post.reactions[AppReactionType.clap] ?? 0;
      }
    }

    final cards = [
      const YearInReviewCard(
        type: YearInReviewCardType.matches,
        value: '18',
        isMocked: true,
      ),
      const YearInReviewCard(
        type: YearInReviewCardType.runsWickets,
        value: '540 runs, 8 wickets',
        isMocked: true,
      ),
      const YearInReviewCard(
        type: YearInReviewCardType.favoriteGround,
        value: 'Green Valley Ground',
        isMocked: true,
      ),
      YearInReviewCard(
        type: YearInReviewCardType.longestStreak,
        value: '${streaks.currentPlayingStreakWeeks}',
      ),
      const YearInReviewCard(
        type: YearInReviewCardType.bestPerformance,
        value: '54* (38) vs Riverside CC',
        isMocked: true,
      ),
      YearInReviewCard(
        type: YearInReviewCardType.propsReceived,
        value: '$propsReceived',
      ),
      const YearInReviewCard(
        type: YearInReviewCardType.moneyFairShare,
        value: 'Settled 100% on time',
        isMocked: true,
      ),
      YearInReviewCard(
        type: YearInReviewCardType.badgesEarned,
        value: '$badgesEarned',
      ),
    ];

    state = state.copyWith(cards: cards, generated: true);
  }

  void toggleExclude(YearInReviewCardType type) {
    state = state.copyWith(
      cards: [
        for (final c in state.cards)
          if (c.type == type) c.copyWith(excluded: !c.excluded) else c,
      ],
    );
  }
}

final yearInReviewProvider =
    NotifierProvider<YearInReviewNotifier, YearInReviewState>(
      YearInReviewNotifier.new,
    );
