import 'package:flutter/painting.dart';

import 'app_icon_glyph.dart';
import 'app_icon_id.dart';
import 'app_icon_shapes.dart';

Path _receiptPath() => polygonPath([
  const Offset(5, 3),
  const Offset(19, 3),
  const Offset(19, 21),
  const Offset(16, 19),
  const Offset(13, 21),
  const Offset(10, 19),
  const Offset(7, 21),
  const Offset(5, 19),
]);
List<Path> _receiptDetails() => [
  Path()
    ..moveTo(8, 8)
    ..lineTo(16, 8),
  Path()
    ..moveTo(8, 12)
    ..lineTo(16, 12),
];

Path _splitPath() => unionOf([
  roundedRectPath(const Rect.fromLTWH(11, 14, 2, 6), 1),
  polygonPath([
    const Offset(12, 14),
    const Offset(14, 14),
    const Offset(8, 4),
    const Offset(6, 4),
  ]),
  polygonPath([
    const Offset(12, 14),
    const Offset(10, 14),
    const Offset(16, 4),
    const Offset(18, 4),
  ]),
]);

Path _settleHandshakePath() => unionOf([
  polygonPath([
    const Offset(4, 18),
    const Offset(7, 18),
    const Offset(20, 6),
    const Offset(17, 6),
  ]),
  polygonPath([
    const Offset(20, 18),
    const Offset(17, 18),
    const Offset(4, 6),
    const Offset(7, 6),
  ]),
  circlePath(const Offset(12, 12), 1.8),
]);

Path _walletPath() => unionOf([
  roundedRectPath(const Rect.fromLTWH(4, 6, 16, 13), 2),
  roundedRectPath(const Rect.fromLTWH(14, 10, 6, 6), 1.5),
]);
List<Path> _walletDetails() => [
  Path()..addOval(const Rect.fromLTWH(16.5, 12, 1.6, 1.6)),
];

final Map<AppIconId, AppIconGlyph> expenseIconGlyphs = {
  AppIconId.receipt: simpleGlyph(_receiptPath, details: _receiptDetails),
  AppIconId.split: simpleGlyph(_splitPath),
  AppIconId.settleHandshake: simpleGlyph(_settleHandshakePath),
  AppIconId.wallet: simpleGlyph(_walletPath, details: _walletDetails),
  AppIconId.remindBell: simpleGlyph(
    () => bellPath(const Rect.fromLTWH(5, 3, 14, 17)),
  ),
};
