import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'app_icon_glyph.dart';
import 'app_icon_id.dart';
import 'app_icon_shapes.dart';

Path _propsPath() => roundedRectPath(const Rect.fromLTWH(6, 9, 12, 10), 4);
List<Path> _propsDetails() => [
  Path()
    ..moveTo(9, 9)
    ..lineTo(9, 5),
  Path()
    ..moveTo(12, 9)
    ..lineTo(12, 4),
  Path()
    ..moveTo(15, 9)
    ..lineTo(15, 5),
];

Path _shareArcPath() => unionOf([
  polygonPath([
    const Offset(12, 3),
    const Offset(16, 8),
    const Offset(13, 8),
    const Offset(13, 15),
    const Offset(11, 15),
    const Offset(11, 8),
    const Offset(8, 8),
  ]),
]);
List<Path> _shareArcDetails() => [
  Path()..addArc(const Rect.fromLTWH(5, 12, 14, 9), math.pi, math.pi),
];

Path _bookmarkPath() => polygonPath([
  const Offset(6, 3),
  const Offset(18, 3),
  const Offset(18, 21),
  const Offset(12, 15),
  const Offset(6, 21),
]);

final Map<AppIconId, AppIconGlyph> socialIconGlyphs = {
  AppIconId.heart: simpleGlyph(
    () => heartPath(const Rect.fromLTWH(4, 5, 16, 14)),
  ),
  AppIconId.props: simpleGlyph(_propsPath, details: _propsDetails),
  AppIconId.comment: simpleGlyph(
    () => speechBubblePath(const Rect.fromLTWH(3, 4, 18, 16)),
  ),
  AppIconId.shareArc: simpleGlyph(_shareArcPath, details: _shareArcDetails),
  AppIconId.bookmark: simpleGlyph(_bookmarkPath),
};
