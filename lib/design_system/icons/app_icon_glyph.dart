import 'package:flutter/painting.dart' show Canvas, Paint, Path, PaintingStyle;

/// A hand-drawn icon glyph, operating in a 24×24 logical coordinate space
/// (the [AppIcon] widget scales the canvas to the requested size before
/// invoking these painters — DS §2.5's 24-grid, 20/28 size variants).
///
/// **Detail simplification convention:** every non-coin glyph is built from
/// one silhouette [Path] (used as the fill in the "filled/active" state)
/// plus optional thin "detail" accents (seams, grille lines, ruled lines)
/// that only render in the "outline/available" state. This keeps outline
/// vs. filled mechanically consistent across all 33 glyphs instead of a
/// bespoke rule per icon — a deliberate placeholder simplification pending
/// real design assets (see PR open questions).
typedef IconPainterFn = void Function(Canvas canvas, Paint paint);

class AppIconGlyph {
  final IconPainterFn? outline;
  final IconPainterFn? filled;

  /// True only for `coin` — DS §2.5: "the coin icon is the *only*
  /// multicolor icon." Multicolor glyphs ignore the caller's [Paint] color
  /// and paint themselves.
  final bool isMulticolor;
  final IconPainterFn? multicolor;

  const AppIconGlyph({this.outline, this.filled, this.multicolor})
    : isMulticolor = false;

  const AppIconGlyph.multicolorGlyph(this.multicolor)
    : outline = null,
      filled = null,
      isMulticolor = true;
}

/// Builds a standard outline/filled pair from a single silhouette path
/// (reused as both the stroke outline and the solid fill) plus optional
/// detail-only accents shown in the outline state.
AppIconGlyph simpleGlyph(
  Path Function() silhouette, {
  List<Path> Function()? details,
}) {
  return AppIconGlyph(
    outline: (canvas, paint) {
      final p = Paint()
        ..color = paint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = paint.strokeWidth
        ..strokeCap = paint.strokeCap
        ..strokeJoin = paint.strokeJoin;
      canvas.drawPath(silhouette(), p);
      for (final d in details?.call() ?? const <Path>[]) {
        canvas.drawPath(d, p);
      }
    },
    filled: (canvas, paint) {
      final p = Paint()
        ..color = paint.color
        ..style = PaintingStyle.fill;
      canvas.drawPath(silhouette(), p);
    },
  );
}
