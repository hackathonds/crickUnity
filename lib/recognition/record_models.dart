/// Backlog cites "Appx F.9" for the record category taxonomy --
/// Appendix F does not exist anywhere in the frozen PRD (only Appendix
/// A "Acceptance Criteria Pattern" and B "Cross-Module Interaction Map"
/// actually exist, confirmed by grepping every `^# Appendix` heading).
/// Since the categories are this story's entire data model and the PRD
/// gives no fallback description of records at all, this is a bigger
/// gap than the usual missing-detail flags this session -- a curated,
/// real-cricket-domain category list stands in, called out prominently
/// in the PR rather than silently invented.
enum RecordCategory {
  highestIndividualScore,
  bestBowlingFigures,
  highestTeamTotal,
  mostSixesInnings,
  youngestCenturion,
  fastestFifty,
}

const Map<RecordCategory, String> recordCategoryLabels = {
  RecordCategory.highestIndividualScore: 'Highest individual score',
  RecordCategory.bestBowlingFigures: 'Best bowling figures',
  RecordCategory.highestTeamTotal: 'Highest team total',
  RecordCategory.mostSixesInnings: 'Most sixes in an innings',
  RecordCategory.youngestCenturion: 'Youngest centurion',
  RecordCategory.fastestFifty: 'Fastest fifty (balls)',
};

enum RecordScope { ground, tournament, global }

const Map<RecordScope, String> recordScopeLabels = {
  RecordScope.ground: 'Ground',
  RecordScope.tournament: 'Tournament',
  RecordScope.global: 'Global',
};

class RecordTransfer {
  final String? previousHolderName;
  final String newHolderName;
  final int newValue;
  final DateTime transferredAt;

  const RecordTransfer({
    required this.previousHolderName,
    required this.newHolderName,
    required this.newValue,
    required this.transferredAt,
  });

  /// PRD §14 (record-transfer flow): "respectful prior-holder notice."
  String get priorHolderNotice => previousHolderName == null
      ? '$newHolderName set the first record ($newValue).'
      : "$newHolderName has surpassed $previousHolderName's record "
            'with $newValue. $previousHolderName held this record with '
            'distinction -- their achievement remains in the record book.';
}

/// [holderName] null = vacant, rendered as a "be first" card.
class Record {
  final RecordCategory category;
  final RecordScope scope;
  final String scopeLabel;
  final String? holderName;
  final int value;
  final String? provenanceLabel;
  final DateTime? setAt;
  final List<RecordTransfer> transferHistory;

  const Record({
    required this.category,
    required this.scope,
    required this.scopeLabel,
    this.holderName,
    this.value = 0,
    this.provenanceLabel,
    this.setAt,
    this.transferHistory = const [],
  });

  bool get isVacant => holderName == null;

  Record copyWith({
    String? holderName,
    int? value,
    String? provenanceLabel,
    DateTime? setAt,
    List<RecordTransfer>? transferHistory,
  }) {
    return Record(
      category: category,
      scope: scope,
      scopeLabel: scopeLabel,
      holderName: holderName ?? this.holderName,
      value: value ?? this.value,
      provenanceLabel: provenanceLabel ?? this.provenanceLabel,
      setAt: setAt ?? this.setAt,
      transferHistory: transferHistory ?? this.transferHistory,
    );
  }
}

/// PRD names no exact alert threshold -- within 10 runs (or 1 wicket/
/// sixes short) of the record is a flagged judgment call for "live
/// approach alerts."
const int nearRecordThreshold = 10;
