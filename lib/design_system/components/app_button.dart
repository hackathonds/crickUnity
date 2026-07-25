import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../icons/app_icon.dart';
import '../icons/app_icon_id.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_elevation.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// DS §3.1's four label-button variants. Height/padding/radius/fill per
/// the spec's table.
enum AppButtonVariant { primary, secondary, tertiary, destructive }

/// Shared press/focus mechanics for every button in this file — DS §3
/// intro's global anatomy: pressed = scale 0.98 + 8% tint over 80ms;
/// focused = 2px ring offset 2px (a reserved, always-present 2px gutter
/// avoids layout shift when focus toggles).
class _Pressable extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color tintColor;
  final double cornerRadius;
  final Color focusRingColor;

  const _Pressable({
    required this.onPressed,
    required this.child,
    required this.tintColor,
    required this.cornerRadius,
    required this.focusRingColor,
  });

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: AppMotionDuration.instant,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    if (pressed) {
      _scaleController.forward();
    } else {
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    return Focus(
      onFocusChange: (value) => setState(() => _focused = value),
      child: GestureDetector(
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        onTap: widget.onPressed,
        child: Container(
          key: const ValueKey('appButtonFocusRing'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.cornerRadius + 2),
            border: Border.all(
              color: _focused ? widget.focusRingColor : Colors.transparent,
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(2),
          child: AnimatedBuilder(
            animation: _scaleController,
            builder: (context, child) {
              final t = _scaleController.value;
              return Transform.scale(
                scale: 1.0 - (0.02 * t),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.cornerRadius),
                    color: enabled
                        ? widget.tintColor.withValues(alpha: 0.08 * t)
                        : null,
                  ),
                  child: child,
                ),
              );
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// 20px Arc spinner — DS §5 pattern 4: "sweep 270°, rotate 900ms" (reuses
/// [AppMotionDuration.ceremony], not a new token); freezes under reduced
/// motion instead of spinning.
class _ArcSpinner extends StatefulWidget {
  final Color color;
  const _ArcSpinner({required this.color});

  @override
  State<_ArcSpinner> createState() => _ArcSpinnerState();
}

class _ArcSpinnerState extends State<_ArcSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _motionInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotionDuration.ceremony,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionInitialized) return;
    _motionInitialized = true;
    if (!AppMotion.isReduced(context)) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: SizedBox(
        width: 20,
        height: 20,
        child: CustomPaint(painter: _ArcSpinnerPainter(widget.color)),
      ),
    );
  }
}

class _ArcSpinnerPainter extends CustomPainter {
  final Color color;
  const _ArcSpinnerPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 1.5, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ArcSpinnerPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// The four label-button variants — DS §3.1. `isLoading` fades the label
/// and centers a 20px Arc spinner, width locked (button-specific loading
/// spec, overriding the generic skeleton rule).
class AppButton extends StatelessWidget {
  final AppButtonVariant variant;
  final String label;
  final VoidCallback? onPressed;
  final AppIconId? icon;
  final bool isLoading;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.variant,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final enabled = onPressed != null && !isLoading;

    final (double height, double padH) = switch (variant) {
      AppButtonVariant.tertiary => (44.0, AppSpacing.lg),
      _ => (52.0, AppSpacing.xxl),
    };

    // No dedicated "onError" token exists yet — onPrimary is reused as the
    // closest "contrasts against a bold theme surface" token.
    var (
      Color background,
      Color foreground,
      Border? border,
    ) = switch (variant) {
      AppButtonVariant.primary => (colors.primary, colors.onPrimary, null),
      AppButtonVariant.secondary => (
        Colors.transparent,
        colors.primary,
        Border.all(color: colors.primary, width: 1.5),
      ),
      AppButtonVariant.tertiary => (Colors.transparent, colors.primary, null),
      AppButtonVariant.destructive => (colors.error, colors.onPrimary, null),
    };

    if (!enabled && onPressed == null) {
      final isOutlineVariant =
          variant == AppButtonVariant.secondary ||
          variant == AppButtonVariant.tertiary;
      background = isOutlineVariant ? Colors.transparent : colors.disabledBg;
      foreground = colors.disabledFg;
      border = border != null
          ? Border.all(color: colors.disabledFg, width: 1.5)
          : null;
    }

    final content = isLoading
        ? Center(child: _ArcSpinner(color: foreground))
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                AppIcon(
                  id: icon!,
                  semanticLabel: label,
                  color: foreground,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.button.copyWith(color: foreground),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    return _Pressable(
      onPressed: enabled ? onPressed : null,
      tintColor: colors.primary,
      cornerRadius: AppRadius.sm,
      focusRingColor: colors.primary,
      child: Container(
        key: const ValueKey('appButtonSurface'),
        height: height,
        width: fullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(horizontal: padH),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.smRadius,
          border: border,
        ),
        child: content,
      ),
    );
  }
}

/// 44×44 icon button — DS §3.1. `selected` uses [AppIcon]'s filled variant
/// (outline = available, filled = active, per DS §2.5's global rule).
class AppIconButton extends StatelessWidget {
  final AppIconId icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final bool selected;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final enabled = onPressed != null;
    final color = enabled ? colors.textPrimary : colors.disabledFg;

    return _Pressable(
      onPressed: onPressed,
      tintColor: colors.primary,
      cornerRadius: AppRadius.full,
      focusRingColor: colors.primary,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: AppIcon(
            id: icon,
            semanticLabel: semanticLabel,
            active: selected,
            color: color,
            size: 24,
          ),
        ),
      ),
    );
  }
}

/// Inline Yes/No decision chip — DS §3.1's Chip-action row (36h, r-full,
/// `surfaceAlt` fill). `selected` tints the border/text `primary`.
class AppChipActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool selected;

  const AppChipActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final enabled = onPressed != null;
    final foreground = !enabled
        ? colors.disabledFg
        : (selected ? colors.primary : colors.textPrimary);

    return _Pressable(
      onPressed: onPressed,
      tintColor: colors.primary,
      cornerRadius: AppRadius.full,
      focusRingColor: colors.primary,
      child: Container(
        key: const ValueKey('appChipActionSurface'),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: AppRadius.fullRadius,
          border: selected
              ? Border.all(color: colors.primary, width: 1.5)
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.button.copyWith(color: foreground),
          ),
        ),
      ),
    );
  }
}

/// The tab-bar-center FAB — DS §3.1 (56 circular, `primary`, e2). Reused by
/// [AppShell] instead of a raw `FloatingActionButton`.
class AppFab extends StatelessWidget {
  final AppIconId icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  const AppFab({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return _Pressable(
      onPressed: onPressed,
      tintColor: colors.onPrimary,
      cornerRadius: AppRadius.full,
      focusRingColor: colors.textPrimary,
      child: Container(
        key: const ValueKey('appFabSurface'),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: colors.primary,
          shape: BoxShape.circle,
          boxShadow: AppElevation.e2.toBoxShadows(),
        ),
        child: Center(
          child: AppIcon(
            id: icon,
            semanticLabel: semanticLabel,
            color: colors.onPrimary,
            size: 24,
          ),
        ),
      ),
    );
  }
}
