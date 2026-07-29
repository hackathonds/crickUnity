/// Backlog addendum -- cites "PRD §14, §4.23"; no §4.2x heading exists
/// anywhere in the PRD, flagged. PRD §14's actual text: "weekly rings
/// (Play / Train / Contribute) with user-set targets; ring-close
/// streaks." Distinct from Goals (E8-05) -- a fixed weekly triad, not
/// user-created arbitrary metric/target/period cards.
enum RingType { play, train, contribute }

const Map<RingType, String> ringTypeLabels = {
  RingType.play: 'Play',
  RingType.train: 'Train',
  RingType.contribute: 'Contribute',
};

const Map<RingType, int> defaultWeeklyTargets = {
  RingType.play: 2,
  RingType.train: 3,
  RingType.contribute: 1,
};

class WeeklyRingProgress {
  final RingType type;
  final int target;
  final int progress;
  final int closeStreak;
  final DateTime weekStart;

  const WeeklyRingProgress({
    required this.type,
    required this.target,
    this.progress = 0,
    this.closeStreak = 0,
    required this.weekStart,
  });

  bool get isClosed => progress >= target;

  double get fraction => target == 0 ? 0 : (progress / target).clamp(0.0, 1.0);

  WeeklyRingProgress copyWith({
    int? target,
    int? progress,
    int? closeStreak,
    DateTime? weekStart,
  }) {
    return WeeklyRingProgress(
      type: type,
      target: target ?? this.target,
      progress: progress ?? this.progress,
      closeStreak: closeStreak ?? this.closeStreak,
      weekStart: weekStart ?? this.weekStart,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'target': target,
    'progress': progress,
    'closeStreak': closeStreak,
    'weekStart': weekStart.toIso8601String(),
  };

  factory WeeklyRingProgress.fromJson(Map<String, dynamic> json) {
    return WeeklyRingProgress(
      type: RingType.values.byName(json['type'] as String),
      target: json['target'] as int,
      progress: json['progress'] as int? ?? 0,
      closeStreak: json['closeStreak'] as int? ?? 0,
      weekStart: DateTime.parse(json['weekStart'] as String),
    );
  }
}
