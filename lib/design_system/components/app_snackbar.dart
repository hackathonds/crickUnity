import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// DS §3.20: bottom, above the nav bar by 8, 48h, r-sm, dark surface,
/// single action max, 5s, "queue max 1 (new replaces old)". Flutter's
/// `ScaffoldMessenger` queues snackbars by default rather than replacing —
/// `hideCurrentSnackBar()` right before showing the new one is what turns
/// that into a replace.
///
/// Not implemented: "persist while touched" (pausing the auto-dismiss timer
/// on interaction) — stock `SnackBar` has no hook for it; flagged as an
/// open question rather than faked.
void showAppSnackbar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      backgroundColor: AppColors.theme4.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: AppColors.theme4.primary,
              onPressed: onAction ?? () {},
            )
          : null,
    ),
  );
}
