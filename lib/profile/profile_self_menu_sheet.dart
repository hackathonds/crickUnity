import 'package:flutter/material.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';
import 'availability_sheet.dart';

/// The self-view profile-menu (⋮) -- DS §11.18: "Availability quick
/// toggle: profile-menu Availability sheet." Only one entry exists in
/// scope today; more self-only actions may land here in future stories.
Future<void> showProfileSelfMenuSheet({required BuildContext context}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MenuRow(
            key: const ValueKey('profileSelfMenuAvailability'),
            label: 'Availability',
            onTap: () {
              Navigator.of(sheetContext).pop();
              showAvailabilitySheet(context: context);
            },
          ),
        ],
      ),
    ),
  );
}

class _MenuRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MenuRow({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: AppTypography.body.copyWith(color: colors.textPrimary),
      ),
      onTap: onTap,
    );
  }
}
