import 'package:flutter/material.dart';

import '../components/app_bottom_sheet.dart';
import '../components/app_dialog.dart';
import '../components/app_snackbar.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// QA tool for E0-05's primitives: sheet detents + unsaved-input guard,
/// confirm/typed-confirm dialogs, and the replace-not-queue snackbar.
class SheetDialogSnackbarScreen extends StatelessWidget {
  const SheetDialogSnackbarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Sheet / dialog / snackbar (QA)')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Bottom sheet',
            style: AppTypography.h2.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            onPressed: () => showAppBottomSheet<void>(
              context: context,
              title: 'No unsaved input',
              contentBuilder: (context) => Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Drag this below peek — it just dismisses.',
                  style: AppTypography.body,
                ),
              ),
            ),
            child: const Text('Open sheet (no unsaved input)'),
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            onPressed: () => showAppBottomSheet<void>(
              context: context,
              title: 'Edit draft',
              hasUnsavedInput: true,
              contentBuilder: (context) => Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Draft text (unsaved)',
                  ),
                  onChanged: (_) {},
                ),
              ),
            ),
            child: const Text('Open sheet (with unsaved input)'),
          ),
          const Divider(height: AppSpacing.xxl),
          Text(
            'Dialogs',
            style: AppTypography.h2.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            onPressed: () => showAppConfirmDialog(
              context: context,
              title: 'Leave team?',
              body: 'You can rejoin later if the captain approves.',
            ),
            child: const Text('Open confirm dialog'),
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            onPressed: () => showAppTypedConfirmDialog(
              context: context,
              title: 'Delete team',
              body: 'This cannot be undone. Type DELETE to confirm.',
              confirmPhrase: 'DELETE',
              destructiveLabel: 'Delete team',
            ),
            child: const Text('Open typed-confirm dialog'),
          ),
          const Divider(height: AppSpacing.xxl),
          Text(
            'Snackbar',
            style: AppTypography.h2.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            onPressed: () => showAppSnackbar(context, 'Saved'),
            child: const Text('Show snackbar'),
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            onPressed: () => showAppSnackbar(
              context,
              'Item removed',
              actionLabel: 'UNDO',
              onAction: () {},
            ),
            child: const Text('Show snackbar with action'),
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            onPressed: () {
              showAppSnackbar(context, 'First message');
              showAppSnackbar(context, 'Second message replaces it');
            },
            child: const Text('Show two snackbars back to back'),
          ),
        ],
      ),
    );
  }
}
