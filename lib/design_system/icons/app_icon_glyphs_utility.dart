import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'app_icon_glyph.dart';
import 'app_icon_id.dart';
import 'app_icon_shapes.dart';

Path _searchPath() {
  final lens = pathWithHole(
    circlePath(const Offset(10, 10), 6),
    circlePath(const Offset(10, 10), 3.8),
  );
  final handle = polygonPath([
    const Offset(14.2, 14.2),
    const Offset(16, 12.4),
    const Offset(21, 17.4),
    const Offset(19.2, 19.2),
  ]);
  return unionOf([lens, handle]);
}

Path _micPath() => unionOf([
  roundedRectPath(const Rect.fromLTWH(9, 3, 6, 10), 3),
  roundedRectPath(const Rect.fromLTWH(11, 15, 2, 4), 1),
  roundedRectPath(const Rect.fromLTWH(7, 18.5, 10, 1.6), 0.8),
]);
List<Path> _micDetails() => [
  Path()..addArc(const Rect.fromLTWH(5, 8, 14, 10), 0, math.pi),
];

Path _qrCodePath() => pathWithHole(
  roundedRectPath(const Rect.fromLTWH(3, 3, 18, 18), 3),
  roundedRectPath(const Rect.fromLTWH(6, 6, 12, 12), 2),
);
List<Path> _qrCodeDetails() => [
  Path()..addRect(const Rect.fromLTWH(8, 8, 3, 3)),
  Path()..addRect(const Rect.fromLTWH(13, 8, 3, 3)),
  Path()..addRect(const Rect.fromLTWH(8, 13, 3, 3)),
];

Path _closePath() => unionOf([
  polygonPath([
    const Offset(5, 7),
    const Offset(7, 5),
    const Offset(19, 17),
    const Offset(17, 19),
  ]),
  polygonPath([
    const Offset(17, 5),
    const Offset(19, 7),
    const Offset(7, 19),
    const Offset(5, 17),
  ]),
]);

Path _backArrowPath() => unionOf([
  polygonPath([
    const Offset(11, 4),
    const Offset(13, 6),
    const Offset(7, 12),
    const Offset(13, 18),
    const Offset(11, 20),
    const Offset(3, 12),
  ]),
  roundedRectPath(const Rect.fromLTWH(7, 10.8, 14, 2.4), 1.2),
]);

final Map<AppIconId, AppIconGlyph> utilityIconGlyphs = {
  AppIconId.search: simpleGlyph(_searchPath),
  AppIconId.mic: simpleGlyph(_micPath, details: _micDetails),
  AppIconId.qrCode: simpleGlyph(_qrCodePath, details: _qrCodeDetails),
  AppIconId.close: simpleGlyph(_closePath),
  AppIconId.backArrow: simpleGlyph(_backArrowPath),
};
