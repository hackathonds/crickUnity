import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import '../rewards/missions_models.dart';
import '../rewards/missions_provider.dart';
import '../rewards/rewards_provider.dart';
import 'coach_models.dart';
import 'coach_provider.dart';
import 'training_log_models.dart';

class TrainingLogState {
  final List<TrainingLogEntry> entries;
  final Map<TrainingBadgeId, int> badgeCounters;

  const TrainingLogState({
    this.entries = const [],
    this.badgeCounters = const {},
  });

  TrainingLogState copyWith({
    List<TrainingLogEntry>? entries,
    Map<TrainingBadgeId, int>? badgeCounters,
  }) {
    return TrainingLogState(
      entries: entries ?? this.entries,
      badgeCounters: badgeCounters ?? this.badgeCounters,
    );
  }

  List<TrainingLogEntry> forUser(String userName) =>
      entries.where((e) => e.userName == userName).toList();

  List<TrainingLogEntry> personalBestsFor(String userName, String drillId) =>
      entries
          .where((e) => e.userName == userName && e.drillId == drillId)
          .toList()
        ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));

  int badgeCounterFor(TrainingBadgeId id) => badgeCounters[id] ?? 0;

  int badgeTierIndexFor(TrainingBadgeId id) {
    final counter = badgeCounterFor(id);
    final tiers = trainingBadgeTiers[id]!;
    var index = -1;
    for (var i = 0; i < tiers.length; i++) {
      if (counter >= tiers[i]) index = i;
    }
    return index;
  }

  List<TrainingLogEntry> sessionsThisWeekFor(String userName, DateTime now) {
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    return entries
        .where(
          (e) =>
              e.userName == userName &&
              !e.loggedAt.isBefore(weekStart) &&
              e.loggedAt.isBefore(weekEnd),
        )
        .toList();
  }

  Map<String, dynamic> toJson() => {
    'entries': [for (final e in entries) e.toJson()],
    'badgeCounters': {
      for (final entry in badgeCounters.entries) entry.key.name: entry.value,
    },
  };

  factory TrainingLogState.fromJson(Map<String, dynamic> json) {
    return TrainingLogState(
      entries: [
        for (final e in json['entries'] as List)
          TrainingLogEntry.fromJson(e as Map<String, dynamic>),
      ],
      badgeCounters: {
        for (final entry
            in (json['badgeCounters'] as Map<String, dynamic>).entries)
          TrainingBadgeId.values.byName(entry.key): entry.value as int,
      },
    );
  }
}

/// Backlog E11-05 -- Personal training log engine (Drill Library
/// opened up to all users). See training_log_models.dart's top-of-file
/// note for the exact backlog quote and flagged phantom citations.
class TrainingLogNotifier extends PersistedNotifier<TrainingLogState> {
  @override
  String get persistenceKey => 'training_log_v1';

  @override
  TrainingLogState seed() => const TrainingLogState();

  @override
  Map<String, dynamic> toJson(TrainingLogState value) => value.toJson();

  @override
  TrainingLogState fromJson(Map<String, dynamic> json) =>
      TrainingLogState.fromJson(json);

  /// Backlog: "age workload caps" -- reuses the exact
  /// coach_models.dart maxSessionsPerWeek cap E11-03 established for
  /// coach-assigned sessions, applied here to self-logged ones.
  /// Returns null on success, or a rejection message.
  String? logDrill(
    String userName,
    String drillId,
    int value, {
    bool hasProof = false,
    DateTime Function() now = DateTime.now,
  }) {
    if (state.sessionsThisWeekFor(userName, now()).length >=
        maxSessionsPerWeek) {
      return 'You have already reached the $maxSessionsPerWeek session/week workload cap.';
    }

    final entry = TrainingLogEntry(
      id: 'training-${now().microsecondsSinceEpoch}',
      userName: userName,
      drillId: drillId,
      value: value,
      hasProof: hasProof,
      loggedAt: now(),
    );
    state = state.copyWith(entries: [...state.entries, entry]);

    ref
        .read(missionsProvider.notifier)
        .recordAction(MissionActionType.logTrainingDrill);

    if (hasProof) {
      ref
          .read(rewardsProvider.notifier)
          .awardBonus(proofBonusCoins, label: 'Training log proof bonus');
    }

    final drill = ref
        .read(coachProvider)
        .drills
        .where((d) => d.id == drillId)
        .firstOrNull;
    if (drill != null) {
      for (final badgeId in TrainingBadgeId.values) {
        if (trainingBadgeCategories[badgeId]!.contains(drill.category)) {
          _incrementBadge(badgeId);
        }
      }
    }
    return null;
  }

  void _incrementBadge(TrainingBadgeId id) {
    state = state.copyWith(
      badgeCounters: {...state.badgeCounters, id: badgeCounterFor(id) + 1},
    );
  }

  int badgeCounterFor(TrainingBadgeId id) => state.badgeCounterFor(id);

  /// Backlog: "partner-confirm." No multi-account confirmation system
  /// exists (same flagged convention as every other cross-party flow
  /// this session) -- a named partner confirmation is recorded
  /// directly rather than requiring a second account's real approval.
  void confirmAsPartner(String entryId, String partnerName) {
    state = state.copyWith(
      entries: [
        for (final e in state.entries)
          if (e.id == entryId)
            e.copyWith(partnerConfirmed: true, partnerName: partnerName)
          else
            e,
      ],
    );
  }
}

final trainingLogProvider =
    NotifierProvider<TrainingLogNotifier, TrainingLogState>(
      TrainingLogNotifier.new,
    );
