import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'go_live_models.dart';
import 'go_live_provider.dart';

/// DS §11.8: "Go-Live flow (squad/organizer): entry from Match Detail
/// [Go live]; pre-flight checklist card -> overlay theme picker (3
/// thumbnails) -> sponsor-slot confirm (if contracted) -> countdown
/// 3-2-1 -> live HUD: viewer count, health dot, [Mark moment], [End]."
class GoLiveScreen extends ConsumerStatefulWidget {
  const GoLiveScreen({super.key});

  @override
  ConsumerState<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends ConsumerState<GoLiveScreen> {
  Timer? _viewerTicker;

  @override
  void dispose() {
    _viewerTicker?.cancel();
    super.dispose();
  }

  void _startViewerTicker() {
    _viewerTicker?.cancel();
    _viewerTicker = Timer.periodic(
      const Duration(seconds: 4),
      (_) => ref.read(goLiveProvider.notifier).tickViewerCount(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(goLiveProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Go live')),
      body: switch (state.phase) {
        GoLivePhase.preflight => const _PreflightStep(),
        GoLivePhase.themePicker => const _ThemePickerStep(),
        GoLivePhase.sponsorConfirm => const _SponsorConfirmStep(),
        GoLivePhase.countdown => _CountdownStep(onDone: _startViewerTicker),
        GoLivePhase.live => const _LiveHudStep(),
        GoLivePhase.ended => const _EndedStep(),
      },
    );
  }
}

class _PreflightStep extends ConsumerWidget {
  const _PreflightStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final notifier = ref.read(goLiveProvider.notifier);
    final checklist = ref.watch(goLiveProvider.select((s) => s.checklist));

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pre-flight checklist',
            style: AppTypography.title.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          CheckboxListTile(
            key: const ValueKey('preflightOrientationCheckbox'),
            value: checklist.orientationOk,
            onChanged: (v) =>
                notifier.setChecklistItem(orientation: v ?? false),
            title: const Text('Phone is landscape and steady'),
          ),
          CheckboxListTile(
            key: const ValueKey('preflightStabilityCheckbox'),
            value: checklist.stabilityOk,
            onChanged: (v) => notifier.setChecklistItem(stability: v ?? false),
            title: const Text('Network connection is stable'),
          ),
          CheckboxListTile(
            key: const ValueKey('preflightScoreSyncCheckbox'),
            value: checklist.scoreSyncOk,
            onChanged: (v) => notifier.setChecklistItem(scoreSync: v ?? false),
            title: const Text('Live scoring is synced to this match'),
          ),
          const Spacer(),
          FilledButton(
            key: const ValueKey('preflightContinueButton'),
            onPressed: checklist.allOk ? notifier.confirmPreflight : null,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class _ThemePickerStep extends ConsumerWidget {
  const _ThemePickerStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final notifier = ref.read(goLiveProvider.notifier);
    final selected = ref.watch(goLiveProvider.select((s) => s.overlayTheme));

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overlay theme',
            style: AppTypography.title.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (final theme in OverlayTheme.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: GestureDetector(
                      key: ValueKey('overlayThemeThumb_${theme.name}'),
                      onTap: () => notifier.selectOverlayTheme(theme),
                      child: Container(
                        height: 96,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected == theme
                                ? colors.primary
                                : colors.border,
                            width: selected == theme ? 2 : 1,
                          ),
                        ),
                        child: Text(overlayThemeLabels[theme]!),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          FilledButton(
            key: const ValueKey('themePickerContinueButton'),
            onPressed: notifier.confirmThemeAndContinue,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class _SponsorConfirmStep extends ConsumerWidget {
  const _SponsorConfirmStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final notifier = ref.read(goLiveProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sponsor slot',
            style: AppTypography.title.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'This stream carries a contracted sponsor lower-third. '
            'Confirm it renders before going live.',
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
          const Spacer(),
          FilledButton(
            key: const ValueKey('confirmSponsorSlotButton'),
            onPressed: notifier.confirmSponsorSlot,
            child: const Text('Confirm sponsor slot'),
          ),
        ],
      ),
    );
  }
}

class _CountdownStep extends ConsumerStatefulWidget {
  final VoidCallback onDone;

  const _CountdownStep({required this.onDone});

  @override
  ConsumerState<_CountdownStep> createState() => _CountdownStepState();
}

class _CountdownStepState extends ConsumerState<_CountdownStep> {
  int _count = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_count <= 1) {
        t.cancel();
        ref.read(goLiveProvider.notifier).startLive();
        widget.onDone();
        return;
      }
      setState(() => _count--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Text(
        '$_count',
        key: const ValueKey('goLiveCountdownText'),
        style: AppTypography.scoreboard.copyWith(color: colors.textPrimary),
      ),
    );
  }
}

class _LiveHudStep extends ConsumerWidget {
  const _LiveHudStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final state = ref.watch(goLiveProvider);
    final notifier = ref.read(goLiveProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                key: const ValueKey('streamHealthDot'),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: state.healthStatus == StreamHealthStatus.healthy
                      ? colors.success
                      : colors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                streamHealthStatusLabels[state.healthStatus]!,
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const Spacer(),
              Icon(Icons.visibility, size: 16, color: colors.textTertiary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${state.viewerCount}',
                key: const ValueKey('viewerCountText'),
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                'Slow mode',
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
              const Spacer(),
              Switch(
                key: const ValueKey('slowModeToggle'),
                value: state.slowModeEnabled,
                onChanged: (_) => notifier.toggleSlowMode(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: SizedBox(
              width: 64,
              height: 64,
              child: FilledButton(
                key: const ValueKey('liveMarkMomentButton'),
                onPressed: notifier.markMoment,
                style: FilledButton.styleFrom(shape: const CircleBorder()),
                child: const Icon(Icons.bolt, size: 28),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Moments marked: ${state.moments.length}',
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
          const Spacer(),
          OutlinedButton(
            key: const ValueKey('endStreamButton'),
            onPressed: notifier.endStream,
            child: const Text('End stream'),
          ),
        ],
      ),
    );
  }
}

class _EndedStep extends ConsumerWidget {
  const _EndedStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final chapters = ref.read(goLiveProvider.notifier).vodChapters();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stream ended -- VOD saved to match gallery',
            style: AppTypography.title.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Chapters',
            style: AppTypography.label.copyWith(color: colors.textTertiary),
          ),
          for (final chapter in chapters)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Text(
                '${chapter.ballIndex}: ${chapter.label}',
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
            ),
        ],
      ),
    );
  }
}
