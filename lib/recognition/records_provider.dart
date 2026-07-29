import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../matches/scoring_provider.dart';
import '../persistence/persisted_notifier.dart';
import 'record_models.dart';

class RecordsState {
  final List<Record> records;

  const RecordsState({this.records = const []});

  RecordsState copyWith({List<Record>? records}) =>
      RecordsState(records: records ?? this.records);

  Map<String, dynamic> toJson() => {
    'records': [for (final r in records) r.toJson()],
  };

  factory RecordsState.fromJson(Map<String, dynamic> json) {
    return RecordsState(
      records: [
        for (final r in json['records'] as List)
          Record.fromJson(r as Map<String, dynamic>),
      ],
    );
  }
}

/// Backlog (E8-02) -- records hub engine. See record_models.dart's
/// top-of-file note on the missing "Appx F" category taxonomy.
class RecordsNotifier extends PersistedNotifier<RecordsState> {
  @override
  String get persistenceKey => 'records_v1';

  @override
  RecordsState seed() => RecordsState(records: _seedRecords());

  @override
  Map<String, dynamic> toJson(RecordsState value) => value.toJson();

  @override
  RecordsState fromJson(Map<String, dynamic> json) =>
      RecordsState.fromJson(json);

  static List<Record> _seedRecords() {
    final setAt = DateTime.now().subtract(const Duration(days: 40));
    return [
      Record(
        category: RecordCategory.highestIndividualScore,
        scope: RecordScope.ground,
        scopeLabel: 'Green Valley Ground',
        holderName: 'Arjun Rao',
        value: 132,
        provenanceLabel: 'vs Warriors, 40 days ago',
        setAt: setAt,
      ),
      const Record(
        category: RecordCategory.bestBowlingFigures,
        scope: RecordScope.ground,
        scopeLabel: 'Green Valley Ground',
        // Vacant -- "be first" per DS.
      ),
      Record(
        category: RecordCategory.highestTeamTotal,
        scope: RecordScope.tournament,
        scopeLabel: 'City Premier League',
        holderName: 'Strikers CC',
        value: 245,
        provenanceLabel: 'vs Riverside CC, last season',
        setAt: setAt,
      ),
      const Record(
        category: RecordCategory.mostSixesInnings,
        scope: RecordScope.global,
        scopeLabel: 'CricUnity',
        holderName: 'Kabir Singh',
        value: 9,
        provenanceLabel: 'vs Titans, 2 seasons ago',
      ),
      const Record(
        category: RecordCategory.youngestCenturion,
        scope: RecordScope.global,
        scopeLabel: 'CricUnity',
        // Vacant -- "be first".
      ),
      const Record(
        category: RecordCategory.fastestFifty,
        scope: RecordScope.tournament,
        scopeLabel: 'City Premier League',
        holderName: 'Priya Nair',
        value: 22,
        provenanceLabel: 'vs Warriors, this season',
      ),
    ];
  }

  /// PRD §14 (records): "live approach alerts." Reads the real
  /// scoring_provider.dart inningsProvider (the same live match every
  /// other cross-module reuse this session reads) for the current
  /// striker's runs, comparing against the ground-scope highest-
  /// individual-score record -- not a mocked "would alert" line.
  Record? approachingRecord() {
    final innings = ref.read(inningsProvider);
    final striker = innings.currentStriker;
    final runs = innings.batters[striker]?.runs ?? 0;
    final record = state.records.firstWhere(
      (r) =>
          r.category == RecordCategory.highestIndividualScore &&
          r.scope == RecordScope.ground,
      orElse: () => const Record(
        category: RecordCategory.highestIndividualScore,
        scope: RecordScope.ground,
        scopeLabel: '',
      ),
    );
    if (record.isVacant || record.scopeLabel.isEmpty) return null;
    final remaining = record.value - runs;
    if (remaining > 0 && remaining <= nearRecordThreshold) return record;
    return null;
  }

  /// PRD §14: "record-transfer flow with respectful prior-holder
  /// notice." No real automatic detection pipeline exists for every
  /// record category -- a debug control (records_hub_screen.dart)
  /// triggers this once a new value is known to beat the current one.
  void transferRecord(
    RecordCategory category,
    RecordScope scope,
    String newHolderName,
    int newValue, {
    String? provenanceLabel,
    DateTime Function() now = DateTime.now,
  }) {
    final index = state.records.indexWhere(
      (r) => r.category == category && r.scope == scope,
    );
    if (index < 0) return;
    final record = state.records[index];
    if (!record.isVacant && newValue <= record.value) return;

    final transfer = RecordTransfer(
      previousHolderName: record.holderName,
      newHolderName: newHolderName,
      newValue: newValue,
      transferredAt: now(),
    );
    final updated = [...state.records];
    updated[index] = record.copyWith(
      holderName: newHolderName,
      value: newValue,
      provenanceLabel: provenanceLabel ?? record.provenanceLabel,
      setAt: now(),
      transferHistory: [...record.transferHistory, transfer],
    );
    state = state.copyWith(records: updated);
  }
}

final recordsProvider = NotifierProvider<RecordsNotifier, RecordsState>(
  RecordsNotifier.new,
);
