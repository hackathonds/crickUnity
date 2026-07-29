import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../academies/academy_provider.dart';
import '../persistence/persisted_notifier.dart';
import 'coach_models.dart';

class CoachState {
  final List<Drill> drills;
  final List<TemplateSession> templates;
  final List<AssignedSession> assignedSessions;
  final List<DrillPersonalBest> personalBests;
  final List<ProgressCard> progressCards;

  const CoachState({
    this.drills = const [],
    this.templates = const [],
    this.assignedSessions = const [],
    this.personalBests = const [],
    this.progressCards = const [],
  });

  CoachState copyWith({
    List<Drill>? drills,
    List<TemplateSession>? templates,
    List<AssignedSession>? assignedSessions,
    List<DrillPersonalBest>? personalBests,
    List<ProgressCard>? progressCards,
  }) {
    return CoachState(
      drills: drills ?? this.drills,
      templates: templates ?? this.templates,
      assignedSessions: assignedSessions ?? this.assignedSessions,
      personalBests: personalBests ?? this.personalBests,
      progressCards: progressCards ?? this.progressCards,
    );
  }

  List<AssignedSession> sessionsThisWeekFor(String studentName, DateTime now) {
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    return assignedSessions
        .where(
          (s) =>
              s.studentName == studentName &&
              !s.date.isBefore(weekStart) &&
              s.date.isBefore(weekEnd),
        )
        .toList();
  }

  List<DrillPersonalBest> personalBestsFor(
    String studentName,
    String drillId,
  ) =>
      personalBests
          .where((p) => p.studentName == studentName && p.drillId == drillId)
          .toList()
        ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

  /// Only the mutated collections persist -- [drills]/[templates] are
  /// a static library no method ever mutates, re-seeded fresh on load.
  Map<String, dynamic> toJson() => {
    'assignedSessions': [for (final s in assignedSessions) s.toJson()],
    'personalBests': [for (final p in personalBests) p.toJson()],
    'progressCards': [for (final c in progressCards) c.toJson()],
  };
}

/// Backlog E11-03 -- Coach console + drill library + homework engine.
/// See coach_models.dart's top-of-file note for the exact DS §7-46
/// quote and the flagged phantom "Appx E" citation.
class CoachNotifier extends PersistedNotifier<CoachState> {
  @override
  String get persistenceKey => 'coach_v1';

  @override
  Map<String, dynamic> toJson(CoachState value) => value.toJson();

  @override
  CoachState fromJson(Map<String, dynamic> json) {
    final base = seed();
    return base.copyWith(
      assignedSessions: [
        for (final s in json['assignedSessions'] as List)
          AssignedSession.fromJson(s as Map<String, dynamic>),
      ],
      personalBests: [
        for (final p in json['personalBests'] as List)
          DrillPersonalBest.fromJson(p as Map<String, dynamic>),
      ],
      progressCards: [
        for (final c in json['progressCards'] as List)
          ProgressCard.fromJson(c as Map<String, dynamic>),
      ],
    );
  }

  @override
  CoachState seed() => CoachState(
    drills: const [
      Drill(
        id: 'drill-cover-drive',
        name: 'Cover drive repetitions',
        category: DrillCategory.batting,
        baseSets: 4,
        baseReps: 15,
      ),
      Drill(
        id: 'drill-yorker',
        name: 'Yorker accuracy',
        category: DrillCategory.bowling,
        baseSets: 3,
        baseReps: 12,
      ),
      Drill(
        id: 'drill-slip-catching',
        name: 'Slip catching',
        category: DrillCategory.fielding,
        baseSets: 3,
        baseReps: 20,
      ),
    ],
    templates: const [
      TemplateSession(
        id: 'template-batting-basics',
        name: 'Batting basics',
        drillIds: ['drill-cover-drive'],
      ),
      TemplateSession(
        id: 'template-all-round',
        name: 'All-round session',
        drillIds: ['drill-cover-drive', 'drill-yorker', 'drill-slip-catching'],
      ),
    ],
  );

  /// DS §7-46: "session planner (template picker grid from Drill
  /// Library, drill cards showing prescription)." Backlog: "workload
  /// caps." Returns null on success, or a rejection message.
  String? assignSession(
    String studentName,
    String templateId,
    DateTime date, {
    DateTime Function() now = DateTime.now,
  }) {
    final sessionsThisWeek = sessionsThisWeekFor(studentName, now());
    if (sessionsThisWeek.length >= maxSessionsPerWeek) {
      return '$studentName has already reached the $maxSessionsPerWeek session/week workload cap.';
    }
    state = state.copyWith(
      assignedSessions: [
        ...state.assignedSessions,
        AssignedSession(
          id: 'session-${now().microsecondsSinceEpoch}',
          studentName: studentName,
          templateId: templateId,
          date: date,
        ),
      ],
    );
    return null;
  }

  List<AssignedSession> sessionsThisWeekFor(String studentName, DateTime now) =>
      state.sessionsThisWeekFor(studentName, now);

  /// Backlog: "drill PB graphs."
  void recordPersonalBest(
    String studentName,
    String drillId,
    int value, {
    DateTime Function() now = DateTime.now,
  }) {
    state = state.copyWith(
      personalBests: [
        ...state.personalBests,
        DrillPersonalBest(
          studentName: studentName,
          drillId: drillId,
          value: value,
          recordedAt: now(),
        ),
      ],
    );
  }

  /// DS §7-46: "progress-card composer (approve -> send)."
  /// Backlog addendum (PRD §2.8): "progress notes for minors visible
  /// to guardian account." Reads the real academyProvider Student
  /// record to determine minor status, not a re-declared flag.
  void composeProgressCard(
    String studentName,
    String monthLabel,
    String notes, {
    DateTime Function() now = DateTime.now,
  }) {
    final student = ref
        .read(academyProvider)
        .students
        .where((s) => s.name == studentName)
        .firstOrNull;
    state = state.copyWith(
      progressCards: [
        ...state.progressCards,
        ProgressCard(
          id: 'progress-${now().microsecondsSinceEpoch}',
          studentName: studentName,
          monthLabel: monthLabel,
          notes: notes,
          visibleToGuardian: student?.isMinor ?? false,
        ),
      ],
    );
  }

  void approveAndSend(String cardId, {DateTime Function() now = DateTime.now}) {
    state = state.copyWith(
      progressCards: [
        for (final c in state.progressCards)
          if (c.id == cardId) c.copyWith(approved: true, sentAt: now()) else c,
      ],
    );
  }
}

final coachProvider = NotifierProvider<CoachNotifier, CoachState>(
  CoachNotifier.new,
);
