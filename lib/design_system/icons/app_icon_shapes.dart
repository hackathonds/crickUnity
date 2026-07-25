import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Small reusable path-building primitives the 34 glyph definitions compose
/// from, all operating in the shared 24×24 logical grid.
Path circlePath(Offset center, double radius) =>
    Path()..addOval(Rect.fromCircle(center: center, radius: radius));

Path roundedRectPath(Rect rect, double radius) =>
    Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

/// A path with an inner hole punched via the even-odd fill rule — the hole
/// still reads as empty space even when the glyph is solid-filled.
Path pathWithHole(Path outer, Path hole) {
  return Path()
    ..fillType = PathFillType.evenOdd
    ..addPath(outer, Offset.zero)
    ..addPath(hole, Offset.zero);
}

Path unionOf(List<Path> parts) {
  return parts.reduce((a, b) => Path.combine(PathOperation.union, a, b));
}

Path polygonPath(List<Offset> points) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (final point in points.skip(1)) {
    path.lineTo(point.dx, point.dy);
  }
  return path..close();
}

/// A classic heart silhouette inscribed in [rect].
Path heartPath(Rect rect) {
  final w = rect.width;
  final h = rect.height;
  final left = rect.left;
  final top = rect.top;
  final path = Path();
  path.moveTo(left + w * 0.5, top + h * 0.92);
  path.cubicTo(
    left - w * 0.1,
    top + h * 0.55,
    left + w * 0.05,
    top + h * 0.05,
    left + w * 0.5,
    top + h * 0.3,
  );
  path.cubicTo(
    left + w * 0.95,
    top + h * 0.05,
    left + w * 1.1,
    top + h * 0.55,
    left + w * 0.5,
    top + h * 0.92,
  );
  return path..close();
}

/// A rounded speech-bubble silhouette with a small tail.
Path speechBubblePath(Rect rect) {
  final bubble = roundedRectPath(
    Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.75),
    rect.width * 0.22,
  );
  final tail = polygonPath([
    Offset(rect.left + rect.width * 0.22, rect.top + rect.height * 0.72),
    Offset(rect.left + rect.width * 0.4, rect.top + rect.height * 0.72),
    Offset(rect.left + rect.width * 0.22, rect.top + rect.height * 0.95),
  ]);
  return unionOf([bubble, tail]);
}

/// A bell silhouette (dome + base + small clapper) inscribed in [rect].
Path bellPath(Rect rect) {
  final domeRect = Rect.fromLTWH(
    rect.left + rect.width * 0.12,
    rect.top,
    rect.width * 0.76,
    rect.height * 0.7,
  );
  final dome = Path()
    ..moveTo(domeRect.left, domeRect.bottom)
    ..arcTo(domeRect, math.pi, math.pi, false)
    ..lineTo(domeRect.right, domeRect.bottom)
    ..close();
  final base = roundedRectPath(
    Rect.fromLTWH(
      rect.left,
      rect.top + rect.height * 0.66,
      rect.width,
      rect.height * 0.12,
    ),
    2,
  );
  final clapper = circlePath(
    Offset(rect.center.dx, rect.top + rect.height * 0.92),
    rect.width * 0.08,
  );
  return unionOf([dome, base, clapper]);
}

/// A trophy cup silhouette (bowl + handles + stem + base).
Path trophyPath(Rect rect) {
  final bowlRect = Rect.fromLTWH(
    rect.left + rect.width * 0.2,
    rect.top,
    rect.width * 0.6,
    rect.height * 0.55,
  );
  final bowl = Path()
    ..moveTo(bowlRect.left, bowlRect.top)
    ..lineTo(bowlRect.right, bowlRect.top)
    ..lineTo(bowlRect.center.dx + bowlRect.width * 0.22, bowlRect.bottom)
    ..lineTo(bowlRect.center.dx - bowlRect.width * 0.22, bowlRect.bottom)
    ..close();
  final leftHandle = Path()
    ..addArc(
      Rect.fromLTWH(
        rect.left - rect.width * 0.05,
        rect.top + rect.height * 0.05,
        rect.width * 0.3,
        rect.height * 0.3,
      ),
      math.pi * 0.3,
      math.pi * 1.1,
    );
  final rightHandle = Path()
    ..addArc(
      Rect.fromLTWH(
        rect.right - rect.width * 0.25,
        rect.top + rect.height * 0.05,
        rect.width * 0.3,
        rect.height * 0.3,
      ),
      math.pi * 1.6,
      math.pi * 1.1,
    );
  final stem = roundedRectPath(
    Rect.fromLTWH(
      rect.center.dx - rect.width * 0.06,
      rect.top + rect.height * 0.55,
      rect.width * 0.12,
      rect.height * 0.22,
    ),
    1,
  );
  final base = roundedRectPath(
    Rect.fromLTWH(
      rect.left + rect.width * 0.22,
      rect.top + rect.height * 0.82,
      rect.width * 0.56,
      rect.height * 0.12,
    ),
    2,
  );
  return unionOf([bowl, leftHandle, rightHandle, stem, base]);
}

/// A lightning-bolt zigzag silhouette.
Path boltPath(Rect rect) {
  return polygonPath([
    Offset(rect.left + rect.width * 0.55, rect.top),
    Offset(rect.left + rect.width * 0.2, rect.top + rect.height * 0.58),
    Offset(rect.left + rect.width * 0.45, rect.top + rect.height * 0.58),
    Offset(rect.left + rect.width * 0.35, rect.top + rect.height),
    Offset(rect.left + rect.width * 0.8, rect.top + rect.height * 0.38),
    Offset(rect.left + rect.width * 0.55, rect.top + rect.height * 0.38),
  ]);
}

/// A simple person silhouette (head + shoulders) inscribed in [rect].
Path personPath(Rect rect) {
  final head = circlePath(
    Offset(rect.center.dx, rect.top + rect.height * 0.28),
    rect.width * 0.22,
  );
  final shouldersRect = Rect.fromLTWH(
    rect.left,
    rect.top + rect.height * 0.55,
    rect.width,
    rect.height * 0.45,
  );
  final shoulders = Path()
    ..addArc(
      Rect.fromLTWH(
        shouldersRect.left,
        shouldersRect.top,
        shouldersRect.width,
        shouldersRect.height * 2,
      ),
      math.pi,
      math.pi,
    );
  return unionOf([head, shoulders]);
}
