import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_button.dart';

/// The "hex-soft" shape: a hexagon with rounded corners, DS §3.17's tile
/// silhouette at any size. Rounding is achieved by starting/ending each
/// edge short of its vertex and joining with a quadratic curve through
/// the vertex, rather than a sharp corner.
class _HexSoftClipper extends CustomClipper<Path> {
  const _HexSoftClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final corner = w * 0.14;

    final vertices = [
      Offset(w * 0.5, 0),
      Offset(w, h * 0.25),
      Offset(w, h * 0.75),
      Offset(w * 0.5, h),
      Offset(0, h * 0.75),
      Offset(0, h * 0.25),
    ];

    final path = Path();
    for (var i = 0; i < vertices.length; i++) {
      final prev = vertices[(i - 1 + vertices.length) % vertices.length];
      final curr = vertices[i];
      final next = vertices[(i + 1) % vertices.length];

      final fromPrev = (curr - prev);
      final toNext = (next - curr);
      final startPoint =
          curr - Offset.fromDirection(fromPrev.direction, corner);
      final endPoint = curr + Offset.fromDirection(toNext.direction, corner);

      if (i == 0) {
        path.moveTo(startPoint.dx, startPoint.dy);
      } else {
        path.lineTo(startPoint.dx, startPoint.dy);
      }
      path.quadraticBezierTo(curr.dx, curr.dy, endPoint.dx, endPoint.dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// DS §3.17 Badge Widget's tile: "Hex-soft tile 88 (grid) / 56 (strip);
/// earned = full color + engraved inner stroke; locked = 12% silhouette
/// + criteria on tap; tier ribbon bottom." `size` is 88 or 56 depending
/// on the grid/strip context the caller places it in.
class AppBadgeTile extends StatelessWidget {
  final String name;
  final Color color;
  final bool earned;
  final double size;
  final String? tierLabel;
  final VoidCallback? onTap;

  const AppBadgeTile({
    super.key,
    required this.name,
    required this.color,
    required this.earned,
    this.size = 88,
    this.tierLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    final tile = ClipPath(
      key: const ValueKey('appBadgeTileClip'),
      clipper: const _HexSoftClipper(),
      child: Container(
        width: size,
        height: size,
        color: earned ? color : color.withValues(alpha: 0.12),
        child: earned
            ? CustomPaint(
                key: const ValueKey('appBadgeTileEngravedStroke'),
                painter: _EngravedStrokePainter(),
                child: const SizedBox.expand(),
              )
            : null,
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size + (tierLabel != null ? 16 : 0),
        child: Column(
          children: [
            tile,
            if (tierLabel != null)
              Container(
                key: const ValueKey('appBadgeTileTierRibbon'),
                width: size * 0.7,
                height: 16,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.textPrimary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tierLabel!,
                  style: AppTypography.label.copyWith(
                    fontSize: 9,
                    color: colors.bg,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EngravedStrokePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = const _HexSoftClipper().getClip(size);
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.save();
    canvas.clipPath(path);
    canvas.translate(0, 1.5);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EngravedStrokePainter oldDelegate) => false;
}

/// DS §3.17's badge detail sheet content: "160 art, name Clash 20,
/// criteria, rarity %, 'friends who hold this' avatars, earn-date +
/// provenance link, Share." Meant to be passed as the `contentBuilder`
/// to `showAppBottomSheet` (`app_bottom_sheet.dart`) — this widget is
/// just the content, not a new sheet-opening mechanism.
class AppBadgeDetailContent extends StatelessWidget {
  final String name;
  final Color color;
  final String criteria;
  final int rarityPercent;
  final List<Widget> friendAvatars;
  final String earnDateAndProvenance;
  final VoidCallback? onShare;

  const AppBadgeDetailContent({
    super.key,
    required this.name,
    required this.color,
    required this.criteria,
    required this.rarityPercent,
    required this.earnDateAndProvenance,
    this.friendAvatars = const [],
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ClipPath(
              clipper: const _HexSoftClipper(),
              child: Container(width: 160, height: 160, color: color),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            name,
            // DS §3.17: "name Clash 20" -- Clash Display at 20px. No
            // named role matches this exactly (h2 is 20px but Inter, not
            // Clash), so it's composed directly at the point of use, same
            // precedent as AppTypography.moneyMin/moneyMax.
            style: TextStyle(
              fontFamily: AppTypography.displayFamily,
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            criteria,
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Rarity: $rarityPercent% of players',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
          if (friendAvatars.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Friends who hold this',
              style: AppTypography.label.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(children: friendAvatars),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            earnDateAndProvenance,
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (onShare != null)
            AppButton(
              variant: AppButtonVariant.secondary,
              label: 'Share',
              onPressed: onShare,
              fullWidth: true,
            ),
        ],
      ),
    );
  }
}
