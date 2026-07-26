import 'package:flutter/material.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'titles_models.dart';

/// DS §11.18: "Profile edit → Titles row → sheet of earned titles
/// (radio), preview on name live; seasonal expired shown in archive
/// section."
Future<void> showTitlePickerSheet({
  required BuildContext context,
  required String name,
  required List<EquipableTitle> titles,
  required String? currentEquipped,
  required ValueChanged<String?> onEquip,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _TitlePickerContent(
      name: name,
      titles: titles,
      initialEquipped: currentEquipped,
      onEquip: onEquip,
    ),
  );
}

class _TitlePickerContent extends StatefulWidget {
  final String name;
  final List<EquipableTitle> titles;
  final String? initialEquipped;
  final ValueChanged<String?> onEquip;

  const _TitlePickerContent({
    required this.name,
    required this.titles,
    required this.initialEquipped,
    required this.onEquip,
  });

  @override
  State<_TitlePickerContent> createState() => _TitlePickerContentState();
}

class _TitlePickerContentState extends State<_TitlePickerContent> {
  late String? _selected = widget.initialEquipped;

  void _select(String? value) => setState(() {
    _selected = value;
    widget.onEquip(value);
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final active = widget.titles.where((t) => !t.isExpired).toList();
    final archived = widget.titles.where((t) => t.isExpired).toList();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Titles',
            style: AppTypography.title.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            key: const ValueKey('titlePickerPreview'),
            _selected == null ? widget.name : '${widget.name} · $_selected',
            style: AppTypography.subtitle.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),
          _RadioRow(
            key: const ValueKey('titleOption_none'),
            label: 'None',
            selected: _selected == null,
            onTap: () => _select(null),
          ),
          for (final title in active)
            _RadioRow(
              key: ValueKey('titleOption_${title.name}'),
              label: title.name,
              selected: _selected == title.name,
              onTap: () => _select(title.name),
            ),
          if (archived.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Archive (expired)',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            for (final title in archived)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Text(
                  title.name,
                  key: ValueKey('titleArchived_${title.name}'),
                  style: AppTypography.body.copyWith(color: colors.disabledFg),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// A plain tappable radio row -- no dedicated selectable-list primitive
/// exists in the design system yet (style_tag_picker_sheet.dart's chips
/// are multi-select, not this single-select radio shape), and
/// `RadioListTile`/`Radio` are deprecated in this Flutter version in
/// favor of a `RadioGroup` ancestor API this codebase doesn't use
/// elsewhere -- a hand-rolled row keeps this story's footprint small
/// rather than adopting a new framework API for one sheet.
class _RadioRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RadioRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? colors.primary : colors.border,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.primary,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                label,
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
