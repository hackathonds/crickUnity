import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import '../profile/achievement_models.dart';
import 'achievements_models.dart';
import 'rewards_models.dart';
import 'rewards_provider.dart';

class AchievementsState {
  final Map<TieredBadgeId, TieredBadgeProgress> progress;
  final List<String> timeline;

  const AchievementsState({this.progress = const {}, this.timeline = const []});

  TieredBadgeProgress progressFor(TieredBadgeId id) =>
      progress[id] ?? const TieredBadgeProgress();

  AchievementsState copyWith({
    Map<TieredBadgeId, TieredBadgeProgress>? progress,
    List<String>? timeline,
  }) {
    return AchievementsState(
      progress: progress ?? this.progress,
      timeline: timeline ?? this.timeline,
    );
  }

  Map<String, dynamic> toJson() => {
    'progress': {
      for (final entry in progress.entries)
        entry.key.name: entry.value.toJson(),
    },
    'timeline': timeline,
  };

  factory AchievementsState.fromJson(Map<String, dynamic> json) {
    return AchievementsState(
      progress: {
        for (final entry in (json['progress'] as Map<String, dynamic>).entries)
          TieredBadgeId.values.byName(entry.key): TieredBadgeProgress.fromJson(
            entry.value as Map<String, dynamic>,
          ),
      },
      timeline: [for (final t in json['timeline'] as List) t as String],
    );
  }
}

/// E6-04 -- badge engine for the 3 tiered badges (see
/// achievements_models.dart). Genuinely wired into the moments that
/// already exist elsewhere this session: scoring_provider.dart's
/// zero-dispute ripple and streaks_provider.dart's playing-streak
/// milestone detection, rather than a standalone mock trigger.
class AchievementsNotifier extends PersistedNotifier<AchievementsState> {
  @override
  String get persistenceKey => 'achievements_v1';

  @override
  AchievementsState seed() => const AchievementsState();

  @override
  Map<String, dynamic> toJson(AchievementsState value) => value.toJson();

  @override
  AchievementsState fromJson(Map<String, dynamic> json) =>
      AchievementsState.fromJson(json);

  void _applyCounter(TieredBadgeId id, int newCounter) {
    final tiers = badgeTiers[id]!;
    final current = state.progressFor(id);
    final crossed = <BadgeTier>[];
    var newTierIndex = current.currentTierIndex;
    for (var i = current.currentTierIndex + 1; i < tiers.length; i++) {
      if (newCounter < tiers[i].threshold) break;
      newTierIndex = i;
      crossed.add(tiers[i]);
    }
    if (newCounter == current.counter && crossed.isEmpty) return;

    final name = tieredBadgeNames[id]!;
    final crossedEntries = [
      for (final tier in crossed)
        '$name -- ${tier.label} tier reached ($newCounter)',
    ];
    state = state.copyWith(
      progress: {
        ...state.progress,
        id: TieredBadgeProgress(
          counter: newCounter,
          currentTierIndex: newTierIndex,
          history: [...current.history, ...crossedEntries],
        ),
      },
      timeline: [...state.timeline, ...crossedEntries],
    );

    for (final tier in crossed) {
      ref
          .read(rewardsProvider.notifier)
          .enqueueCeremony(
            CeremonyEvent(
              type: CeremonyType.badgeUnlock,
              badgeName: name,
              tierLabel: tier.label,
            ),
          );
    }
  }

  /// Wired from scoring_provider.dart's _maybeFireRipple, alongside the
  /// existing E6-01 scorerZeroDisputes coin award, at the same
  /// zero-dispute confirmation moment.
  void recordDisputeFreeMatchScored() {
    _applyCounter(
      TieredBadgeId.scorerSupreme,
      state.progressFor(TieredBadgeId.scorerSupreme).counter + 1,
    );
  }

  /// Wired from streaks_provider.dart's recordActivity milestone block --
  /// [weeks] is the absolute current playing-streak length, not a delta.
  void recordPlayingStreakWeeks(int weeks) {
    _applyCounter(TieredBadgeId.ironPlayer, weeks);
  }

  /// No Ground/booking module exists to detect a real visit -- advanced
  /// only via a manual debug control until that module ships.
  void recordGroundVisited() {
    _applyCounter(
      TieredBadgeId.groundCollector,
      state.progressFor(TieredBadgeId.groundCollector).counter + 1,
    );
  }
}

final achievementsProvider =
    NotifierProvider<AchievementsNotifier, AchievementsState>(
      AchievementsNotifier.new,
    );

const Map<String, TieredBadgeId> _tieredBadgeIdsByName = {
  'Iron Player': TieredBadgeId.ironPlayer,
  'Scorer Supreme': TieredBadgeId.scorerSupreme,
  'Ground Collector': TieredBadgeId.groundCollector,
};

/// Overlays live tier/earned/history state for the 3 tiered badges onto
/// E2-05's static mock catalog; the other 7 badges pass through
/// unchanged. Feeds directly into the existing AchievementsWallScreen's
/// public `badges` param -- reuses that screen, doesn't modify it.
List<AchievementBadge> dataDrivenBadges(AchievementsState state) {
  return [
    for (final badge in mockAchievementBadges())
      if (_tieredBadgeIdsByName[badge.name] case final id?)
        _overlay(badge, state, id)
      else
        badge,
  ];
}

AchievementBadge _overlay(
  AchievementBadge badge,
  AchievementsState state,
  TieredBadgeId id,
) {
  final progress = state.progressFor(id);
  final tier = progress.tierAt(id);
  final next = progress.nextTierFor(id);
  return AchievementBadge(
    name: badge.name,
    color: badge.color,
    category: badge.category,
    earned: tier != null,
    criteria: next == null
        ? '${badge.criteria} (top tier reached)'
        : '${badge.criteria} Next: ${next.label} at ${next.threshold} '
              '(${progress.counter} so far).',
    rarityPercent: badge.rarityPercent,
    friendsWhoHold: badge.friendsWhoHold,
    earnDateAndProvenance: tier == null
        ? null
        : '${tier.label} tier -- ${progress.counter} recorded',
  );
}
