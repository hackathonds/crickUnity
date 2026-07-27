import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';

/// DS §11.9 "Sponsored rendering rules (global)": "sponsor logo slots
/// are fixed-size reserved zones (team header 88x28, match card footer
/// 72x20, stream lower-third), always with 'Sponsored' microlabel 10,
/// never animated, never in feed posts (PRD rule)." One shared widget
/// for every sponsored surface so the fixed sizing and non-negotiable
/// "Sponsored" microlabel can never drift between call sites.
enum SponsoredZoneSize { teamHeader, matchCardFooter, streamLowerThird }

const Map<SponsoredZoneSize, Size> _zoneSizes = {
  SponsoredZoneSize.teamHeader: Size(88, 28),
  SponsoredZoneSize.matchCardFooter: Size(72, 20),
  SponsoredZoneSize.streamLowerThird: Size(96, 28),
};

class AppSponsoredBadge extends StatelessWidget {
  final String sponsorName;
  final SponsoredZoneSize zone;

  const AppSponsoredBadge({
    super.key,
    required this.sponsorName,
    required this.zone,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final size = _zoneSizes[zone]!;

    return Container(
      width: size.width,
      height: size.height,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sponsored',
            style: const TextStyle(
              fontFamily: AppTypography.bodyFamily,
              fontSize: 10,
            ).copyWith(color: colors.textTertiary),
          ),
          Text(
            sponsorName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
