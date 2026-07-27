import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../rewards/achievements_models.dart';
import '../rewards/achievements_provider.dart';
import '../rewards/rewards_provider.dart';
import '../rewards/streaks_provider.dart';
import '../social/composer_screen.dart';
import '../social/feed_models.dart';
import '../social/feed_provider.dart';
import 'award_models.dart';

class AwardsState {
  final List<AwardWinner> pastWinners;

  const AwardsState({this.pastWinners = const []});

  AwardsState copyWith({List<AwardWinner>? pastWinners}) =>
      AwardsState(pastWinners: pastWinners ?? this.pastWinners);
}

/// PRD §14 -- E8-07's periodic awards engine.
class AwardsNotifier extends Notifier<AwardsState> {
  @override
  AwardsState build() => const AwardsState();

  /// Real signals where this session's existing providers make it
  /// possible; the rest is clearly flagged mock. Single-account app --
  /// this returns whether the viewer genuinely qualifies as a nominee,
  /// not a ranked pool of nominees.
  bool qualifiesFor(AwardCategory category) {
    switch (category) {
      case AwardCategory.consistency:
        return ref.read(streaksProvider).currentPlayingStreakWeeks >= 4;
      case AwardCategory.attendance:
        final progress = ref
            .read(achievementsProvider)
            .progressFor(TieredBadgeId.ironPlayer);
        return progress.tierAt(TieredBadgeId.ironPlayer)?.label == 'Platinum';
      case AwardCategory.volunteer:
        final log = ref.read(rewardsProvider).log;
        return log.where((e) => e.contains('Volunteer duty')).length >= 3;
      case AwardCategory.fairPlay:
      case AwardCategory.fitness:
      case AwardCategory.community:
        // No sportsmanship-voting / personal-training-log / granular
        // reaction-attribution module exists anywhere in this codebase
        // to genuinely check these -- flagged mock, always eligible for
        // the debug declare-winner action below.
        return true;
    }
  }

  /// No other real account exists to hold a genuine city/club-wide
  /// competition against -- this always declares the viewer the winner
  /// once they qualify, flagged. Genuinely posts a real feed
  /// announcement (feed_provider.dart) with an achievement-style
  /// attached object, and appends a certificate.
  void declareWinner(
    AwardCategory category, {
    required String scopeLabel,
    required String periodLabel,
    DateTime Function() now = DateTime.now,
  }) {
    final winner = AwardWinner(
      category: category,
      scopeLabel: scopeLabel,
      winnerName: composerViewerName,
      periodLabel: periodLabel,
      certificateIssuedAt: now(),
    );
    state = state.copyWith(pastWinners: [...state.pastWinners, winner]);

    ref
        .read(feedProvider.notifier)
        .addPost(
          FeedPost(
            id: 'post-award-${now().microsecondsSinceEpoch}',
            authorName: composerViewerName,
            contentText:
                'Won the ${awardCategoryLabels[category]} award for '
                '$scopeLabel -- $periodLabel!',
            attachedObject: AttachedObject(
              type: AttachedObjectType.achievement,
              title: '${awardCategoryLabels[category]} Award',
              subtitle: '$scopeLabel · $periodLabel',
              verified: true,
            ),
            timestamp: now(),
            relationshipScore: 1.0,
            cricketRelevanceScore: 1.0,
          ),
        );
  }
}

final awardsProvider = NotifierProvider<AwardsNotifier, AwardsState>(
  AwardsNotifier.new,
);
