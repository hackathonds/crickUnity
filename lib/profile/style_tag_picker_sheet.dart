import 'package:flutter/material.dart';

import '../design_system/components/app_button.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';

/// PRD §5.8: "Style tags: self-selected (max 5: 'Anchor', 'Death-over
/// hitter', 'New-ball swing')." Those three plus a representative set of
/// similar tags -- PRD gives examples, not an exhaustive canonical list.
const int maxStyleTags = 5;

const List<String> availableStyleTags = [
  'Anchor',
  'Death-over hitter',
  'New-ball swing',
  'Powerplay enforcer',
  'Finisher',
  'Spin specialist',
  'Part-time bowler',
  'Safe hands',
];

/// Self-view only -- callers gate that (see [ProfileOverviewTab]).
Future<void> showStyleTagPickerSheet({
  required BuildContext context,
  required List<String> currentTags,
  required ValueChanged<List<String>> onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) =>
        _StyleTagPickerContent(initialTags: currentTags, onChanged: onChanged),
  );
}

class _StyleTagPickerContent extends StatefulWidget {
  final List<String> initialTags;
  final ValueChanged<List<String>> onChanged;

  const _StyleTagPickerContent({
    required this.initialTags,
    required this.onChanged,
  });

  @override
  State<_StyleTagPickerContent> createState() => _StyleTagPickerContentState();
}

class _StyleTagPickerContentState extends State<_StyleTagPickerContent> {
  late final Set<String> _selected = {...widget.initialTags};

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final atLimit = _selected.length >= maxStyleTags;

    // Non-negotiable #5 grew AppChipActionButton's tap target from 36h to
    // 44h -- this sheet's Wrap of 8 chips now needs more room than a
    // fixed-height bottom sheet reliably gives it, so the tag list
    // scrolls independently of the sticky title/Done button.
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Style tags ($maxStyleTags max)',
            style: AppTypography.title.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final tag in availableStyleTags)
                    AppChipActionButton(
                      key: ValueKey('styleTagOption_$tag'),
                      label: tag,
                      selected: _selected.contains(tag),
                      onPressed: (!_selected.contains(tag) && atLimit)
                          ? null
                          : () => setState(() {
                              if (!_selected.remove(tag)) _selected.add(tag);
                            }),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            key: const ValueKey('styleTagPickerDone'),
            variant: AppButtonVariant.primary,
            label: 'Done',
            fullWidth: true,
            onPressed: () {
              widget.onChanged(_selected.toList());
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
