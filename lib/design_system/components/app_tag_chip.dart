import 'package:flutter/material.dart';

import '../icons/app_icon.dart';
import '../icons/app_icon_id.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// The static tag/status chip family — DS §2.2's radius table lists r-xs 6
/// for "chips, tags" as a separate entry from Chip-action's r-full
/// ([AppChipActionButton] in `app_button.dart`), confirming these are two
/// distinct components. This one is informational only — no press state,
/// no `onPressed`. Covers role chips (§3.2.1), format tag chips (§3.2.2),
/// sanctioned/verified chips (§3.2.4), and warning/error status chips
/// (§3.2.5) — the caller composes the label text (e.g. "7d overdue").
enum AppTagChipVariant { neutral, verified, success, warning, error }

class AppTagChip extends StatelessWidget {
  final String label;
  final AppTagChipVariant variant;
  final AppIconId? icon;

  const AppTagChip({
    super.key,
    required this.label,
    this.variant = AppTagChipVariant.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    final Color foreground = switch (variant) {
      AppTagChipVariant.neutral => colors.textSecondary,
      AppTagChipVariant.verified => colors.verified,
      AppTagChipVariant.success => colors.success,
      AppTagChipVariant.warning => colors.warning,
      AppTagChipVariant.error => colors.error,
    };
    final Color background = variant == AppTagChipVariant.neutral
        ? colors.surfaceAlt
        : foreground.withValues(alpha: 0.12);

    return Container(
      key: const ValueKey('appTagChipSurface'),
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.xsRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            AppIcon(
              id: icon!,
              semanticLabel: label,
              color: foreground,
              size: 14,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTypography.label.copyWith(color: foreground),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// DS §3.2.9's trend-arrow pattern: "▲ success / ▼ textTertiary — down is
/// neutral, not red, except money surfaces." The down-arrow's money-surface
/// exception has no described usage anywhere in the frozen docs yet (PR
/// open question) — this implements only the documented stats-card case.
enum AppDeltaDirection { up, down }

class AppDeltaChip extends StatelessWidget {
  final String value;
  final AppDeltaDirection direction;

  const AppDeltaChip({super.key, required this.value, required this.direction});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final foreground = direction == AppDeltaDirection.up
        ? colors.success
        : colors.textTertiary;
    final glyph = direction == AppDeltaDirection.up ? '▲' : '▼';

    return Container(
      key: const ValueKey('appDeltaChipSurface'),
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.12),
        borderRadius: AppRadius.xsRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            glyph,
            style: AppTypography.label.copyWith(
              color: foreground,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.label.copyWith(color: foreground),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
