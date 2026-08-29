import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// One lit star: which win it represents, and where it sits in the
/// constellation's normalized (0..1) coordinate space.
class ConstellationStar {
  const ConstellationStar({required this.winId, required this.position});

  final int winId;
  final Offset position;
}

/// Renders a small white radial-gradient glow once and caches it as a
/// [ui.Image], so [ConstellationPainter] can batch-draw hundreds of stars
/// with a single `canvas.drawAtlas()` call (tinted per-star via its
/// `colors` argument) instead of paying for a blurred [Paint] per star.
Future<ui.Image> buildGlowSprite({double size = 48}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final center = Offset(size / 2, size / 2);
  final paint = Paint()
    ..shader = ui.Gradient.radial(center, size / 2, [
      Colors.white,
      Colors.white.withValues(alpha: 0),
    ]);
  canvas.drawCircle(center, size / 2, paint);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  picture.dispose();
  return image;
}

class ConstellationPainter extends CustomPainter {
  const ConstellationPainter({
    required this.stars,
    required this.glowSprite,
    required this.revision,
    required this.starColor,
    required this.coreColor,
    this.edges = const [],
    this.linkThreshold = 0,
  });

  final List<ConstellationStar> stars;
  final ui.Image? glowSprite;

  /// Passed in rather than read from a static palette — a [CustomPainter]
  /// has no [BuildContext], and these must follow the active light/dark
  /// theme.
  final Color starColor;
  final Color coreColor;

  /// Which pairs of [stars] (by index) get a connecting line — built by
  /// `buildConstellationLayout`, so this can branch (a figure's arms and
  /// legs, a teapot's handle) instead of being a single path or loop.
  final List<(int, int)> edges;

  /// No lines are drawn at all until [stars] reaches this many — a
  /// project's constellation shows loose, unlinked stars until its full
  /// base graph (the shape's keypoints) is lit.
  final int linkThreshold;

  /// Bumped by the caller whenever [stars] actually changes (a win was
  /// added/edited or the screen reloaded) — deliberately NOT a deep list
  /// comparison, so pan/zoom gesture frames never trigger a repaint.
  final int revision;

  static const _sparkleRadius = 5.5;

  @override
  void paint(Canvas canvas, Size size) {
    final sprite = glowSprite;
    if (sprite == null || stars.isEmpty) return;

    if (stars.length >= linkThreshold && linkThreshold > 0) {
      final linePaint = Paint()
        ..color = starColor.withValues(alpha: 0.35)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      for (final (a, b) in edges) {
        if (a >= stars.length || b >= stars.length) continue;
        canvas.drawLine(
          _toCanvas(stars[a].position, size),
          _toCanvas(stars[b].position, size),
          linePaint,
        );
      }
    }

    final srcRect = Rect.fromLTWH(
      0,
      0,
      sprite.width.toDouble(),
      sprite.height.toDouble(),
    );
    final transforms = <RSTransform>[];
    final srcRects = <Rect>[];
    final colors = <Color>[];

    for (final star in stars) {
      final center = _toCanvas(star.position, size);
      transforms.add(
        RSTransform.fromComponents(
          rotation: 0,
          scale: 1,
          anchorX: sprite.width / 2,
          anchorY: sprite.height / 2,
          translateX: center.dx,
          translateY: center.dy,
        ),
      );
      srcRects.add(srcRect);
      colors.add(starColor);
    }

    canvas.drawAtlas(
      sprite,
      transforms,
      srcRects,
      colors,
      BlendMode.modulate,
      null,
      Paint(),
    );

    final sparkle = _sparklePath(_sparkleRadius);
    final corePaint = Paint()..color = coreColor;
    for (final star in stars) {
      final center = _toCanvas(star.position, size);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.drawPath(sparkle, corePaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConstellationPainter oldDelegate) {
    return revision != oldDelegate.revision ||
        glowSprite != oldDelegate.glowSprite ||
        starColor != oldDelegate.starColor ||
        coreColor != oldDelegate.coreColor ||
        stars.length != oldDelegate.stars.length;
  }
}

/// A small four-pointed "twinkle" sparkle (like ✦), pinched to a narrow
/// waist at the center — reads clearly at star size, unlike a filled
/// diamond or a rounder shape which just blurs into a dot.
Path _sparklePath(double radius) {
  final waist = radius * 0.28;
  return Path()
    ..moveTo(0, -radius)
    ..quadraticBezierTo(waist, -waist, radius, 0)
    ..quadraticBezierTo(waist, waist, 0, radius)
    ..quadraticBezierTo(-waist, waist, -radius, 0)
    ..quadraticBezierTo(-waist, -waist, 0, -radius)
    ..close();
}

Offset _toCanvas(Offset normalized, Size size) {
  return Offset(normalized.dx * size.width, normalized.dy * size.height);
}

/// Finds the lit star nearest a tap, within [hitRadius] logical pixels, in
/// the same normalized-to-canvas coordinate space [ConstellationPainter]
/// paints in.
ConstellationStar? hitTestStar(
  Offset localPosition,
  Size canvasSize,
  List<ConstellationStar> stars, {
  double hitRadius = 24,
}) {
  ConstellationStar? closest;
  var closestDistanceSq = hitRadius * hitRadius;
  for (final star in stars) {
    final distanceSq =
        (_toCanvas(star.position, canvasSize) - localPosition).distanceSquared;
    if (distanceSq < closestDistanceSq) {
      closestDistanceSq = distanceSq;
      closest = star;
    }
  }
  return closest;
}

/// The bounding box of a set of normalized points, used to frame a
/// constellation's initial pan/zoom view and to size its min/max scale.
Rect boundingBoxOf(List<Offset> points) {
  var minX = double.infinity, minY = double.infinity;
  var maxX = -double.infinity, maxY = -double.infinity;
  for (final p in points) {
    if (p.dx < minX) minX = p.dx;
    if (p.dy < minY) minY = p.dy;
    if (p.dx > maxX) maxX = p.dx;
    if (p.dy > maxY) maxY = p.dy;
  }
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}
