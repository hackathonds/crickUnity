/// DS §11.11 (Knowledge Hub, ⊕ Discover): "Hub home: Daily-trivia card
/// (3-question inline flow, per-question 20s soft timer ring, streak
/// chip) -> quiz-pack shelf -> certification tracks. Certification
/// exam: syllabus screen (version chip, pass mark, attempts left) ->
/// exam mode: distraction-reduced layout (no nav bar), question counter
/// Arc, flag-for-review, submit-confirm dialog -> result screen: pass =
/// certificate ceremony (restrained Theme-2 styling) + profile card
/// mint; fail = section-wise feedback + next-attempt date. Certificates
/// render on Officials Console and profile credentials row."
///
/// Backlog cites this story against "G.5" -- no Appendix G exists
/// anywhere in the frozen PRD (only A and B are real, established
/// earlier this session), and a full-text search of the PRD for
/// trivia/quiz/certification-exam returns nothing at all. Like E14-04's
/// Commentator room, this DS section is the *only* real spec for the
/// entire feature -- everything here is built strictly from it.
/// "Certificate mint gating Silver tier" reuses E14-02's real
/// [CredentialTier] enum rather than inventing a second tier system.
library;

import 'officials_console_models.dart' show CredentialTier;

class TriviaQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  const TriviaQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

class QuizPack {
  final String id;
  final String title;
  final List<TriviaQuestion> questions;

  const QuizPack({
    required this.id,
    required this.title,
    required this.questions,
  });
}

class ExamQuestion {
  final String sectionLabel;
  final String question;
  final List<String> options;
  final int correctIndex;

  const ExamQuestion({
    required this.sectionLabel,
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

class CertificationTrack {
  final String id;
  final String title;
  final String versionLabel;
  final int passMarkPercent;
  final int maxAttempts;
  final CredentialTier requiredTier;
  final List<ExamQuestion> questions;

  const CertificationTrack({
    required this.id,
    required this.title,
    required this.versionLabel,
    required this.passMarkPercent,
    required this.maxAttempts,
    required this.requiredTier,
    required this.questions,
  });
}

class ExamAttemptResult {
  final String trackId;
  final int attemptNumber;
  final double scorePercent;
  final bool passed;
  final Map<String, double> sectionScores;
  final DateTime takenAt;

  const ExamAttemptResult({
    required this.trackId,
    required this.attemptNumber,
    required this.scorePercent,
    required this.passed,
    required this.sectionScores,
    required this.takenAt,
  });

  DateTime get nextAttemptDate => takenAt.add(const Duration(days: 7));

  Map<String, dynamic> toJson() => {
    'trackId': trackId,
    'attemptNumber': attemptNumber,
    'scorePercent': scorePercent,
    'passed': passed,
    'sectionScores': sectionScores,
    'takenAt': takenAt.toIso8601String(),
  };

  factory ExamAttemptResult.fromJson(Map<String, dynamic> json) {
    return ExamAttemptResult(
      trackId: json['trackId'] as String,
      attemptNumber: json['attemptNumber'] as int,
      scorePercent: (json['scorePercent'] as num).toDouble(),
      passed: json['passed'] as bool,
      sectionScores: {
        for (final entry
            in (json['sectionScores'] as Map<String, dynamic>).entries)
          entry.key: (entry.value as num).toDouble(),
      },
      takenAt: DateTime.parse(json['takenAt'] as String),
    );
  }
}
