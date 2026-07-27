import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'sandbox_tutorial_models.dart';
import 'sandbox_tutorial_provider.dart';

/// DS §11.18: "Sandbox tutorial: first scoring-console open offers
/// 'Practice with a sample match' -- console loads with SANDBOX
/// watermark chip and coach-mark sequence per control; exit anytime;
/// zero stat/XP writes (explicit banner)." See
/// sandbox_tutorial_models.dart's top-of-file note on why this is a
/// standalone practice surface rather than the real console in a
/// sandbox mode.
class SandboxEntryPoint extends ConsumerStatefulWidget {
  const SandboxEntryPoint({super.key});

  @override
  ConsumerState<SandboxEntryPoint> createState() => _SandboxEntryPointState();
}

class _SandboxEntryPointState extends ConsumerState<SandboxEntryPoint> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOffer());
  }

  void _maybeOffer() {
    if (ref.read(sandboxTutorialProvider).hasBeenOffered) return;
    ref.read(sandboxTutorialProvider.notifier).markOffered();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Practice with a sample match?'),
        content: const Text(
          'A guided sandbox walks you through the scoring controls. '
          'Zero stats or XP are written -- exit anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Skip'),
          ),
          TextButton(
            key: const ValueKey('startSandboxButton'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SandboxScoringScreen()),
              );
            },
            child: const Text('Practice'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('Live scoring console (demo entry)')),
      body: Center(
        child: OutlinedButton(
          key: const ValueKey('openSandboxManuallyButton'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SandboxScoringScreen()),
          ),
          child: Text(
            'Open sandbox',
            style: AppTypography.body.copyWith(color: colors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class SandboxScoringScreen extends StatefulWidget {
  const SandboxScoringScreen({super.key});

  @override
  State<SandboxScoringScreen> createState() => _SandboxScoringScreenState();
}

class _SandboxScoringScreenState extends State<SandboxScoringScreen> {
  final List<String> _ballLog = [];
  int _coachMarkIndex = 0;
  bool _coachMarksDone = false;

  void _record(String label) {
    setState(() => _ballLog.add(label));
  }

  void _undo() {
    if (_ballLog.isEmpty) return;
    setState(() => _ballLog.removeLast());
  }

  void _nextCoachMark() {
    if (_coachMarkIndex >= sandboxCoachMarks.length - 1) {
      setState(() => _coachMarksDone = true);
    } else {
      setState(() => _coachMarkIndex++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Sandbox')),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                key: const ValueKey('sandboxWatermarkChip'),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                color: colors.surfaceAlt,
                child: Text(
                  'SANDBOX',
                  textAlign: TextAlign.center,
                  style: AppTypography.label.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ),
              Container(
                key: const ValueKey('zeroWritesBanner'),
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                color: colors.warning.withValues(alpha: 0.12),
                child: Text(
                  'Practice mode -- zero stat/XP writes.',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          children: [
                            for (var i = 0; i < _ballLog.length; i++)
                              Text(
                                'Ball ${i + 1}: ${_ballLog[i]}',
                                style: AppTypography.body.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        key: const ValueKey('sandboxRunButtons'),
                        spacing: AppSpacing.sm,
                        children: [
                          for (final runs in [0, 1, 2, 3, 4, 6])
                            OutlinedButton(
                              key: ValueKey('sandboxRunButton_$runs'),
                              onPressed: () => _record('$runs run(s)'),
                              child: Text('$runs'),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              key: const ValueKey('sandboxWicketButton'),
                              onPressed: () => _record('Wicket'),
                              child: const Text('Wicket'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: OutlinedButton(
                              key: const ValueKey('sandboxExtrasButton'),
                              onPressed: () => _record('Extra'),
                              child: const Text('Extras'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton(
                        key: const ValueKey('sandboxUndoButton'),
                        onPressed: _undo,
                        child: const Text('Undo'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (!_coachMarksDone)
            _CoachMarkOverlay(
              step: sandboxCoachMarks[_coachMarkIndex],
              stepIndex: _coachMarkIndex,
              totalSteps: sandboxCoachMarks.length,
              onNext: _nextCoachMark,
              onSkipAll: () => setState(() => _coachMarksDone = true),
            ),
        ],
      ),
    );
  }
}

class _CoachMarkOverlay extends StatelessWidget {
  final CoachMarkStep step;
  final int stepIndex;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkipAll;

  const _CoachMarkOverlay({
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.onNext,
    required this.onSkipAll,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Container(
            key: const ValueKey('coachMarkCard'),
            margin: const EdgeInsets.all(AppSpacing.xl),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.targetLabel,
                  style: AppTypography.title.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  step.description,
                  style: AppTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Text(
                      '${stepIndex + 1}/$totalSteps',
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      key: const ValueKey('skipCoachMarksButton'),
                      onPressed: onSkipAll,
                      child: const Text('Exit tutorial'),
                    ),
                    FilledButton(
                      key: const ValueKey('nextCoachMarkButton'),
                      onPressed: onNext,
                      child: Text(
                        stepIndex + 1 == totalSteps ? 'Done' : 'Next',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
