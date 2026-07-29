import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'rank_models.dart';

class RanksState {
  final List<RankProfile> profiles;

  const RanksState({this.profiles = const []});

  RanksState copyWith({List<RankProfile>? profiles}) =>
      RanksState(profiles: profiles ?? this.profiles);

  Map<String, dynamic> toJson() => {
    'profiles': [for (final p in profiles) p.toJson()],
  };

  factory RanksState.fromJson(Map<String, dynamic> json) {
    return RanksState(
      profiles: [
        for (final p in json['profiles'] as List)
          RankProfile.fromJson(p as Map<String, dynamic>),
      ],
    );
  }
}

/// PRD §18 -- E6-08's Ranks engine.
class RanksNotifier extends PersistedNotifier<RanksState> {
  @override
  String get persistenceKey => 'ranks_v1';

  @override
  RanksState seed() => RanksState(profiles: _seedProfiles());

  @override
  Map<String, dynamic> toJson(RanksState value) => value.toJson();

  @override
  RanksState fromJson(Map<String, dynamic> json) => RanksState.fromJson(json);

  static List<RankProfile> _seedProfiles() {
    final now = DateTime.now();
    return [
      RankProfile(
        discipline: RankDiscipline.batting,
        cityLabel: 'Delhi',
        formatLabel: 'Weekend league',
        percentile: 72,
        historicalPeakBand: RankBand.gold,
        lastActiveAt: now.subtract(const Duration(days: 3)),
      ),
      RankProfile(
        discipline: RankDiscipline.bowling,
        cityLabel: 'Delhi',
        formatLabel: 'Weekend league',
        percentile: 38,
        historicalPeakBand: RankBand.silver,
        lastActiveAt: now.subtract(const Duration(days: 90)),
      ),
      RankProfile(
        discipline: RankDiscipline.allRounder,
        cityLabel: 'Delhi',
        formatLabel: 'Weekend league',
        percentile: 55,
        historicalPeakBand: RankBand.gold,
        lastActiveAt: now,
      ),
    ];
  }

  /// No real match-activity feed drives this yet -- debug controls
  /// (ranks_screen.dart) simulate inactivity/reactivation to exercise
  /// the soft-decay rule.
  void simulateInactivity(RankDiscipline discipline) {
    _update(
      discipline,
      (p) => RankProfile(
        discipline: p.discipline,
        cityLabel: p.cityLabel,
        formatLabel: p.formatLabel,
        percentile: p.percentile,
        historicalPeakBand: p.historicalPeakBand,
        lastActiveAt: DateTime.now().subtract(
          const Duration(days: rankDecayInactivityDays + 1),
        ),
      ),
    );
  }

  void recordActivity(RankDiscipline discipline) {
    _update(discipline, (p) {
      final computedBand = bandForPercentile(p.percentile);
      final peakIndex = RankBand.values.indexOf(p.historicalPeakBand);
      final computedIndex = RankBand.values.indexOf(computedBand);
      return RankProfile(
        discipline: p.discipline,
        cityLabel: p.cityLabel,
        formatLabel: p.formatLabel,
        percentile: p.percentile,
        historicalPeakBand: computedIndex > peakIndex
            ? computedBand
            : p.historicalPeakBand,
        lastActiveAt: DateTime.now(),
      );
    });
  }

  void _update(
    RankDiscipline discipline,
    RankProfile Function(RankProfile) transform,
  ) {
    state = state.copyWith(
      profiles: [
        for (final p in state.profiles)
          if (p.discipline == discipline) transform(p) else p,
      ],
    );
  }
}

final ranksProvider = NotifierProvider<RanksNotifier, RanksState>(
  RanksNotifier.new,
);
