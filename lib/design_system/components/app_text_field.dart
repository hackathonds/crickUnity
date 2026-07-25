import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_shake.dart';

/// DS §3.19 Forms (global): "Field 52h, r-sm, 1px border → primary 1.5px on
/// focus; floating label 13→11 rise 160ms; helper/error text 13 below
/// (error `error` + icon 14, field shakes 3px×2 once, error announced to
/// screen reader). Inline validation on blur."
class AppTextField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final String? Function(String value)? validator;
  final String? helperText;
  final bool enabled;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  /// A fixed, non-floating prefix rendered before the input (e.g. a
  /// currency symbol) — used by [AppCurrencyField].
  final String? prefixText;
  final TextAlign textAlign;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.helperText,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.prefixText,
    this.textAlign = TextAlign.start,
    this.inputFormatters,
  });

  @override
  State<AppTextField> createState() => AppTextFieldState();
}

class AppTextFieldState extends State<AppTextField> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  final _shakeTrigger = ValueNotifier<int>(0);
  String? _errorText;

  bool get _floated =>
      _focusNode.hasFocus ||
      _controller.text.isNotEmpty ||
      widget.prefixText != null;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _validate();
    }
    setState(() {});
  }

  void _validate() {
    final error = widget.validator?.call(_controller.text);
    if (error != null && _errorText == null) {
      _shakeTrigger.value++;
    }
    setState(() => _errorText = error);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _shakeTrigger.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final hasError = _errorText != null;
    final borderColor = hasError
        ? colors.error
        : (_focusNode.hasFocus ? colors.primary : colors.border);
    final borderWidth = _focusNode.hasFocus || hasError ? 1.5 : 1.0;
    final duration = AppMotion.resolveDuration(context, AppMotionToken.fast);

    return AppShakeTarget(
      trigger: _shakeTrigger,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            key: const ValueKey('appTextFieldBox'),
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: AppRadius.smRadius,
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedAlign(
                  duration: duration,
                  curve: AppMotionCurves.standard,
                  alignment: _floated
                      ? Alignment.topLeft
                      : Alignment.centerLeft,
                  child: AnimatedDefaultTextStyle(
                    duration: duration,
                    curve: AppMotionCurves.standard,
                    style: AppTypography.caption.copyWith(
                      fontSize: _floated ? 11 : 13,
                      color: hasError ? colors.error : colors.textTertiary,
                      height: 1,
                    ),
                    child: Transform.translate(
                      offset: Offset(0, _floated ? -6 : 0),
                      child: Text(widget.label),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: _floated ? 2 : 0),
                    child: TextField(
                      key: const ValueKey('appTextFieldInput'),
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      keyboardType: widget.keyboardType,
                      textAlign: widget.textAlign,
                      inputFormatters: widget.inputFormatters,
                      onChanged: (value) {
                        widget.onChanged?.call(value);
                        setState(() {});
                      },
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        prefixText: widget.prefixText,
                        prefixStyle: AppTypography.body.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hasError || widget.helperText != null)
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.xs,
                left: AppSpacing.lg,
              ),
              child: hasError
                  ? Semantics(
                      liveRegion: true,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ErrorGlyph(color: colors.error),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              _errorText!,
                              style: AppTypography.caption.copyWith(
                                color: colors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      widget.helperText!,
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

/// A 14px error indicator — no hand-drawn "alert" glyph exists in DS §2.5's
/// icon families, and adding one for this single use would be over-scoped
/// (same reasoning as [AppDeltaChip]'s plain trend arrows).
class _ErrorGlyph extends StatelessWidget {
  final Color color;
  const _ErrorGlyph({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: const Center(
        child: Text(
          '!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
      ),
    );
  }
}
