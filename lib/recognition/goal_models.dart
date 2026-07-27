import 'leaderboard_models.dart';

/// DS §11.15: "Goals screen (Profile): goal cards with pace ring +
/// on/off-track chip; create-goal sheet (metric picker -> target
/// stepper -> period); coach-proposed goals arrive as accept/decline
/// cards." Backlog cites "G.11" -- no Appendix G exists in the frozen
/// PRD (only A and B), flagged like every prior citation gap this
/// session.
enum GoalPeriod { week, month, season }

const Map<GoalPeriod, String> goalPeriodLabels = {
  GoalPeriod.week: 'Week',
  GoalPeriod.month: 'Month',
  GoalPeriod.season: 'Season',
};

const Map<GoalPeriod, Duration> goalPeriodDurations = {
  GoalPeriod.week: Duration(days: 7),
  GoalPeriod.month: Duration(days: 30),
  GoalPeriod.season: Duration(days: 180),
};

enum GoalStatus { pending, accepted, declined }

/// Reuses leaderboard_models.dart's LeaderboardMetric as the goal
/// metric picker's options -- same measurable quantities, no need for a
/// second metric enum.
class Goal {
  final String id;
  final LeaderboardMetric metric;
  final int target;
  final GoalPeriod period;
  final DateTime periodStart;
  final int progress;
  final String? proposedByCoachName;
  final GoalStatus status;

  const Goal({
    required this.id,
    required this.metric,
    required this.target,
    required this.period,
    required this.periodStart,
    this.progress = 0,
    this.proposedByCoachName,
    this.status = GoalStatus.accepted,
  });

  /// DS: "pace ring + on/off-track chip." No exact pace formula given --
  /// linear expected-progress-by-elapsed-time-fraction is a flagged
  /// judgment call.
  double expectedProgressFraction({DateTime Function() now = DateTime.now}) {
    final duration = goalPeriodDurations[period]!;
    final elapsed = now().difference(periodStart);
    if (elapsed.isNegative) return 0;
    return (elapsed.inMinutes / duration.inMinutes).clamp(0.0, 1.0);
  }

  double get progressFraction =>
      target == 0 ? 0 : (progress / target).clamp(0.0, 1.0);

  bool onTrack({DateTime Function() now = DateTime.now}) =>
      progressFraction >= expectedProgressFraction(now: now);

  Goal copyWith({int? progress, GoalStatus? status}) {
    return Goal(
      id: id,
      metric: metric,
      target: target,
      period: period,
      periodStart: periodStart,
      progress: progress ?? this.progress,
      proposedByCoachName: proposedByCoachName,
      status: status ?? this.status,
    );
  }
}
