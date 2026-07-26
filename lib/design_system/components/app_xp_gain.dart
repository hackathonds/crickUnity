import 'dart:async';

import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_avatar.dart';

/// DS §3.16 XP Widget: "Level ring on avatars (2px, Arc gap)" is already
/// built (`AppAvatar`'s `levelProgress` + the shared `AppArcRing`) --
/// this wraps that existing, stateless avatar with an animated sweep
/// between two progress values, rather than adding animation state to
/// `AppAvatar` itself (which every other caller needs to stay a plain,
/// stateless snapshot).
class AppAvatarRingSweep extends StatelessWidget {
  final AppAvatarSize size;
  final String name;
  final ImageProvider? image;
  final double fromProgress;
  final double toProgress;
  final Duration duration;

  const AppAvatarRingSweep({
    super.key,
    required this.size,
    required this.name,
    required this.fromProgress,
    required this.toProgress,
    this.image,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.isReduced(context);

    return TweenAnimationBuilder<double>(
      key: const ValueKey('appAvatarRingSweepTween'),
      tween: Tween(begin: fromProgress, end: toProgress),
      duration: reduced ? Duration.zero : duration,
      curve: AppMotionCurves.standard,
      builder: (context, progress, child) => AppAvatar(
        size: size,
        name: name,
        image: image,
        levelProgress: progress,
      ),
    );
  }
}

/// DS §3.16: "gains render as ring-fill sweep + '+50 XP' toast-chip
/// bottom-center 2s." A one-shot floating toast, distinct from
/// `AppSnackbar` (that one's a general single-action queue-of-1 pattern;
/// this is XP-specific, self-dismissing, no action). The level-up
/// ceremony itself (DS §5.8 -- a full-screen overlay with its own queuing
/// rules) is out of scope here, the same deferred-to-later-epic boundary
/// already used for Avatar's XP animation and Reward Card's claim
/// overlay.
Future<void> showXpGainToast(
  BuildContext context, {
  required int amount,
  Duration visibleFor = const Duration(seconds: 2),
}) async {
  final overlay = Overlay.of(context);
  final colors = Theme.of(context).extension<AppColors>()!;
  final reduced = AppMotion.isReduced(context);
  final completer = Completer<void>();
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => Positioned(
      left: 0,
      right: 0,
      bottom: 32,
      child: Center(
        child: _XpToastChip(colors: colors, amount: amount),
      ),
    ),
  );
  overlay.insert(entry);

  Future.delayed(reduced ? Duration.zero : visibleFor, () {
    entry.remove();
    if (!completer.isCompleted) completer.complete();
  });

  return completer.future;
}

class _XpToastChip extends StatelessWidget {
  final AppColors colors;
  final int amount;
  const _XpToastChip({required this.colors, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('appXpGainToastChip'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.textPrimary,
        borderRadius: AppRadius.fullRadius,
      ),
      child: Text(
        '+$amount XP',
        style: AppTypography.button.copyWith(color: colors.bg),
      ),
    );
  }
}
