import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/persisted_notifier.dart';
import 'goal_models.dart';
import 'leaderboard_models.dart';

class GoalsState {
  final List<Goal> goals;

  const GoalsState({this.goals = const []});

  GoalsState copyWith({List<Goal>? goals}) =>
      GoalsState(goals: goals ?? this.goals);

  Map<String, dynamic> toJson() => {
    'goals': [for (final g in goals) g.toJson()],
  };

  factory GoalsState.fromJson(Map<String, dynamic> json) {
    return GoalsState(
      goals: [
        for (final g in json['goals'] as List)
          Goal.fromJson(g as Map<String, dynamic>),
      ],
    );
  }
}

/// DS §11.15 -- E8-05's Goals engine.
class GoalsNotifier extends PersistedNotifier<GoalsState> {
  @override
  String get persistenceKey => 'goals_v1';

  @override
  GoalsState seed() => GoalsState(goals: _seedGoals());

  @override
  Map<String, dynamic> toJson(GoalsState value) => value.toJson();

  @override
  GoalsState fromJson(Map<String, dynamic> json) => GoalsState.fromJson(json);

  static List<Goal> _seedGoals() {
    final now = DateTime.now();
    return [
      Goal(
        id: 'goal-1',
        metric: LeaderboardMetric.runs,
        target: 300,
        period: GoalPeriod.month,
        periodStart: now.subtract(const Duration(days: 10)),
        progress: 120,
      ),
      // "Coach-proposed goals arrive as accept/decline cards."
      Goal(
        id: 'goal-coach-1',
        metric: LeaderboardMetric.wickets,
        target: 15,
        period: GoalPeriod.season,
        periodStart: now,
        proposedByCoachName: 'Coach Ramesh',
        status: GoalStatus.pending,
      ),
    ];
  }

  void createGoal({
    required LeaderboardMetric metric,
    required int target,
    required GoalPeriod period,
    DateTime Function() now = DateTime.now,
  }) {
    state = state.copyWith(
      goals: [
        ...state.goals,
        Goal(
          id: 'goal-${now().microsecondsSinceEpoch}',
          metric: metric,
          target: target,
          period: period,
          periodStart: now(),
        ),
      ],
    );
  }

  void recordProgress(String goalId, int amount) {
    _update(goalId, (g) => g.copyWith(progress: g.progress + amount));
  }

  void acceptCoachGoal(
    String goalId, {
    DateTime Function() now = DateTime.now,
  }) {
    _update(
      goalId,
      (g) => Goal(
        id: g.id,
        metric: g.metric,
        target: g.target,
        period: g.period,
        periodStart: now(),
        progress: g.progress,
        proposedByCoachName: g.proposedByCoachName,
        status: GoalStatus.accepted,
      ),
    );
  }

  void declineCoachGoal(String goalId) {
    _update(goalId, (g) => g.copyWith(status: GoalStatus.declined));
  }

  void _update(String goalId, Goal Function(Goal) transform) {
    state = state.copyWith(
      goals: [
        for (final g in state.goals)
          if (g.id == goalId) transform(g) else g,
      ],
    );
  }
}

final goalsProvider = NotifierProvider<GoalsNotifier, GoalsState>(
  GoalsNotifier.new,
);
