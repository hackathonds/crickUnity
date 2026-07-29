import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'record_models.dart';

/// PRD §14: "Personal Bests: dedicated shelf; PB detection announces in
/// post-match summary ('New PB: best figures 4/18!')." Reuses
/// record_models.dart's RecordCategory for the metric names, restricted
/// to the categories that make sense as an individual's own personal
/// best (not team/global-only categories like highestTeamTotal or
/// youngestCenturion).
const List<RecordCategory> personalBestCategories = [
  RecordCategory.highestIndividualScore,
  RecordCategory.bestBowlingFigures,
  RecordCategory.mostSixesInnings,
];

class PersonalBestsState {
  final Map<RecordCategory, int> bests;
  final List<String> announcements;

  const PersonalBestsState({
    this.bests = const {},
    this.announcements = const [],
  });

  PersonalBestsState copyWith({
    Map<RecordCategory, int>? bests,
    List<String>? announcements,
  }) {
    return PersonalBestsState(
      bests: bests ?? this.bests,
      announcements: announcements ?? this.announcements,
    );
  }

  Map<String, dynamic> toJson() => {
    'bests': {for (final entry in bests.entries) entry.key.name: entry.value},
    'announcements': announcements,
  };

  factory PersonalBestsState.fromJson(Map<String, dynamic> json) {
    return PersonalBestsState(
      bests: {
        for (final entry in (json['bests'] as Map<String, dynamic>).entries)
          RecordCategory.values.byName(entry.key): entry.value as int,
      },
      announcements: [
        for (final a in json['announcements'] as List) a as String,
      ],
    );
  }
}

/// E8-04 -- genuinely wired into scoring_provider.dart's
/// _maybeFireRipple, same scorer-scoped-identity convention as every
/// other match-ripple integration this session.
class PersonalBestsNotifier extends PersistedNotifier<PersonalBestsState> {
  @override
  String get persistenceKey => 'personal_bests_v1';

  @override
  PersonalBestsState seed() => const PersonalBestsState();

  @override
  Map<String, dynamic> toJson(PersonalBestsState value) => value.toJson();

  @override
  PersonalBestsState fromJson(Map<String, dynamic> json) =>
      PersonalBestsState.fromJson(json);

  /// Returns the categories newly set as a PB this call, if any.
  List<RecordCategory> checkPerformance(Map<RecordCategory, int> newValues) {
    final newlySet = <RecordCategory>[];
    var bests = state.bests;
    final announcements = <String>[];

    for (final entry in newValues.entries) {
      final current = bests[entry.key] ?? 0;
      if (entry.value > current) {
        bests = {...bests, entry.key: entry.value};
        newlySet.add(entry.key);
        announcements.add(
          'New PB: ${recordCategoryLabels[entry.key]} -- ${entry.value}!',
        );
      }
    }

    if (newlySet.isNotEmpty) {
      state = state.copyWith(
        bests: bests,
        announcements: [...state.announcements, ...announcements],
      );
    }
    return newlySet;
  }
}

final personalBestsProvider =
    NotifierProvider<PersonalBestsNotifier, PersonalBestsState>(
      PersonalBestsNotifier.new,
    );
