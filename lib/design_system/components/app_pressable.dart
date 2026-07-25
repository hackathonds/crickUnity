import 'package:flutter/material.dart';

import '../tokens/app_motion.dart';

/// Shared press/focus mechanics for every interactive component in this
/// design system — DS §3 intro's global anatomy: pressed = scale 0.98 +
/// 8% tint over 80ms; focused = 2px ring offset 2px (a reserved,
/// always-present 2px gutter avoids layout shift when focus toggles).
/// Originally built for buttons (E0-07 sub-task 1); extracted here so
/// cards (sub-task 2) and later components reuse the same mechanic
/// instead of duplicating it.
class AppPressable extends StatefulWidget {
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Widget child;
  final Color tintColor;
  final double cornerRadius;
  final Color focusRingColor;

  const AppPressable({
    super.key,
    required this.onPressed,
    required this.child,
    required this.tintColor,
    required this.cornerRadius,
    required this.focusRingColor,
    this.onLongPress,
  });

  @override
  State<AppPressable> createState() => AppPressableState();
}

class AppPressableState extends State<AppPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController scaleController;
  bool focused = false;

  @override
  void initState() {
    super.initState();
    scaleController = AnimationController(
      vsync: this,
      duration: AppMotionDuration.instant,
    );
  }

  @override
  void dispose() {
    scaleController.dispose();
    super.dispose();
  }

  void setPressed(bool pressed) {
    if (pressed) {
      scaleController.forward();
    } else {
      scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null || widget.onLongPress != null;

    return Focus(
      onFocusChange: (value) => setState(() => focused = value),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setPressed(true) : null,
        onTapUp: enabled ? (_) => setPressed(false) : null,
        onTapCancel: enabled ? () => setPressed(false) : null,
        onTap: widget.onPressed,
        onLongPress: widget.onLongPress,
        child: Container(
          key: const ValueKey('appPressableFocusRing'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.cornerRadius + 2),
            border: Border.all(
              color: focused ? widget.focusRingColor : Colors.transparent,
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(2),
          child: AnimatedBuilder(
            animation: scaleController,
            builder: (context, child) {
              final t = scaleController.value;
              return Transform.scale(
                scale: 1.0 - (0.02 * t),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.cornerRadius),
                    color: widget.onPressed != null
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
