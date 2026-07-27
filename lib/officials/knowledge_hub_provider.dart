import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'knowledge_hub_models.dart';
import 'officials_console_models.dart' show CredentialTier, currentTier;
import 'officials_console_provider.dart';

const List<TriviaQuestion> _dailyTrivia = [
  TriviaQuestion(
    question: 'How many players are on a cricket team?',
    options: ['9', '10', '11', '12'],
    correctIndex: 2,
  ),
  TriviaQuestion(
    question: 'What is it called when a bowler takes 3 wickets in an over?',
    options: ['Hat-trick', 'Golden over', 'Maiden', 'Triple strike'],
    correctIndex: 0,
  ),
  TriviaQuestion(
    question: 'How many runs is a "six"?',
    options: ['4', '5', '6', '8'],
    correctIndex: 2,
  ),
];

final List<QuizPack> _quizPacks = [
  QuizPack(
    id: 'pack-laws',
    title: 'Laws of Cricket basics',
    questions: _dailyTrivia,
  ),
];

final List<CertificationTrack> _certificationTracks = [
  CertificationTrack(
    id: 'cert-scorer-1',
    title: 'Certified Scorer -- Level 1',
    versionLabel: 'v2.1',
    passMarkPercent: 70,
    maxAttempts: 3,
    requiredTier: CredentialTier.silver,
    questions: const [
      ExamQuestion(
        sectionLabel: 'Scoring basics',
        question: 'What does "lbw" stand for?',
        options: [
          'Leg before wicket',
          'Last ball wicket',
          'Late batting warning',
          'Line ball wide',
        ],
        correctIndex: 0,
      ),
      ExamQuestion(
        sectionLabel: 'Scoring basics',
        question: 'A no-ball that is also hit for four scores how many runs?',
        options: ['4', '5', '6', '1'],
        correctIndex: 1,
      ),
      ExamQuestion(
        sectionLabel: 'Extras',
        question: 'Which extra is credited to the batter\'s individual score?',
        options: ['Wide', 'Bye', 'Leg bye', 'None of these'],
        correctIndex: 3,
      ),
      ExamQuestion(
        sectionLabel: 'Extras',
        question: 'Does a wide count as a legal delivery in the over?',
        options: ['Yes', 'No'],
        correctIndex: 1,
      ),
    ],
  ),
];

class ExamInProgress {
  final String trackId;
  final int currentIndex;
  final Map<int, int> answers;
  final Set<int> flaggedForReview;

  const ExamInProgress({
    required this.trackId,
    this.currentIndex = 0,
    this.answers = const {},
    this.flaggedForReview = const {},
  });

  ExamInProgress copyWith({
    int? currentIndex,
    Map<int, int>? answers,
    Set<int>? flaggedForReview,
  }) {
    return ExamInProgress(
      trackId: trackId,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      flaggedForReview: flaggedForReview ?? this.flaggedForReview,
    );
  }
}

class KnowledgeHubState {
  final int triviaQuestionIndex;
  final int triviaCorrectToday;
  final bool triviaCompletedToday;
  final int streakDays;
  final Map<String, int> attemptsUsed;
  final List<ExamAttemptResult> attemptResults;
  final Set<String> mintedCertificateIds;
  final ExamInProgress? examInProgress;

  const KnowledgeHubState({
    this.triviaQuestionIndex = 0,
    this.triviaCorrectToday = 0,
    this.triviaCompletedToday = false,
    this.streakDays = 4,
    this.attemptsUsed = const {},
    this.attemptResults = const [],
    this.mintedCertificateIds = const {},
    this.examInProgress,
  });

  KnowledgeHubState copyWith({
    int? triviaQuestionIndex,
    int? triviaCorrectToday,
    bool? triviaCompletedToday,
    int? streakDays,
    Map<String, int>? attemptsUsed,
    List<ExamAttemptResult>? attemptResults,
    Set<String>? mintedCertificateIds,
    ExamInProgress? examInProgress,
    bool clearExam = false,
  }) {
    return KnowledgeHubState(
      triviaQuestionIndex: triviaQuestionIndex ?? this.triviaQuestionIndex,
      triviaCorrectToday: triviaCorrectToday ?? this.triviaCorrectToday,
      triviaCompletedToday: triviaCompletedToday ?? this.triviaCompletedToday,
      streakDays: streakDays ?? this.streakDays,
      attemptsUsed: attemptsUsed ?? this.attemptsUsed,
      attemptResults: attemptResults ?? this.attemptResults,
      mintedCertificateIds: mintedCertificateIds ?? this.mintedCertificateIds,
      examInProgress: clearExam
          ? null
          : (examInProgress ?? this.examInProgress),
    );
  }
}

/// No real trivia-content/exam-authoring backend exists -- flagged mock
/// question banks, same convention as every other missing-backend gap
/// this session.
class KnowledgeHubNotifier extends Notifier<KnowledgeHubState> {
  @override
  KnowledgeHubState build() => const KnowledgeHubState();

  List<TriviaQuestion> get dailyTrivia => _dailyTrivia;
  List<QuizPack> get quizPacks => _quizPacks;
  List<CertificationTrack> get certificationTracks => _certificationTracks;

  void answerTrivia(bool correct) {
    final nextIndex = state.triviaQuestionIndex + 1;
    final completed = nextIndex >= _dailyTrivia.length;
    state = state.copyWith(
      triviaQuestionIndex: nextIndex,
      triviaCorrectToday: state.triviaCorrectToday + (correct ? 1 : 0),
      triviaCompletedToday: completed,
      streakDays: completed ? state.streakDays + 1 : state.streakDays,
    );
  }

  int attemptsLeftFor(CertificationTrack track) {
    return track.maxAttempts - (state.attemptsUsed[track.id] ?? 0);
  }

  bool isTierEligible(CertificationTrack track) {
    final disputeFreeMatches = ref
        .read(officialsConsoleProvider)
        .disputeFreeMatches;
    final tier = currentTier(disputeFreeMatches);
    if (tier == null) return false;
    return tier.index >= track.requiredTier.index;
  }

  void startExam(String trackId) {
    state = state.copyWith(examInProgress: ExamInProgress(trackId: trackId));
  }

  void answerExamQuestion(int questionIndex, int optionIndex) {
    final exam = state.examInProgress;
    if (exam == null) return;
    state = state.copyWith(
      examInProgress: exam.copyWith(
        answers: {...exam.answers, questionIndex: optionIndex},
      ),
    );
  }

  void toggleFlagForReview(int questionIndex) {
    final exam = state.examInProgress;
    if (exam == null) return;
    final flagged = {...exam.flaggedForReview};
    flagged.contains(questionIndex)
        ? flagged.remove(questionIndex)
        : flagged.add(questionIndex);
    state = state.copyWith(
      examInProgress: exam.copyWith(flaggedForReview: flagged),
    );
  }

  void goToQuestion(int index) {
    final exam = state.examInProgress;
    if (exam == null) return;
    state = state.copyWith(examInProgress: exam.copyWith(currentIndex: index));
  }

  ExamAttemptResult submitExam(CertificationTrack track) {
    final exam = state.examInProgress!;
    final bySection = <String, List<bool>>{};
    for (var i = 0; i < track.questions.length; i++) {
      final q = track.questions[i];
      final correct = exam.answers[i] == q.correctIndex;
      bySection.putIfAbsent(q.sectionLabel, () => []).add(correct);
    }
    final totalCorrect = bySection.values.fold(
      0,
      (a, l) => a + l.where((c) => c).length,
    );
    final scorePercent = 100 * totalCorrect / track.questions.length;
    final passed = scorePercent >= track.passMarkPercent;
    final attemptNumber = (state.attemptsUsed[track.id] ?? 0) + 1;

    final result = ExamAttemptResult(
      trackId: track.id,
      attemptNumber: attemptNumber,
      scorePercent: scorePercent,
      passed: passed,
      sectionScores: {
        for (final entry in bySection.entries)
          entry.key:
              100 * entry.value.where((c) => c).length / entry.value.length,
      },
      takenAt: DateTime.now(),
    );

    state = state.copyWith(
      attemptsUsed: {...state.attemptsUsed, track.id: attemptNumber},
      attemptResults: [result, ...state.attemptResults],
      mintedCertificateIds: passed
          ? {...state.mintedCertificateIds, track.id}
          : state.mintedCertificateIds,
      clearExam: true,
    );
    return result;
  }
}

final knowledgeHubProvider =
    NotifierProvider<KnowledgeHubNotifier, KnowledgeHubState>(
      KnowledgeHubNotifier.new,
    );
