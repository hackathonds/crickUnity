import 'package:flutter/painting.dart';

import 'app_icon_glyph.dart';
import 'app_icon_id.dart';
import 'app_icon_shapes.dart';

Path _livePath() => circlePath(const Offset(12, 12), 6);

Path _verifiedCheckPath() {
  final seal = circlePath(const Offset(12, 12), 8);
  final check = polygonPath([
    const Offset(8, 12.5),
    const Offset(10.5, 15),
    const Offset(16, 8.5),
    const Offset(16, 10.5),
    const Offset(10.5, 17),
    const Offset(8, 14.5),
  ]);
  return Path.combine(PathOperation.difference, seal, check);
}

Path _pendingClockPath() => circlePath(const Offset(12, 12), 8);
List<Path> _pendingClockDetails() => [
  Path()
    ..moveTo(12, 12)
    ..lineTo(12, 7),
  Path()
    ..moveTo(12, 12)
    ..lineTo(16, 13),
];

Path _lockedPath() {
  final body = roundedRectPath(const Rect.fromLTWH(6, 11, 12, 10), 2);
  final shackle = Path()..addArc(const Rect.fromLTWH(8, 4, 8, 10), 3.4, 2.9);
  final keyhole = circlePath(const Offset(12, 15.5), 1.6);
  return pathWithHole(unionOf([body, shackle]), keyhole);
}

Path _syncedOfflineCloudPath() => unionOf([
  circlePath(const Offset(9, 13), 4),
  circlePath(const Offset(14, 11), 5),
  roundedRectPath(const Rect.fromLTWH(5, 13, 15, 6), 3),
]);

final Map<AppIconId, AppIconGlyph> statusIconGlyphs = {
  AppIconId.live: simpleGlyph(_livePath),
  AppIconId.verifiedCheck: simpleGlyph(_verifiedCheckPath),
  AppIconId.pendingClock: simpleGlyph(
    _pendingClockPath,
    details: _pendingClockDetails,
  ),
  AppIconId.locked: simpleGlyph(_lockedPath),
  AppIconId.syncedOfflineCloud: simpleGlyph(_syncedOfflineCloudPath),
};
