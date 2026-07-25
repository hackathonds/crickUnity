import 'package:flutter/painting.dart';

import 'app_icon_glyph.dart';
import 'app_icon_id.dart';
import 'app_icon_shapes.dart';

Path _homePath() => polygonPath([
  const Offset(4, 12),
  const Offset(12, 5),
  const Offset(20, 12),
  const Offset(20, 20),
  const Offset(4, 20),
]);

Path _matchesPath() {
  final bat = polygonPath([
    const Offset(15, 4),
    const Offset(18, 7),
    const Offset(9, 18),
    const Offset(6, 17),
    const Offset(7, 14),
  ]);
  final ball = circlePath(const Offset(18, 18), 3);
  return unionOf([bat, ball]);
}

Path _plusPath() => unionOf([
  roundedRectPath(const Rect.fromLTWH(10, 4, 4, 16), 1.5),
  roundedRectPath(const Rect.fromLTWH(4, 10, 16, 4), 1.5),
]);

Path _peoplePath() => unionOf([
  personPath(const Rect.fromLTWH(2, 5, 13, 15)),
  personPath(const Rect.fromLTWH(9, 5, 13, 15)),
]);

Path _avatarPath() => personPath(const Rect.fromLTWH(5, 4, 14, 17));

final Map<AppIconId, AppIconGlyph> navigationIconGlyphs = {
  AppIconId.home: simpleGlyph(_homePath),
  AppIconId.matches: simpleGlyph(_matchesPath),
  AppIconId.plus: simpleGlyph(_plusPath),
  AppIconId.people: simpleGlyph(_peoplePath),
  AppIconId.avatar: simpleGlyph(_avatarPath),
};
