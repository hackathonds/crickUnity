/// DS §7.6 item 46 (Coach Console): "batch cards -> student roster
/// (progress rings 44 per student) -> session planner (template picker
/// grid from Drill Library, drill cards showing prescription) ->
/// progress-card composer (approve -> send). Guardian view mirrors
/// student scope read-only."
///
/// Backlog cites "PRD Appx E" -- no Appendix E exists anywhere in the
/// frozen PRD (only Appendix A and B are real, same phantom-citation
/// pattern flagged repeatedly this session). Age autoscaling factors
/// and workload caps are therefore flagged judgment calls, not
/// PRD-given numbers.
library;

enum DrillCategory { batting, bowling, fielding, fitness }

const Map<DrillCategory, String> drillCategoryLabels = {
  DrillCategory.batting: 'Batting',
  DrillCategory.bowling: 'Bowling',
  DrillCategory.fielding: 'Fielding',
  DrillCategory.fitness: 'Fitness',
};

class Drill {
  final String id;
  final String name;
  final DrillCategory category;

  /// Base prescription for an adult (18+) student -- "sets x reps" or
  /// a duration count, scaled down for younger age bands by
  /// [scaledPrescription].
  final int baseSets;
  final int baseReps;

  const Drill({
    required this.id,
    required this.name,
    required this.category,
    required this.baseSets,
    required this.baseReps,
  });
}

enum AgeBand { under12, age12to15, age16to18, adult }

const Map<AgeBand, String> ageBandLabels = {
  AgeBand.under12: 'Under 12',
  AgeBand.age12to15: '12-15',
  AgeBand.age16to18: '16-18',
  AgeBand.adult: '18+',
};

/// Backlog: "age autoscaling." No PRD formula exists (Appx E is
/// phantom) -- a flagged judgment call: younger bands scale reps down
/// to protect against overuse.
const Map<AgeBand, double> ageScalingFactor = {
  AgeBand.under12: 0.5,
  AgeBand.age12to15: 0.7,
  AgeBand.age16to18: 0.85,
  AgeBand.adult: 1.0,
};

(int sets, int reps) scaledPrescription(Drill drill, AgeBand ageBand) {
  final factor = ageScalingFactor[ageBand]!;
  return (
    (drill.baseSets * factor).round().clamp(1, drill.baseSets),
    (drill.baseReps * factor).round().clamp(1, drill.baseReps),
  );
}

/// Backlog: "workload caps." No PRD number exists -- a flagged
/// judgment call: max sessions per student per week.
const int maxSessionsPerWeek = 5;

class TemplateSession {
  final String id;
  final String name;
  final List<String> drillIds;

  const TemplateSession({
    required this.id,
    required this.name,
    required this.drillIds,
  });
}

class AssignedSession {
  final String id;
  final String studentName;
  final String templateId;
  final DateTime date;

  const AssignedSession({
    required this.id,
    required this.studentName,
    required this.templateId,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentName': studentName,
    'templateId': templateId,
    'date': date.toIso8601String(),
  };

  factory AssignedSession.fromJson(Map<String, dynamic> json) {
    return AssignedSession(
      id: json['id'] as String,
      studentName: json['studentName'] as String,
      templateId: json['templateId'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }
}

/// Backlog: "drill PB graphs." A simple value-over-time series stands
/// in for a full chart (hand-rolled charting is deferred to E13-01
/// "Chart library completion," same convention already established
/// elsewhere this session for out-of-proportion visualization asks).
class DrillPersonalBest {
  final String studentName;
  final String drillId;
  final int value;
  final DateTime recordedAt;

  const DrillPersonalBest({
    required this.studentName,
    required this.drillId,
    required this.value,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
    'studentName': studentName,
    'drillId': drillId,
    'value': value,
    'recordedAt': recordedAt.toIso8601String(),
  };

  factory DrillPersonalBest.fromJson(Map<String, dynamic> json) {
    return DrillPersonalBest(
      studentName: json['studentName'] as String,
      drillId: json['drillId'] as String,
      value: json['value'] as int,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
    );
  }
}

class ProgressCard {
  final String id;
  final String studentName;
  final String monthLabel;
  final String notes;
  final bool approved;
  final DateTime? sentAt;

  /// Backlog addendum (PRD §2.8): "progress notes for minors visible
  /// to guardian account."
  final bool visibleToGuardian;

  const ProgressCard({
    required this.id,
    required this.studentName,
    required this.monthLabel,
    required this.notes,
    this.approved = false,
    this.sentAt,
    this.visibleToGuardian = false,
  });

  ProgressCard copyWith({bool? approved, DateTime? sentAt}) {
    return ProgressCard(
      id: id,
      studentName: studentName,
      monthLabel: monthLabel,
      notes: notes,
      approved: approved ?? this.approved,
      sentAt: sentAt ?? this.sentAt,
      visibleToGuardian: visibleToGuardian,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentName': studentName,
    'monthLabel': monthLabel,
    'notes': notes,
    'approved': approved,
    'sentAt': sentAt?.toIso8601String(),
    'visibleToGuardian': visibleToGuardian,
  };

  factory ProgressCard.fromJson(Map<String, dynamic> json) {
    return ProgressCard(
      id: json['id'] as String,
      studentName: json['studentName'] as String,
      monthLabel: json['monthLabel'] as String,
      notes: json['notes'] as String,
      approved: json['approved'] as bool? ?? false,
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'] as String)
          : null,
      visibleToGuardian: json['visibleToGuardian'] as bool? ?? false,
    );
  }
}
