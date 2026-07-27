import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_arc_ring.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'knowledge_hub_models.dart';
import 'knowledge_hub_provider.dart';
import 'officials_console_models.dart' show credentialTierLabels;

/// DS §11.11 (Knowledge Hub). See knowledge_hub_models.dart's top-of-file
/// note for the "G.5" citation gap -- this DS section is the only real
/// spec for the whole feature.
class KnowledgeHubScreen extends ConsumerWidget {
  const KnowledgeHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final notifier = ref.read(knowledgeHubProvider.notifier);
    final state = ref.watch(knowledgeHubProvider);

    Widget sectionLabel(String text) => Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm,
        top: AppSpacing.xxl,
      ),
      child: Text(
        text,
        style: AppTypography.label.copyWith(color: colors.textTertiary),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Knowledge hub')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          sectionLabel('Daily trivia'),
          if (state.triviaCompletedToday)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department, color: colors.coin),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Completed today -- ${state.triviaCorrectToday}/'
                      '${notifier.dailyTrivia.length} correct. '
                      '${state.streakDays}-day streak.',
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            _DailyTriviaCard(streakDays: state.streakDays),
          sectionLabel('Quiz packs'),
          for (final pack in notifier.quizPacks)
            Card(
              key: ValueKey('quizPackCard_${pack.id}'),
              child: ListTile(
                title: Text(pack.title),
                subtitle: Text('${pack.questions.length} questions'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _QuizPackScreen(pack: pack),
                  ),
                ),
              ),
            ),
          sectionLabel('Certification tracks'),
          for (final track in notifier.certificationTracks)
            Card(
              key: ValueKey('certificationTrackCard_${track.id}'),
              child: ListTile(
                title: Text(track.title),
                subtitle: Text(
                  '${track.versionLabel} -- pass mark ${track.passMarkPercent}% '
                  '-- requires ${credentialTierLabels[track.requiredTier]} tier',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CertificationSyllabusScreen(track: track),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DailyTriviaCard extends ConsumerStatefulWidget {
  final int streakDays;

  const _DailyTriviaCard({required this.streakDays});

  @override
  ConsumerState<_DailyTriviaCard> createState() => _DailyTriviaCardState();
}

class _DailyTriviaCardState extends ConsumerState<_DailyTriviaCard> {
  static const _secondsPerQuestion = 20;
  Timer? _timer;
  int _remaining = _secondsPerQuestion;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _remaining = _secondsPerQuestion;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        _answer(null);
      }
    });
  }

  void _answer(int? selected) {
    final notifier = ref.read(knowledgeHubProvider.notifier);
    final index = ref.read(knowledgeHubProvider).triviaQuestionIndex;
    final question = notifier.dailyTrivia[index];
    notifier.answerTrivia(selected == question.correctIndex);
    if (mounted && !ref.read(knowledgeHubProvider).triviaCompletedToday) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final notifier = ref.read(knowledgeHubProvider.notifier);
    final index = ref.watch(
      knowledgeHubProvider.select((s) => s.triviaQuestionIndex),
    );
    if (index >= notifier.dailyTrivia.length) return const SizedBox.shrink();
    final question = notifier.dailyTrivia[index];

    return Container(
      key: const ValueKey('dailyTriviaCard'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppArcRing(
                progress: _remaining / _secondsPerQuestion,
                size: 32,
                strokeWidth: 3,
                trackColor: colors.divider,
                fillColor: colors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Question ${index + 1}/${notifier.dailyTrivia.length}',
                style: AppTypography.label.copyWith(color: colors.textTertiary),
              ),
              const Spacer(),
              Chip(label: Text('🔥 ${widget.streakDays}')),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            question.question,
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < question.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: OutlinedButton(
                key: ValueKey('triviaOption_${index}_$i'),
                onPressed: () => _answer(i),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(question.options[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuizPackScreen extends StatefulWidget {
  final QuizPack pack;

  const _QuizPackScreen({required this.pack});

  @override
  State<_QuizPackScreen> createState() => _QuizPackScreenState();
}

class _QuizPackScreenState extends State<_QuizPackScreen> {
  int _index = 0;
  int _correct = 0;

  void _answer(int selected) {
    final q = widget.pack.questions[_index];
    setState(() {
      if (selected == q.correctIndex) _correct++;
      _index++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final done = _index >= widget.pack.questions.length;

    return Scaffold(
      appBar: AppBar(title: Text(widget.pack.title)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: done
            ? Center(
                child: Text(
                  'Score: $_correct/${widget.pack.questions.length}',
                  style: AppTypography.title.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.pack.questions[_index].question,
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (
                    var i = 0;
                    i < widget.pack.questions[_index].options.length;
                    i++
                  )
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: OutlinedButton(
                        onPressed: () => _answer(i),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(widget.pack.questions[_index].options[i]),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class CertificationSyllabusScreen extends ConsumerWidget {
  final CertificationTrack track;

  const CertificationSyllabusScreen({super.key, required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final notifier = ref.read(knowledgeHubProvider.notifier);
    final attemptsLeft = notifier.attemptsLeftFor(track);
    final eligible = notifier.isTierEligible(track);

    return Scaffold(
      appBar: AppBar(title: Text(track.title)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(label: Text(track.versionLabel)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Pass mark: ${track.passMarkPercent}%',
              style: AppTypography.body.copyWith(color: colors.textPrimary),
            ),
            Text(
              'Attempts left: $attemptsLeft/${track.maxAttempts}',
              style: AppTypography.body.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (!eligible)
              Text(
                'Requires ${credentialTierLabels[track.requiredTier]} tier '
                'on the Officials Console to attempt this exam.',
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              )
            else if (attemptsLeft <= 0)
              Text(
                'No attempts remaining.',
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              )
            else
              FilledButton(
                key: const ValueKey('startExamButton'),
                onPressed: () {
                  notifier.startExam(track.id);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => CertificationExamScreen(track: track),
                    ),
                  );
                },
                child: const Text('Start exam'),
              ),
          ],
        ),
      ),
    );
  }
}

/// DS §11.11: "exam mode: distraction-reduced layout (no nav bar)."
class CertificationExamScreen extends ConsumerWidget {
  final CertificationTrack track;

  const CertificationExamScreen({super.key, required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final notifier = ref.read(knowledgeHubProvider.notifier);
    final exam = ref.watch(
      knowledgeHubProvider.select((s) => s.examInProgress),
    );
    if (exam == null) return const SizedBox.shrink();

    final question = track.questions[exam.currentIndex];
    final isLast = exam.currentIndex == track.questions.length - 1;
    final flagged = exam.flaggedForReview.contains(exam.currentIndex);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppArcRing(
                    key: const ValueKey('examQuestionCounterArc'),
                    progress: (exam.currentIndex + 1) / track.questions.length,
                    size: 36,
                    strokeWidth: 3,
                    trackColor: colors.divider,
                    fillColor: colors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Question ${exam.currentIndex + 1}/${track.questions.length}',
                    style: AppTypography.label.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    key: const ValueKey('flagForReviewButton'),
                    icon: Icon(
                      flagged ? Icons.flag : Icons.flag_outlined,
                      color: flagged ? colors.warning : colors.textTertiary,
                    ),
                    onPressed: () =>
                        notifier.toggleFlagForReview(exam.currentIndex),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                question.question,
                style: AppTypography.title.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < question.options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: OutlinedButton(
                    key: ValueKey('examOption_${exam.currentIndex}_$i'),
                    onPressed: () =>
                        notifier.answerExamQuestion(exam.currentIndex, i),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: exam.answers[exam.currentIndex] == i
                          ? colors.surfaceAlt
                          : null,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(question.options[i]),
                    ),
                  ),
                ),
              const Spacer(),
              Row(
                children: [
                  if (exam.currentIndex > 0)
                    TextButton(
                      onPressed: () =>
                          notifier.goToQuestion(exam.currentIndex - 1),
                      child: const Text('Previous'),
                    ),
                  const Spacer(),
                  FilledButton(
                    key: const ValueKey('examNextOrSubmitButton'),
                    onPressed: () {
                      if (isLast) {
                        _confirmSubmit(context, ref);
                      } else {
                        notifier.goToQuestion(exam.currentIndex + 1);
                      }
                    },
                    child: Text(isLast ? 'Submit' : 'Next'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSubmit(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit exam?'),
        content: const Text('You cannot change your answers after submitting.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('confirmSubmitExamButton'),
            onPressed: () {
              final result = ref
                  .read(knowledgeHubProvider.notifier)
                  .submitExam(track);
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) =>
                      CertificationResultScreen(track: track, result: result),
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class CertificationResultScreen extends StatelessWidget {
  final CertificationTrack track;
  final ExamAttemptResult result;

  const CertificationResultScreen({
    super.key,
    required this.track,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(title: Text(track.title)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.passed) ...[
              Icon(Icons.verified, size: 56, color: colors.verified),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Certified! ${result.scorePercent.toStringAsFixed(0)}%',
                style: AppTypography.title.copyWith(color: colors.textPrimary),
              ),
              Text(
                'Certificate minted -- renders on Officials Console and '
                'your profile credentials row.',
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              ),
            ] else ...[
              Text(
                'Not passed -- ${result.scorePercent.toStringAsFixed(0)}% '
                '(need ${track.passMarkPercent}%)',
                style: AppTypography.title.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Section feedback',
                style: AppTypography.label.copyWith(color: colors.textTertiary),
              ),
              for (final entry in result.sectionScores.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(child: Text(entry.key)),
                      Text('${entry.value.toStringAsFixed(0)}%'),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Next attempt available '
                '${result.nextAttemptDate.toLocal().toString().split(' ').first}.',
                style: AppTypography.caption.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
