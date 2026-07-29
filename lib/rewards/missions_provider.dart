import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'missions_models.dart';
import 'rewards_provider.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime _weekStart(DateTime d) =>
    _dateOnly(d).subtract(Duration(days: d.weekday - 1));

class MissionsState {
  final Map<MissionTier, List<MissionInstance>> instancesByTier;
  final Map<MissionTier, DateTime> periodKeyByTier;
  final Map<MissionTier, int> refreshTokens;
  final int roleRotationIndex;

  const MissionsState({
    this.instancesByTier = const {},
    this.periodKeyByTier = const {},
    this.refreshTokens = const {},
    this.roleRotationIndex = 0,
  });

  List<MissionInstance> instancesFor(MissionTier tier) =>
      instancesByTier[tier] ?? const [];

  MissionsState copyWith({
    Map<MissionTier, List<MissionInstance>>? instancesByTier,
    Map<MissionTier, DateTime>? periodKeyByTier,
    Map<MissionTier, int>? refreshTokens,
    int? roleRotationIndex,
  }) {
    return MissionsState(
      instancesByTier: instancesByTier ?? this.instancesByTier,
      periodKeyByTier: periodKeyByTier ?? this.periodKeyByTier,
      refreshTokens: refreshTokens ?? this.refreshTokens,
      roleRotationIndex: roleRotationIndex ?? this.roleRotationIndex,
    );
  }

  Map<String, dynamic> toJson() => {
    'instancesByTier': {
      for (final entry in instancesByTier.entries)
        entry.key.name: [for (final i in entry.value) i.toJson()],
    },
    'periodKeyByTier': {
      for (final entry in periodKeyByTier.entries)
        entry.key.name: entry.value.toIso8601String(),
    },
    'refreshTokens': {
      for (final entry in refreshTokens.entries) entry.key.name: entry.value,
    },
    'roleRotationIndex': roleRotationIndex,
  };

  factory MissionsState.fromJson(Map<String, dynamic> json) {
    return MissionsState(
      instancesByTier: {
        for (final entry
            in (json['instancesByTier'] as Map<String, dynamic>).entries)
          MissionTier.values.byName(entry.key): [
            for (final i in entry.value as List)
              MissionInstance.fromJson(i as Map<String, dynamic>),
          ],
      },
      periodKeyByTier: {
        for (final entry
            in (json['periodKeyByTier'] as Map<String, dynamic>).entries)
          MissionTier.values.byName(entry.key): DateTime.parse(
            entry.value as String,
          ),
      },
      refreshTokens: {
        for (final entry
            in (json['refreshTokens'] as Map<String, dynamic>).entries)
          MissionTier.values.byName(entry.key): entry.value as int,
      },
      roleRotationIndex: json['roleRotationIndex'] as int? ?? 0,
    );
  }
}

/// DS §7-54 (Missions Board) + PRD §13.2 -- E6-03's missions engine.
class MissionsNotifier extends PersistedNotifier<MissionsState> {
  @override
  String get persistenceKey => 'missions_v1';

  @override
  MissionsState seed() => const MissionsState();

  @override
  Map<String, dynamic> toJson(MissionsState value) => value.toJson();

  @override
  MissionsState fromJson(Map<String, dynamic> json) =>
      MissionsState.fromJson(json);

  DateTime _periodKeyFor(MissionTier tier, DateTime now) {
    return switch (tier) {
      MissionTier.daily => _dateOnly(now),
      MissionTier.weekly => _weekStart(now),
      MissionTier.monthly => DateTime(now.year, now.month),
      // Epic missions are cumulative across the whole season -- no
      // recurring period, generated once.
      MissionTier.epic => DateTime(now.year),
    };
  }

  /// Backlog: "role-fair pool rotation." Rotates which role category
  /// leads the pick each period so the set isn't skewed toward one
  /// role over time, not just within a single day.
  List<MissionInstance> _roll(MissionTier tier, int rotationIndex, int count) {
    final defs = missionsForTier(tier);
    if (defs.length <= count) {
      return [for (final d in defs) MissionInstance(defId: d.id)];
    }
    final categories = MissionRoleCategory.values;
    final rotated = [
      for (var i = 0; i < categories.length; i++)
        categories[(rotationIndex + i) % categories.length],
    ];
    final picked = <MissionDef>[];
    for (final cat in rotated) {
      if (picked.length >= count) break;
      final match = defs.where(
        (d) => d.roleCategory == cat && !picked.contains(d),
      );
      if (match.isNotEmpty) picked.add(match.first);
    }
    for (final d in defs) {
      if (picked.length >= count) break;
      if (!picked.contains(d)) picked.add(d);
    }
    return [for (final d in picked) MissionInstance(defId: d.id)];
  }

  int _countFor(MissionTier tier) => tier == MissionTier.daily ? 3 : 2;

  /// Ensures every tier's mission set matches the current period,
  /// rerolling (role-fair) whenever a new day/week/month/season starts.
  void ensureCurrentPeriod({DateTime Function() now = DateTime.now}) {
    final n = now();
    var instancesByTier = state.instancesByTier;
    var periodKeyByTier = state.periodKeyByTier;
    var refreshTokens = state.refreshTokens;
    var rotation = state.roleRotationIndex;
    var changed = false;

    for (final tier in MissionTier.values) {
      final key = _periodKeyFor(tier, n);
      if (periodKeyByTier[tier] != key) {
        instancesByTier = {
          ...instancesByTier,
          tier: _roll(tier, rotation, _countFor(tier)),
        };
        periodKeyByTier = {...periodKeyByTier, tier: key};
        refreshTokens = {...refreshTokens, tier: 1};
        if (tier == MissionTier.daily) rotation++;
        changed = true;
      }
    }

    if (changed) {
      state = state.copyWith(
        instancesByTier: instancesByTier,
        periodKeyByTier: periodKeyByTier,
        refreshTokens: refreshTokens,
        roleRotationIndex: rotation,
      );
    }
  }

  /// DS §7-54: "refresh-token chip." Limited (1 per period per tier) --
  /// rerolls that tier's set early without waiting for the next period.
  bool useRefreshToken(MissionTier tier) {
    if ((state.refreshTokens[tier] ?? 0) <= 0) return false;
    final newRotation = tier == MissionTier.daily
        ? state.roleRotationIndex + 1
        : state.roleRotationIndex;
    state = state.copyWith(
      instancesByTier: {
        ...state.instancesByTier,
        tier: _roll(tier, newRotation, _countFor(tier)),
      },
      refreshTokens: {...state.refreshTokens, tier: 0},
      roleRotationIndex: newRotation,
    );
    return true;
  }

  /// Increments progress on every active, unclaimed instance across
  /// every tier whose def matches [actionType].
  void recordAction(MissionActionType actionType, {int amount = 1}) {
    final updated = <MissionTier, List<MissionInstance>>{};
    for (final entry in state.instancesByTier.entries) {
      updated[entry.key] = [
        for (final instance in entry.value)
          if (!instance.claimed && instance.def.actionType == actionType)
            instance.copyWith(
              progress: (instance.progress + amount).clamp(
                0,
                instance.def.target,
              ),
            )
          else
            instance,
      ];
    }
    state = state.copyWith(instancesByTier: updated);
  }

  void claimMission(MissionTier tier, String defId) {
    final instances = state.instancesFor(tier);
    final index = instances.indexWhere((i) => i.defId == defId);
    if (index < 0) return;
    final instance = instances[index];
    if (instance.claimState != MissionClaimState.claimable) return;

    ref
        .read(rewardsProvider.notifier)
        .awardBonus(
          instance.def.coins,
          label: '${missionTierLabels[tier]} mission: ${instance.def.title}',
        );

    final newList = [...instances];
    newList[index] = instance.copyWith(claimed: true);
    state = state.copyWith(
      instancesByTier: {...state.instancesByTier, tier: newList},
    );
  }
}

final missionsProvider = NotifierProvider<MissionsNotifier, MissionsState>(
  MissionsNotifier.new,
);
