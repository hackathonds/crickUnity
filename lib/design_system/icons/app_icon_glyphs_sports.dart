import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'app_icon_glyph.dart';
import 'app_icon_id.dart';
import 'app_icon_shapes.dart';

Path _batPath() => unionOf([
  roundedRectPath(const Rect.fromLTWH(11, 3, 3, 8), 1.5),
  roundedRectPath(const Rect.fromLTWH(8.5, 10, 8, 11), 3),
]);

Path _ballPath() => circlePath(const Offset(12, 12), 7);
List<Path> _ballDetails() => [
  Path()
    ..addArc(const Rect.fromLTWH(7, 7, 10, 10), -math.pi * 0.7, math.pi * 0.9),
  Path()
    ..addArc(const Rect.fromLTWH(7, 7, 10, 10), math.pi * 0.3, math.pi * 0.9),
];

Path _stumpsPath() => unionOf([
  roundedRectPath(const Rect.fromLTWH(5, 6, 2.2, 15), 1),
  roundedRectPath(const Rect.fromLTWH(11, 6, 2.2, 15), 1),
  roundedRectPath(const Rect.fromLTWH(17, 6, 2.2, 15), 1),
  roundedRectPath(const Rect.fromLTWH(4, 4, 16, 2.2), 1),
]);

Path _glovesPath() => unionOf([
  roundedRectPath(const Rect.fromLTWH(6, 8, 12, 12), 5),
  circlePath(const Offset(6, 10), 3),
]);

Path _helmetPath() {
  final domeRect = const Rect.fromLTWH(4, 4, 16, 14);
  return Path()
    ..moveTo(domeRect.left, domeRect.bottom)
    ..arcTo(domeRect, math.pi, math.pi, false)
    ..lineTo(domeRect.right, domeRect.bottom)
    ..close();
}

List<Path> _helmetDetails() => [
  Path()
    ..moveTo(9, 12)
    ..lineTo(9, 18),
  Path()
    ..moveTo(12, 12)
    ..lineTo(12, 18),
  Path()
    ..moveTo(15, 12)
    ..lineTo(15, 18),
];

Path _whistlePath() {
  final body = Path()..addOval(const Rect.fromLTWH(4, 8, 13, 10));
  final stem = roundedRectPath(const Rect.fromLTWH(16, 11, 5, 4), 1.5);
  final hole = Path()..addOval(const Rect.fromLTWH(8.5, 11.5, 4, 4));
  return pathWithHole(unionOf([body, stem]), hole);
}

Path _scorebookPath() => roundedRectPath(const Rect.fromLTWH(4, 3, 16, 18), 2);
List<Path> _scorebookDetails() => [
  Path()
    ..moveTo(7, 8)
    ..lineTo(17, 8),
  Path()
    ..moveTo(7, 12)
    ..lineTo(17, 12),
  Path()
    ..moveTo(7, 16)
    ..lineTo(14, 16),
];

Path _pitchPath() => roundedRectPath(const Rect.fromLTWH(9, 2, 6, 20), 2);
List<Path> _pitchDetails() => [
  Path()..addOval(const Rect.fromLTWH(10.5, 11, 3, 3)),
];

final Map<AppIconId, AppIconGlyph> sportsIconGlyphs = {
  AppIconId.bat: simpleGlyph(_batPath),
  AppIconId.ball: simpleGlyph(_ballPath, details: _ballDetails),
  AppIconId.stumps: simpleGlyph(_stumpsPath),
  AppIconId.gloves: simpleGlyph(_glovesPath),
  AppIconId.helmet: simpleGlyph(_helmetPath, details: _helmetDetails),
  AppIconId.whistle: simpleGlyph(_whistlePath),
  AppIconId.scorebook: simpleGlyph(_scorebookPath, details: _scorebookDetails),
  AppIconId.trophy: simpleGlyph(
    () => trophyPath(const Rect.fromLTWH(3, 3, 18, 18)),
  ),
  AppIconId.pitch: simpleGlyph(_pitchPath, details: _pitchDetails),
};
