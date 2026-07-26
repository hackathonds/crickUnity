import 'package:flutter/painting.dart';

import 'app_icon_glyph.dart';
import 'app_icon_id.dart';

/// DS §11.5's Trust band chip glyph -- not in the base §2.5 icon set,
/// added for the Addendum's new component same as other §11-only
/// primitives this session (badge tile, calendar, leaderboard row).
Path _shieldPath() => Path()
  ..moveTo(12, 3)
  ..lineTo(19, 6)
  ..lineTo(19, 12)
  ..cubicTo(19, 17, 16, 20, 12, 21.5)
  ..cubicTo(8, 20, 5, 17, 5, 12)
  ..lineTo(5, 6)
  ..close();

final Map<AppIconId, AppIconGlyph> trustIconGlyphs = {
  AppIconId.shield: simpleGlyph(_shieldPath),
};
