import 'package:flutter/material.dart';

import '../icons/app_icon.dart';
import '../icons/app_icon_id.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_spacing.dart';

/// DS §5.12: "Swipe rows: action underlay reveals with icon scaling
/// 0.8→1 at 40% threshold; haptic at commit point; snap-back 160ms."
/// Reused by Match Card (this sub-task) and Expense Row (next sub-task).
///
/// No `HapticFeedback` call is wired here — no haptics package/call
/// exists anywhere else in this codebase yet, so the commit-point haptic
/// is left as a PR open question rather than an isolated one-off call.
class AppSwipeAction {
  final AppIconId icon;
  final String label;
  final Color color;
  final VoidCallback onTrigger;

  const AppSwipeAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTrigger,
  });
}

class AppSwipeActionRow extends StatefulWidget {
  final Widget child;
  final AppSwipeAction? leftAction;
  final AppSwipeAction? rightAction;

  const AppSwipeActionRow({
    super.key,
    required this.child,
    this.leftAction,
    this.rightAction,
  });

  @override
  State<AppSwipeActionRow> createState() => AppSwipeActionRowState();
}

/// Fraction of the row's width that must be dragged before release commits
/// the action — DS §5.12's "40% threshold."
const double _commitThreshold = 0.4;

class AppSwipeActionRowState extends State<AppSwipeActionRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _rowWidth = 0;
  double _dragExtent = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      value: 0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_rowWidth == 0) return;
    setState(() {
      _dragExtent += details.delta.dx;
      if (_dragExtent > 0 && widget.leftAction == null) _dragExtent = 0;
      if (_dragExtent < 0 && widget.rightAction == null) _dragExtent = 0;
      _dragExtent = _dragExtent.clamp(-_rowWidth, _rowWidth);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final progress = _dragExtent.abs() / (_rowWidth == 0 ? 1 : _rowWidth);
    if (progress >= _commitThreshold) {
      if (_dragExtent > 0) {
        widget.leftAction?.onTrigger();
      } else {
        widget.rightAction?.onTrigger();
      }
    }
    setState(() => _dragExtent = 0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final duration = AppMotion.resolveDuration(context, AppMotionToken.fast);

    return LayoutBuilder(
      builder: (context, constraints) {
        _rowWidth = constraints.maxWidth;
        final progress = _rowWidth == 0
            ? 0.0
            : (_dragExtent.abs() / _rowWidth).clamp(0.0, 1.0);
        final iconScale =
            0.8 + (0.2 * (progress / _commitThreshold).clamp(0.0, 1.0));

        return Stack(
          children: [
            if (_dragExtent > 0 && widget.leftAction != null)
              Positioned.fill(
                child: Container(
                  key: const ValueKey('appSwipeActionRowLeftUnderlay'),
                  alignment: Alignment.centerLeft,
                  color: widget.leftAction!.color.withValues(alpha: 0.12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Transform.scale(
                    scale: iconScale,
                    child: AppIcon(
                      id: widget.leftAction!.icon,
                      semanticLabel: widget.leftAction!.label,
                      color: widget.leftAction!.color,
                    ),
                  ),
                ),
              ),
            if (_dragExtent < 0 && widget.rightAction != null)
              Positioned.fill(
                child: Container(
                  key: const ValueKey('appSwipeActionRowRightUnderlay'),
                  alignment: Alignment.centerRight,
                  color: widget.rightAction!.color.withValues(alpha: 0.12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Transform.scale(
                    scale: iconScale,
                    child: AppIcon(
                      id: widget.rightAction!.icon,
                      semanticLabel: widget.rightAction!.label,
                      color: widget.rightAction!.color,
                    ),
                  ),
                ),
              ),
            GestureDetector(
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              child: AnimatedContainer(
                key: const ValueKey('appSwipeActionRowContent'),
                duration: _dragExtent == 0 ? duration : Duration.zero,
                transform: Matrix4.translationValues(_dragExtent, 0, 0),
                color: colors.bg,
                child: widget.child,
              ),
            ),
          ],
        );
      },
    );
  }
}
