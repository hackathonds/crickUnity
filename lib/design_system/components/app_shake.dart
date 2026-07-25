import 'package:flutter/material.dart';

import '../tokens/app_motion.dart';

/// DS §3.9/§3.19's shared "shake 3px×2 once" — the Stepper's invalid
/// manual entry and Forms fields' blur-validation error both cite this
/// exact spec, so it's built once here rather than twice.
///
/// `trigger` is a [ValueNotifier] the caller increments to play the shake;
/// the value itself is unused, only the change notification matters.
class AppShakeTarget extends StatefulWidget {
  final ValueNotifier<int> trigger;
  final Widget child;

  const AppShakeTarget({super.key, required this.trigger, required this.child});

  @override
  State<AppShakeTarget> createState() => _AppShakeTargetState();
}

class _AppShakeTargetState extends State<AppShakeTarget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _offset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 3, end: -3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -3, end: 3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 3, end: 0), weight: 1),
    ]).animate(_controller);
    widget.trigger.addListener(_onTrigger);
  }

  void _onTrigger() {
    if (AppMotion.isReduced(context)) return;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    widget.trigger.removeListener(_onTrigger);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      builder: (context, child) =>
          Transform.translate(offset: Offset(_offset.value, 0), child: child),
      child: widget.child,
    );
  }
}
