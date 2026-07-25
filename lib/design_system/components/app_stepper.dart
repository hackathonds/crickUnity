import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_typography.dart';
import 'app_pressable.dart';
import 'app_shake.dart';

/// DS §3.9: "For counts (overs, players): 44h, [−][value tnum][+],
/// long-press = auto-repeat accelerating; bounds disable respective
/// button; invalid manual entry snaps back with shake 3px×2."
class AppStepper extends StatefulWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String semanticLabel;

  const AppStepper({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.semanticLabel,
  });

  @override
  State<AppStepper> createState() => AppStepperState();
}

/// Long-press auto-repeat schedule: starts slow and shortens each tick down
/// to a floor — DS's "auto-repeat accelerating."
const Duration _repeatStart = Duration(milliseconds: 400);
const Duration _repeatFloor = Duration(milliseconds: 80);
const Duration _repeatStep = Duration(milliseconds: 40);

class AppStepperState extends State<AppStepper> {
  Timer? _repeatTimer;
  Duration _currentInterval = _repeatStart;
  bool _editing = false;
  final _editController = TextEditingController();
  final _shakeTrigger = ValueNotifier<int>(0);

  @override
  void dispose() {
    _repeatTimer?.cancel();
    _shakeTrigger.dispose();
    _editController.dispose();
    super.dispose();
  }

  void _step(int delta) {
    final next = (widget.value + delta).clamp(widget.min, widget.max);
    if (next != widget.value) widget.onChanged(next);
  }

  void _startRepeating(int delta) {
    _currentInterval = _repeatStart;
    _scheduleNext(delta);
  }

  void _scheduleNext(int delta) {
    _repeatTimer = Timer(_currentInterval, () {
      _step(delta);
      _currentInterval = _currentInterval - _repeatStep < _repeatFloor
          ? _repeatFloor
          : _currentInterval - _repeatStep;
      _scheduleNext(delta);
    });
  }

  void _stopRepeating() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  void _beginEdit() {
    _editController.text = '${widget.value}';
    setState(() => _editing = true);
  }

  void _commitEdit() {
    final parsed = int.tryParse(_editController.text);
    if (parsed == null || parsed < widget.min || parsed > widget.max) {
      _shakeTrigger.value++;
    } else if (parsed != widget.value) {
      widget.onChanged(parsed);
    }
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final canDecrement = widget.value > widget.min;
    final canIncrement = widget.value < widget.max;

    return Semantics(
      label: widget.semanticLabel,
      value: '${widget.value}',
      child: AppShakeTarget(
        trigger: _shakeTrigger,
        child: Container(
          key: const ValueKey('appStepperBox'),
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: AppRadius.smRadius,
          ),
          child: Row(
            children: [
              _StepButton(
                key: const ValueKey('appStepperMinus'),
                glyph: '−',
                onPressed: canDecrement ? () => _step(-1) : null,
                onLongPressStart: canDecrement
                    ? () => _startRepeating(-1)
                    : null,
                onLongPressEnd: _stopRepeating,
              ),
              Expanded(
                child: Center(
                  child: _editing
                      ? SizedBox(
                          width: 48,
                          child: TextField(
                            key: const ValueKey('appStepperEditField'),
                            controller: _editController,
                            autofocus: true,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: AppTypography.body.copyWith(
                              color: colors.textPrimary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onSubmitted: (_) => _commitEdit(),
                            onEditingComplete: _commitEdit,
                          ),
                        )
                      : GestureDetector(
                          key: const ValueKey('appStepperValue'),
                          onTap: _beginEdit,
                          child: Text(
                            '${widget.value}',
                            style: AppTypography.body.copyWith(
                              color: colors.textPrimary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
              _StepButton(
                key: const ValueKey('appStepperPlus'),
                glyph: '+',
                onPressed: canIncrement ? () => _step(1) : null,
                onLongPressStart: canIncrement
                    ? () => _startRepeating(1)
                    : null,
                onLongPressEnd: _stopRepeating,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final String glyph;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;

  const _StepButton({
    super.key,
    required this.glyph,
    required this.onPressed,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final enabled = onPressed != null;

    return GestureDetector(
      onLongPressStart: enabled ? (_) => onLongPressStart?.call() : null,
      onLongPressEnd: enabled ? (_) => onLongPressEnd?.call() : null,
      onLongPressCancel: enabled ? onLongPressEnd : null,
      child: AppPressable(
        onPressed: onPressed,
        tintColor: colors.primary,
        cornerRadius: AppRadius.sm,
        focusRingColor: colors.primary,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Text(
              glyph,
              style: AppTypography.button.copyWith(
                color: enabled ? colors.textPrimary : colors.disabledFg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
