/// DS §7.10 screen 68 (Analytics screens): "Custom Stats Explorer:
/// query-builder rows (discipline -> filter chips -> qualification
/// stepper) -> results table (sortable, sticky header) ->
/// [Save query][Pin as widget]." Backlog cites this story as "PRD
/// §19.9" -- no such feature (or numbered subsection) exists anywhere in
/// the PRD at all; the real spec lives in the Design Spec instead, a
/// wrong-document citation rather than a phantom one (flagged here since
/// it's still worth correcting in the backlog). "Small-sample caption"
/// is the backlog's own added phrase, not a DS quote -- grounded in the
/// real "minimum-activity qualifications stop one-match wonders" rule
/// (PRD §14 Leaderboards) rather than invented from nothing.
library;

import '../onboarding/profile_wizard_provider.dart' show BattingStyle;
import 'player_analytics_models.dart'
    show BowlerType, bowlerTypeLabels, MatchPhase, matchPhaseLabels;

const Map<BattingStyle, String> _battingStyleFilterLabels = {
  BattingStyle.rhb: 'vs RHB',
  BattingStyle.lhb: 'vs LHB',
};

enum StatsDiscipline { batting, bowling, fielding }

const Map<StatsDiscipline, String> statsDisciplineLabels = {
  StatsDiscipline.batting: 'Batting',
  StatsDiscipline.bowling: 'Bowling',
  StatsDiscipline.fielding: 'Fielding',
};

class StatsQueryFilters {
  final MatchPhase? phase;
  final BowlerType? bowlerType;
  final BattingStyle? battingStyle;
  final int minSample;

  const StatsQueryFilters({
    this.phase,
    this.bowlerType,
    this.battingStyle,
    this.minSample = 0,
  });

  StatsQueryFilters copyWith({
    MatchPhase? phase,
    bool clearPhase = false,
    BowlerType? bowlerType,
    bool clearBowlerType = false,
    BattingStyle? battingStyle,
    bool clearBattingStyle = false,
    int? minSample,
  }) {
    return StatsQueryFilters(
      phase: clearPhase ? null : (phase ?? this.phase),
      bowlerType: clearBowlerType ? null : (bowlerType ?? this.bowlerType),
      battingStyle: clearBattingStyle
          ? null
          : (battingStyle ?? this.battingStyle),
      minSample: minSample ?? this.minSample,
    );
  }

  List<String> get chipLabels => [
    if (phase != null) matchPhaseLabels[phase]!,
    if (bowlerType != null) bowlerTypeLabels[bowlerType]!,
    if (battingStyle != null) _battingStyleFilterLabels[battingStyle]!,
  ];
}

enum StatsSortColumn { match, primary, secondary, sample }

class StatsExplorerRow {
  final String matchLabel;
  final DateTime date;
  final int primaryValue;
  final double secondaryValue;
  final int sampleSize;

  const StatsExplorerRow({
    required this.matchLabel,
    required this.date,
    required this.primaryValue,
    required this.secondaryValue,
    required this.sampleSize,
  });
}

class SavedQuery {
  final String id;
  final String name;
  final StatsDiscipline discipline;
  final StatsQueryFilters filters;

  const SavedQuery({
    required this.id,
    required this.name,
    required this.discipline,
    required this.filters,
  });
}
