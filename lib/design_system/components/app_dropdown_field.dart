import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_bottom_sheet.dart';
import 'app_text_field.dart';

/// DS §3.7: "Field 52h styled as input; opens bottom sheet (never floating
/// menus on mobile) with radio rows 52h, search row if >8 options. Selected
/// row: filled radio + primary text."
class AppDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> options;
  final String Function(T option) labelBuilder;
  final ValueChanged<T> onChanged;
  final String hint;

  const AppDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
    this.hint = 'Select',
  });

  Future<void> _open(BuildContext context) async {
    final selected = await showAppBottomSheet<T>(
      context: context,
      title: label,
      contentBuilder: (context) => _DropdownSheetContent<T>(
        value: value,
        options: options,
        labelBuilder: labelBuilder,
      ),
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return GestureDetector(
      onTap: () => _open(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: const ValueKey('appDropdownFieldBox'),
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          border: Border.all(color: colors.border),
          borderRadius: AppRadius.smRadius,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      fontSize: 11,
                      color: colors.textTertiary,
                    ),
                  ),
                  Text(
                    value != null ? labelBuilder(value as T) : hint,
                    style: AppTypography.body.copyWith(
                      color: value != null
                          ? colors.textPrimary
                          : colors.textTertiary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              '▾',
              style: AppTypography.body.copyWith(color: colors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownSheetContent<T> extends StatefulWidget {
  final T? value;
  final List<T> options;
  final String Function(T option) labelBuilder;

  const _DropdownSheetContent({
    required this.value,
    required this.options,
    required this.labelBuilder,
  });

  @override
  State<_DropdownSheetContent<T>> createState() =>
      _DropdownSheetContentState<T>();
}

class _DropdownSheetContentState<T> extends State<_DropdownSheetContent<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final visible = _query.isEmpty
        ? widget.options
        : widget.options
              .where(
                (o) => widget
                    .labelBuilder(o)
                    .toLowerCase()
                    .contains(_query.toLowerCase()),
              )
              .toList();

    return Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.options.length > 8)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: AppTextField(
                key: const ValueKey('appDropdownSearchField'),
                label: 'Search',
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
          for (final option in visible)
            _DropdownRadioRow<T>(
              option: option,
              label: widget.labelBuilder(option),
              selected: option == widget.value,
              onTap: () => Navigator.of(context).pop(option),
            ),
        ],
      ),
    );
  }
}

class _DropdownRadioRow<T> extends StatelessWidget {
  final T option;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DropdownRadioRow({
    required this.option,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              _RadioGlyph(
                selected: selected,
                color: colors.primary,
                unselectedColor: colors.border,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body.copyWith(
                    color: selected ? colors.primary : colors.textPrimary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioGlyph extends StatelessWidget {
  final bool selected;
  final Color color;
  final Color unselectedColor;

  const _RadioGlyph({
    required this.selected,
    required this.color,
    required this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? color : unselectedColor,
          width: 1.5,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            )
          : null,
    );
  }
}
