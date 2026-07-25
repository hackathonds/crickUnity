import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../tokens/app_colors.dart';
import 'app_icon_glyph.dart';
import 'app_icon_id.dart';
import 'app_icon_shapes.dart';

/// DS §2.5: "the coin icon is the *only* multicolor icon" — always the
/// metallic amber disc with a "C" cutout, regardless of outline/filled
/// state or the caller's requested color.
void _coinPainter(Canvas canvas, Paint paint) {
  final baseColor = AppColors.theme1.coin;
  final rimColor = Color.lerp(baseColor, const Color(0xFF000000), 0.25)!;

  canvas.drawPath(
    circlePath(const Offset(12, 12), 9),
    Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill,
  );

  final ring = Path.combine(
    PathOperation.difference,
    circlePath(const Offset(12, 12), 5.5),
    circlePath(const Offset(12, 12), 3.2),
  );
  final wedge = polygonPath([
    const Offset(12, 12),
    const Offset(20, 7.5),
    const Offset(20, 16.5),
  ]);
  final cutC = Path.combine(PathOperation.difference, ring, wedge);
  canvas.drawPath(
    cutC,
    Paint()
      ..color = rimColor
      ..style = PaintingStyle.fill,
  );
}

Path _xpBoltPath() => boltPath(const Rect.fromLTWH(4, 2, 16, 20));

Path _chestPath() => unionOf([
  roundedRectPath(const Rect.fromLTWH(4, 11, 16, 9), 2),
  roundedRectPath(const Rect.fromLTWH(4, 6, 16, 6), 2),
  circlePath(const Offset(12, 12), 1.4),
]);
List<Path> _chestDetails() => [
  Path()
    ..moveTo(4, 11.5)
    ..lineTo(20, 11.5),
];

Path _spinPath() {
  final arrow = Path()
    ..addArc(const Rect.fromLTWH(4, 4, 16, 16), -math.pi * 0.15, math.pi * 1.5);
  final head = polygonPath([
    const Offset(17, 5),
    const Offset(20.5, 6.5),
    const Offset(17.5, 9),
  ]);
  return unionOf([arrow, head]);
}

Path _scratchPath() => roundedRectPath(const Rect.fromLTWH(4, 5, 16, 14), 2.5);
List<Path> _scratchDetails() => [
  Path()
    ..moveTo(8, 18)
    ..lineTo(12, 8),
  Path()
    ..moveTo(12, 18)
    ..lineTo(16, 8),
];

final Map<AppIconId, AppIconGlyph> rewardsIconGlyphs = {
  AppIconId.coin: AppIconGlyph.multicolorGlyph(_coinPainter),
  AppIconId.xpBolt: simpleGlyph(_xpBoltPath),
  AppIconId.chest: simpleGlyph(_chestPath, details: _chestDetails),
  AppIconId.spin: simpleGlyph(_spinPath),
  AppIconId.scratch: simpleGlyph(_scratchPath, details: _scratchDetails),
};
