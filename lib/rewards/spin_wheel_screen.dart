import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_motion.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'luck_models.dart';
import 'luck_odds_screen.dart';
import 'luck_provider.dart';
import 'rewards_provider.dart';

const Map<SpinBlockReason, String> _spinBlockMessages = {
  SpinBlockReason.levelLocked: 'Spin unlocks at Level 5.',
  SpinBlockReason.alreadySpunToday:
      "You've already spun today -- come back tomorrow.",
};

/// DS §7-56: "spin (wheel physics, odds link visible)." A full physics
/// simulation is more than this scope needs -- a multi-turn
/// Transform.rotate settling on the RNG-chosen segment is the same
/// "wheel that spins and lands" experience without a physics engine.
class SpinWheelScreen extends ConsumerStatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  ConsumerState<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends ConsumerState<SpinWheelScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _targetTurns = 0;
  SpinSegment? _result;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spin(int viewerLevel) {
    final segment = ref.read(luckLayerProvider.notifier).spinWheel();
    final segments = SpinSegment.values;
    final index = segments.indexOf(segment);
    final segmentAngle = 2 * pi / segments.length;
    final reduced = AppMotion.isReduced(context);
    setState(() {
      _result = segment;
      _targetTurns =
          (reduced ? 0 : 4) + (index + 0.5) * segmentAngle / (2 * pi);
    });
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final rewards = ref.watch(rewardsProvider);
    final notifier = ref.read(luckLayerProvider.notifier);
    final blockReason = notifier.spinBlockReason(viewerLevel: rewards.level);
    final segments = SpinSegment.values;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spin wheel'),
        actions: [
          IconButton(
            key: const ValueKey('spinOddsLinkButton'),
            icon: const Icon(Icons.info_outline),
            tooltip: 'Odds',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const LuckOddsScreen())),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _controller.value * _targetTurns * 2 * pi,
                  child: child,
                );
              },
              child: Container(
                key: const ValueKey('spinWheelDial'),
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.surfaceAlt,
                  border: Border.all(color: colors.coin, width: 3),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    for (var i = 0; i < segments.length; i++)
                      Transform.rotate(
                        angle: i * (2 * pi / segments.length),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              spinSegmentLabels[segments[i]]!.split(' ').first,
                              style: AppTypography.caption.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Icon(Icons.stars, color: colors.coin, size: 28),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _result == null
                  ? (blockReason != null
                        ? _spinBlockMessages[blockReason]!
                        : '1 free spin/day')
                  : 'Result: ${spinSegmentLabels[_result]}',
              style: AppTypography.body.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const ValueKey('spinWheelButton'),
              variant: AppButtonVariant.primary,
              label: 'Spin',
              onPressed: blockReason == null && _result == null
                  ? () => _spin(rewards.level)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
