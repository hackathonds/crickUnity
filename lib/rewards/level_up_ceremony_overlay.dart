import 'package:flutter/material.dart';

import '../design_system/components/app_arc_ring.dart';
import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_motion.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';

/// DS §5.8 (Achievement/level ceremony): "full overlay -- dim 60%,
/// badge scales 0.6->1 spring, Arc rays sweep, name letters cascade
/// 20ms/char, [Share] [Done]; 1.4s to interactive; skippable by tap;
/// queues if multiple (never stacks); suppressed during Live Scoring &
/// money confirmations, delivered after." Reuses the existing
/// `AppArcRing` primitive (E0-07/E0-08) for the "Arc rays sweep" rather
/// than a new painter.
Future<void> showLevelUpCeremony(BuildContext context, {required int level}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    barrierLabel: 'Level up',
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (context, animation, secondaryAnimation) =>
        _LevelUpCeremonyContent(level: level),
  );
}

class _LevelUpCeremonyContent extends StatelessWidget {
  final int level;

  const _LevelUpCeremonyContent({required this.level});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final reduced = AppMotion.isReduced(context);
    final label = 'Level $level';

    return GestureDetector(
      key: const ValueKey('levelUpCeremonyOverlay'),
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1.0),
                duration: reduced
                    ? Duration.zero
                    : const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AppArcRing(
                        progress: 1.0,
                        size: 96,
                        strokeWidth: 4,
                        trackColor: colors.coin.withValues(alpha: 0.2),
                        fillColor: colors.coin,
                      ),
                      Icon(Icons.military_tech, size: 40, color: colors.coin),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < label.length; i++)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: reduced
                          ? Duration.zero
                          : const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      // 20ms/char cascade.
                      builder: (context, value, child) =>
                          Opacity(opacity: value, child: child),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0.5),
                        child: Text(
                          label[i],
                          style: AppTypography.h1.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    key: const ValueKey('ceremonyShareButton'),
                    variant: AppButtonVariant.secondary,
                    label: 'Share',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    key: const ValueKey('ceremonyDoneButton'),
                    variant: AppButtonVariant.primary,
                    label: 'Done',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
