import 'package:flutter/widgets.dart';

import 'app_icon_glyph.dart';
import 'app_icon_id.dart';
import 'app_icon_registry.dart';

/// Icon size variants — DS §2.5: "24×24 grid (20 for dense rows, 28 for tab
/// bar)".
abstract final class AppIconSize {
  static const double dense = 20;
  static const double standard = 24;
  static const double tabBar = 28;
}

/// DS §2.5's reference stroke width at the standard 24px grid; scales
/// proportionally at other sizes so the stroke-to-shape ratio stays
/// constant.
const double _referenceStrokeWidth = 1.75;

/// The stroke width an [AppIcon] of the given [size] renders with.
double resolveIconStrokeWidth(double size) =>
    _referenceStrokeWidth * (size / AppIconSize.standard);

/// Renders one glyph from the [appIconGlyphs] registry.
///
/// `semanticLabel` is required, not optional — DS §2.5: "icons never carry
/// meaning alone (label or accessible name always present)"; the API makes
/// that impossible to forget rather than relying on call-site discipline.
///
/// `active` selects the filled variant (DS §2.5's global rule:
/// outline = available, filled = active) — ignored for [AppIconId.coin],
/// which is always rendered the same multicolor way.
class AppIcon extends StatelessWidget {
  final AppIconId id;
  final String semanticLabel;
  final bool active;
  final double size;
  final Color color;

  const AppIcon({
    super.key,
    required this.id,
    required this.semanticLabel,
    this.active = false,
    this.size = AppIconSize.standard,
    this.color = const Color(0xFF000000),
  });

  @override
  Widget build(BuildContext context) {
    final glyph = appIconGlyphs[id];
    assert(glyph != null, 'No glyph registered for $id');

    return Semantics(
      label: semanticLabel,
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _AppIconPainter(
            glyph: glyph!,
            active: active,
            color: color,
            strokeWidth: resolveIconStrokeWidth(size),
          ),
        ),
      ),
    );
  }
}

class _AppIconPainter extends CustomPainter {
  final AppIconGlyph glyph;
  final bool active;
  final Color color;
  final double strokeWidth;

  _AppIconPainter({
    required this.glyph,
    required this.active,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (glyph.isMulticolor) {
      glyph.multicolor!(canvas, paint);
    } else if (active) {
      glyph.filled!(canvas, paint);
    } else {
      glyph.outline!(canvas, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AppIconPainter oldDelegate) {
    return oldDelegate.glyph != glyph ||
        oldDelegate.active != active ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
