import 'package:flutter/material.dart';

import '../../offline/queued_action.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// The visual pill for one [QueuedAction] — PRD §4's queued-action pattern.
/// Backgrounds stay neutral across every status (DS Pillar 4: no
/// gamification color); only the icon/text accent semantically
/// (success/error), never the `coin`/amber palette.
class AppPendingPill extends StatelessWidget {
  final QueuedAction action;
  final VoidCallback? onRetry;

  const AppPendingPill({super.key, required this.action, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    final Widget leading;
    final Color textColor;
    switch (action.status) {
      case QueuedActionStatus.pending:
        leading = SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.textSecondary,
          ),
        );
        textColor = colors.textSecondary;
      case QueuedActionStatus.success:
        leading = Icon(Icons.check_circle, size: 16, color: colors.success);
        textColor = colors.success;
      case QueuedActionStatus.error:
        leading = Icon(Icons.error_outline, size: 16, color: colors.error);
        textColor = colors.error;
    }

    return Container(
      key: ValueKey('pendingPill-${action.id}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: AppRadius.fullRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              action.label,
              style: AppTypography.caption.copyWith(color: textColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (action.status == QueuedActionStatus.error && onRetry != null) ...[
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 44),
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
