import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../coaching/compliance_provider.dart';
import '../persistence/persisted_notifier.dart';
import 'academy_models.dart';

class AcademyState {
  final List<Batch> batches;
  final List<Student> students;
  final List<FeeLedgerEntry> feeLedger;
  final List<Trial> trials;

  const AcademyState({
    this.batches = const [],
    this.students = const [],
    this.feeLedger = const [],
    this.trials = const [],
  });

  AcademyState copyWith({
    List<Batch>? batches,
    List<Student>? students,
    List<FeeLedgerEntry>? feeLedger,
    List<Trial>? trials,
  }) {
    return AcademyState(
      batches: batches ?? this.batches,
      students: students ?? this.students,
      feeLedger: feeLedger ?? this.feeLedger,
      trials: trials ?? this.trials,
    );
  }

  List<Student> studentsFor(String batchId) =>
      students.where((s) => s.batchId == batchId).toList();

  List<FeeLedgerEntry> ledgerFor(String studentId) =>
      feeLedger.where((f) => f.studentId == studentId).toList();

  List<Student> get talentShowcaseStudents =>
      students.where((s) => s.talentShowcaseOptIn).toList();

  Map<String, dynamic> toJson() => {
    'batches': [for (final b in batches) b.toJson()],
    'students': [for (final s in students) s.toJson()],
    'feeLedger': [for (final f in feeLedger) f.toJson()],
    'trials': [for (final t in trials) t.toJson()],
  };

  factory AcademyState.fromJson(Map<String, dynamic> json) {
    return AcademyState(
      batches: [
        for (final b in json['batches'] as List)
          Batch.fromJson(b as Map<String, dynamic>),
      ],
      students: [
        for (final s in json['students'] as List)
          Student.fromJson(s as Map<String, dynamic>),
      ],
      feeLedger: [
        for (final f in json['feeLedger'] as List)
          FeeLedgerEntry.fromJson(f as Map<String, dynamic>),
      ],
      trials: [
        for (final t in json['trials'] as List)
          Trial.fromJson(t as Map<String, dynamic>),
      ],
    );
  }
}

/// Backlog E11-02 -- Academy console engine. See academy_models.dart's
/// top-of-file note for the exact PRD §2.10 quote this implements.
class AcademyNotifier extends PersistedNotifier<AcademyState> {
  @override
  String get persistenceKey => 'academy_v1';

  @override
  Map<String, dynamic> toJson(AcademyState value) => value.toJson();

  @override
  AcademyState fromJson(Map<String, dynamic> json) =>
      AcademyState.fromJson(json);

  @override
  AcademyState seed() => AcademyState(
    batches: const [
      Batch(
        id: 'batch-u16',
        name: 'U-16 Batch',
        ageGroup: 'Under 16',
        scheduleNote: 'Mon/Wed/Fri 6-8 AM',
        feeAmount: 1500,
        coachName: 'Coach Ramesh',
      ),
    ],
  );

  void createBatch(
    String name,
    String ageGroup,
    String scheduleNote,
    int feeAmount, {
    DateTime Function() now = DateTime.now,
  }) {
    state = state.copyWith(
      batches: [
        ...state.batches,
        Batch(
          id: 'batch-${now().microsecondsSinceEpoch}',
          name: name,
          ageGroup: ageGroup,
          scheduleNote: scheduleNote,
          feeAmount: feeAmount,
        ),
      ],
    );
  }

  /// Backlog E11-04: "signed-status matrix blocking registration."
  /// Returns null on success, or a rejection message if the coach's
  /// compliance vault (certifications, first-aid, background check)
  /// isn't fully signed and unexpired.
  String? assignCoach(
    String batchId,
    String coachName, {
    DateTime Function() now = DateTime.now,
  }) {
    if (!ref.read(complianceProvider).isCoachCompliant(coachName, now())) {
      return '$coachName cannot be assigned -- compliance vault has a missing, unsigned, or expired document.';
    }
    state = state.copyWith(
      batches: [
        for (final b in state.batches)
          if (b.id == batchId) b.copyWith(coachName: coachName) else b,
      ],
    );
    return null;
  }

  /// PRD: "enroll students (guardian consent flow for minors)."
  /// Returns null on success, or a rejection message.
  String? enrollStudent({
    required String name,
    required bool isMinor,
    String? guardianName,
    bool guardianConsentGiven = false,
    required String batchId,
    DateTime Function() now = DateTime.now,
  }) {
    if (isMinor && !guardianConsentGiven) {
      return 'Guardian consent is required to enroll a minor.';
    }
    final student = Student(
      id: 'student-${now().microsecondsSinceEpoch}',
      name: name,
      isMinor: isMinor,
      guardianName: guardianName,
      guardianConsentGiven: guardianConsentGiven,
      batchId: batchId,
    );
    final batch = state.batches.where((b) => b.id == batchId).firstOrNull;
    state = state.copyWith(
      students: [...state.students, student],
      feeLedger: batch == null
          ? state.feeLedger
          : [
              ...state.feeLedger,
              FeeLedgerEntry(
                id: 'fee-${now().microsecondsSinceEpoch}',
                studentId: student.id,
                monthLabel: _monthLabel(now()),
                amount: batch.feeAmount,
                dueDate: now().add(const Duration(days: 7)),
              ),
            ],
    );
    return null;
  }

  static String _monthLabel(DateTime date) => '${date.month}/${date.year}';

  void markFeePaid(String feeEntryId) {
    state = state.copyWith(
      feeLedger: [
        for (final f in state.feeLedger)
          if (f.id == feeEntryId) f.copyWith(paid: true) else f,
      ],
    );
  }

  /// PRD: "publish trials/events."
  void publishTrial(
    String name,
    String ageGroup,
    DateTime date, {
    DateTime Function() now = DateTime.now,
  }) {
    state = state.copyWith(
      trials: [
        ...state.trials,
        Trial(
          id: 'trial-${now().microsecondsSinceEpoch}',
          name: name,
          ageGroup: ageGroup,
          date: date,
        ),
      ],
    );
  }

  void registerForTrial(String trialId) {
    state = state.copyWith(
      trials: [
        for (final t in state.trials)
          if (t.id == trialId)
            t.copyWith(registrationsCount: t.registrationsCount + 1)
          else
            t,
      ],
    );
  }

  /// PRD: "talent showcase board visible to Team Owners/Organizers
  /// (student opt-in)."
  void toggleTalentShowcaseOptIn(String studentId) {
    state = state.copyWith(
      students: [
        for (final s in state.students)
          if (s.id == studentId)
            s.copyWith(talentShowcaseOptIn: !s.talentShowcaseOptIn)
          else
            s,
      ],
    );
  }

  /// Backlog addendum (PRD §2.8): "player consent toggle, default ON
  /// for academy students, OFF for adult team attachments."
  void toggleAnalyticsConsent(String studentId) {
    state = state.copyWith(
      students: [
        for (final s in state.students)
          if (s.id == studentId)
            s.copyWith(analyticsConsentEnabled: !s.analyticsConsentEnabled)
          else
            s,
      ],
    );
  }
}

final academyProvider = NotifierProvider<AcademyNotifier, AcademyState>(
  AcademyNotifier.new,
);
