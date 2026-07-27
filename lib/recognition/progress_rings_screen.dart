import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_arc_ring.dart';
import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'progress_ring_models.dart';
import 'progress_rings_provider.dart';

/// Backlog addendum: "Weekly Play/Train/Contribute rings with user
/// targets, ring-close streaks + burst, distinct from goals." Reuses
/// AppArcRing (its Nth reuse this session) for each ring, with a simple
/// scale+fade burst on close -- the same tap-burst visual language as
/// chest_claim_overlay.dart (E6-06), not a new painter.
class ProgressRingsScreen extends ConsumerStatefulWidget {
  const ProgressRingsScreen({super.key});

  @override
  ConsumerState<ProgressRingsScreen> createState() =>
      _ProgressRingsScreenState();
}

class _ProgressRingsScreenState extends ConsumerState<ProgressRingsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burstController;
  RingType? _burstingRing;

  @override
  void initState() {
    super.initState();
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _burstController.dispose();
    super.dispose();
  }

  void _maybePlayBurst() {
    final closed = ref.read(progressRingsProvider.notifier).consumeJustClosed();
    if (closed != null) {
      setState(() => _burstingRing = closed);
      _burstController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final notifier = ref.read(progressRingsProvider.notifier);
    ref.watch(progressRingsProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePlayBurst());

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Rings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final type in RingType.values)
                _RingTile(
                  key: ValueKey('ringTile_${type.name}'),
                  type: type,
                  ring: ref.watch(progressRingsProvider).ringFor(type),
                  colors: colors,
                  bursting: _burstingRing == type,
                  burstController: _burstController,
                  onIncrement: () => notifier.recordProgress(type, 1),
                  onSetTarget: (target) => notifier.setTarget(type, target),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingTile extends StatelessWidget {
  final RingType type;
  final WeeklyRingProgress ring;
  final AppColors colors;
  final bool bursting;
  final AnimationController burstController;
  final VoidCallback onIncrement;
  final ValueChanged<int> onSetTarget;

  const _RingTile({
    super.key,
    required this.type,
    required this.ring,
    required this.colors,
    required this.bursting,
    required this.burstController,
    required this.onIncrement,
    required this.onSetTarget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AppArcRing(
                progress: ring.fraction,
                size: 80,
                strokeWidth: 6,
                trackColor: colors.border,
                fillColor: ring.isClosed ? colors.success : colors.primary,
              ),
              Text('${ring.progress}/${ring.target}'),
              if (bursting)
                AnimatedBuilder(
                  animation: burstController,
                  builder: (context, _) => Opacity(
                    opacity: (1 - burstController.value).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 1 + burstController.value,
                      child: Icon(
                        Icons.celebration,
                        color: colors.coin,
                        size: 40,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(ringTypeLabels[type]!, style: AppTypography.body),
        Text(
          'Streak: ${ring.closeStreak}',
          style: AppTypography.caption.copyWith(color: colors.textTertiary),
        ),
        AppButton(
          key: ValueKey('incrementRingButton_${type.name}'),
          variant: AppButtonVariant.tertiary,
          label: '+1',
          onPressed: onIncrement,
        ),
        AppButton(
          key: ValueKey('increaseTargetButton_${type.name}'),
          variant: AppButtonVariant.tertiary,
          label: 'Target +1',
          onPressed: () => onSetTarget(ring.target + 1),
        ),
      ],
    );
  }
}
