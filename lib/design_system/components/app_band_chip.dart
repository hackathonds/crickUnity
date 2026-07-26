import 'package:flutter/material.dart';

import '../icons/app_icon.dart';
import '../icons/app_icon_id.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

enum BandKind { trust, sportsmanship }

/// DS §11.5: "24h pill, band name + micro-glyph (shield=Trust,
/// handshake=Sportsmanship); colors: neutral slate ramps only (never
/// success/error — bands aren't judgments of the viewer's worth);
/// 'Under review' = warning-outline."
///
/// Deliberately takes a plain [label] string, never a number -- this
/// component has no numeric-score field to render by construction (the
/// backlog AC: "raw scores never rendered").
class AppBandChip extends StatelessWidget {
  final BandKind kind;
  final String label;
  final bool isUnderReview;
  final VoidCallback? onTap;

  const AppBandChip({
    super.key,
    required this.kind,
    required this.label,
    this.isUnderReview = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final borderColor = isUnderReview ? colors.warning : colors.border;

    final chip = Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: AppRadius.fullRadius,
        border: Border.all(color: borderColor, width: isUnderReview ? 1.5 : 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            id: kind == BandKind.trust
                ? AppIconId.shield
                : AppIconId.settleHandshake,
            semanticLabel: kind == BandKind.trust
                ? 'Trust band'
                : 'Sportsmanship band',
            color: colors.textSecondary,
            size: 14,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.label.copyWith(color: colors.textPrimary),
          ),
        ],
      ),
    );

    if (onTap == null) return chip;
    return Semantics(
      button: true,
      label: '$label, tap for breakdown',
      child: GestureDetector(onTap: onTap, child: chip),
    );
  }
}
