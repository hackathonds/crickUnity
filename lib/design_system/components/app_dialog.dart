import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// DS §3.21: "One dialog at a time, ever." A second call while one is
/// already open is a no-op — not queued, not replaced.
bool _dialogOpen = false;

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  if (_dialogOpen) return Future<T?>.value();
  _dialogOpen = true;
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: builder,
  ).whenComplete(() => _dialogOpen = false);
}

/// A plain confirm dialog (DS §3.21): max width 320, actions right-aligned
/// (Tertiary + Primary).
Future<bool?> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String body,
  String cancelLabel = 'Cancel',
  String confirmLabel = 'Confirm',
}) {
  return showAppDialog<bool>(
    context: context,
    builder: (context) => AppConfirmDialog(
      title: title,
      body: body,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
    ),
  );
}

/// A destructive/irreversible-action dialog (DS §3.21): the *safe* action
/// is Primary-styled; the destructive action is Tertiary-styled and stays
/// disabled until the user types [confirmPhrase] exactly.
Future<bool?> showAppTypedConfirmDialog({
  required BuildContext context,
  required String title,
  required String body,
  required String confirmPhrase,
  String destructiveLabel = 'Delete',
  String safeLabel = 'Cancel',
}) {
  return showAppDialog<bool>(
    context: context,
    builder: (context) => AppTypedConfirmDialog(
      title: title,
      body: body,
      confirmPhrase: confirmPhrase,
      destructiveLabel: destructiveLabel,
      safeLabel: safeLabel,
    ),
  );
}

class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String body;
  final String cancelLabel;
  final String confirmLabel;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.body,
    this.cancelLabel = 'Cancel',
    this.confirmLabel = 'Confirm',
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return AppDialogShell(
      colors: colors,
      title: title,
      body: body,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

class AppTypedConfirmDialog extends StatefulWidget {
  final String title;
  final String body;
  final String confirmPhrase;
  final String destructiveLabel;
  final String safeLabel;

  const AppTypedConfirmDialog({
    super.key,
    required this.title,
    required this.body,
    required this.confirmPhrase,
    this.destructiveLabel = 'Delete',
    this.safeLabel = 'Cancel',
  });

  @override
  State<AppTypedConfirmDialog> createState() => _AppTypedConfirmDialogState();
}

class _AppTypedConfirmDialogState extends State<AppTypedConfirmDialog> {
  final _controller = TextEditingController();
  bool _matches = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final matches = _controller.text == widget.confirmPhrase;
      if (matches != _matches) setState(() => _matches = matches);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return AppDialogShell(
      colors: colors,
      title: widget.title,
      body: widget.body,
      extra: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Type "${widget.confirmPhrase}" to confirm',
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(widget.safeLabel),
        ),
        TextButton(
          onPressed: _matches ? () => Navigator.of(context).pop(true) : null,
          child: Text(widget.destructiveLabel),
        ),
      ],
    );
  }
}

class AppDialogShell extends StatelessWidget {
  final AppColors colors;
  final String title;
  final String body;
  final Widget? extra;
  final List<Widget> actions;

  const AppDialogShell({
    super.key,
    required this.colors,
    required this.title,
    required this.body,
    required this.actions,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.title.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                body,
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              ),
              ?extra,
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    actions[i],
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
