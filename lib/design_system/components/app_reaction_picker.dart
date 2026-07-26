import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_elevation.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// DS §3.14's 6 reactions. No reaction glyphs beyond `heart`/`props`
/// exist in DS §2.5's Social icon family -- rather than mix 2 hand-drawn
/// icons with 4 invented ones (violating §2.5's "never mix stroke
/// weights"), all 6 render as plain emoji, flagged here as a genuine gap
/// rather than guessed silently.
enum AppReactionType { clap, heart, fire, laugh, wow, sad }

const Map<AppReactionType, String> _reactionEmoji = {
  AppReactionType.clap: '👏',
  AppReactionType.heart: '❤️',
  AppReactionType.fire: '🔥',
  AppReactionType.laugh: '😂',
  AppReactionType.wow: '😮',
  AppReactionType.sad: '😢',
};

const double _targetSize = 48;
const double _fanRadius = 72;

/// The 6 target angles, in radians, fanning upward above the press point
/// -- NOT the same sweep/gap convention as [AppArcRing] (that one encodes
/// a progress-ring decoration with a fixed gap at 45° bottom-right; a
/// long-press reaction picker is a different UI pattern, a directional
/// selection fan opening above the thumb, so it gets its own geometry).
List<double> _fanAngles() => [
  for (var i = 0; i < 6; i++) (-160 + i * 28) * math.pi / 180,
];

/// DS §3.14 Reaction Bar: "Long-press any post/message → radial-arc
/// picker (6 reactions on the Arc, 48 targets) above thumb; quick-tap =
/// default Props clap. Chosen reaction particles once (8 particles,
/// 600ms). Counts pill under content; tap = breakdown sheet."
class AppReactionBar extends StatefulWidget {
  final Widget child;
  final int reactionCount;
  final AppReactionType? myReaction;
  final ValueChanged<AppReactionType> onReact;
  final VoidCallback? onCountsTap;

  const AppReactionBar({
    super.key,
    required this.child,
    required this.onReact,
    this.reactionCount = 0,
    this.myReaction,
    this.onCountsTap,
  });

  @override
  State<AppReactionBar> createState() => AppReactionBarState();
}

class AppReactionBarState extends State<AppReactionBar>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  int? _activeIndex;
  Offset _anchor = Offset.zero;
  late final AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _particleController.dispose();
    super.dispose();
  }

  void _quickTap() {
    widget.onReact(AppReactionType.clap);
    _playParticles();
  }

  void _playParticles() {
    if (!mounted) return;
    _particleController.forward(from: 0);
  }

  void _openPicker(Offset globalPosition) {
    final overlay = Overlay.of(context);
    _anchor = globalPosition;
    _activeIndex = null;
    _overlayEntry = OverlayEntry(
      builder: (context) => _ReactionFan(
        key: const ValueKey('appReactionPickerFan'),
        anchor: _anchor,
        activeIndex: _activeIndex,
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _updateActiveIndex(Offset globalPosition) {
    final angles = _fanAngles();
    int? closest;
    var closestDistance = double.infinity;
    for (var i = 0; i < angles.length; i++) {
      final targetCenter =
          _anchor +
          Offset(
            _fanRadius * math.cos(angles[i]),
            _fanRadius * math.sin(angles[i]),
          );
      final distance = (globalPosition - targetCenter).distance;
      if (distance < _targetSize / 2 && distance < closestDistance) {
        closest = i;
        closestDistance = distance;
      }
    }
    if (closest == _activeIndex) return;
    _activeIndex = closest;
    _overlayEntry?.markNeedsBuild();
  }

  void _commitPicker() {
    _removeOverlay();
    if (_activeIndex == null) return;
    final type = AppReactionType.values[_activeIndex!];
    widget.onReact(type);
    _playParticles();
    _activeIndex = null;
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return GestureDetector(
      onTap: _quickTap,
      onLongPressStart: (details) => _openPicker(details.globalPosition),
      onLongPressMoveUpdate: (details) =>
          _updateActiveIndex(details.globalPosition),
      onLongPressEnd: (_) => _commitPicker(),
      onLongPressCancel: _removeOverlay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              widget.child,
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, _) => !_particleController.isAnimating
                      ? const SizedBox.shrink()
                      : IgnorePointer(
                          child: CustomPaint(
                            key: const ValueKey('appReactionParticles'),
                            size: Size.infinite,
                            painter: _ParticlePainter(
                              progress: _particleController.value,
                              color: colors.primary,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          GestureDetector(
            key: const ValueKey('appReactionCountsPill'),
            onTap: widget.onCountsTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: AppRadius.fullRadius,
              ),
              child: Text(
                '${_reactionEmoji[widget.myReaction ?? AppReactionType.clap]} ${widget.reactionCount}',
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The floating overlay content: 6 reaction targets fanned above the
/// press anchor, the one under the finger highlighted. Purely visual --
/// all gesture handling stays on the main [GestureDetector] in
/// [AppReactionBarState], since this is one continuous press-drag-
/// release gesture, not independently tappable targets.
class _ReactionFan extends StatelessWidget {
  final Offset anchor;
  final int? activeIndex;

  const _ReactionFan({super.key, required this.anchor, this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final angles = _fanAngles();

    return Stack(
      children: [
        for (var i = 0; i < angles.length; i++)
          Positioned(
            left:
                anchor.dx + _fanRadius * math.cos(angles[i]) - _targetSize / 2,
            top: anchor.dy + _fanRadius * math.sin(angles[i]) - _targetSize / 2,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 120),
              scale: activeIndex == i ? 1.3 : 1.0,
              child: Container(
                width: _targetSize,
                height: _targetSize,
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                  boxShadow: AppElevation.e2.toBoxShadows(),
                  border: activeIndex == i
                      ? Border.all(color: colors.primary, width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    _reactionEmoji[AppReactionType.values[i]]!,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// DS §3.14's "Chosen reaction particles once (8 particles, 600ms)" --
/// plays once when a reaction commits (quick-tap or picker release),
/// driven by the single-shot [AnimationController] in
/// [AppReactionBarState].
class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ParticlePainter({required this.progress, required this.color});

  static const int _particleCount = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color.withValues(alpha: (1 - progress).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;
    final travel = 24 * progress;

    for (var i = 0; i < _particleCount; i++) {
      final angle = (2 * math.pi / _particleCount) * i;
      final offset =
          center + Offset(travel * math.cos(angle), travel * math.sin(angle));
      canvas.drawCircle(offset, 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
