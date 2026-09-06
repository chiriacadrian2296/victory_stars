import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Which visual family a [ConstellationStar] belongs to. [victory] and
/// [goal] share the exact same sparkle/glow treatment when lit — a goal
/// that's been achieved is drawn by the very same code path as a victory
/// (see [ConstellationPainter.paint]) — differing only in [ConstellationStar.lit]
/// while still unachieved. [dead] is a tombstoned star: still occupying its
/// slot, drawn as a spent husk. [habit] is its own smaller, separately
/// scattered family with a different sparkle and tint.
enum StarKind { victory, goal, dead, habit }

/// One star: which entity it represents, where it sits in the
/// constellation's normalized (0..1) coordinate space, its [kind], and
/// whether it's currently lit.
class ConstellationStar {
  const ConstellationStar({
    required this.entityId,
    required this.position,
    required this.kind,
    required this.lit,
    required this.label,
  });

  final int entityId;
  final Offset position;
  final StarKind kind;
  final bool lit;

  /// The underlying [Star]/[Habit]'s own title — only actually drawn by
  /// the Galaxy tab (see `ConstellationFieldPainter`'s star-name labels);
  /// `ConstellationScreen`'s own single-project view doesn't use it, but
  /// every [ConstellationStar] carries it since both share the exact same
  /// `buildConstellationRenderStars`.
  final String label;
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
    required this.habitColor,
    this.edges = const [],
    this.linkThreshold = 0,
    required this.shapeStarCount,
    this.lineWidthScale = 1,
    this.lineAlpha = 0.35,
    this.sparkleScale = 1,
    this.glowScale = 1,
  });

  final List<ConstellationStar> stars;
  final ui.Image? glowSprite;

  /// Passed in rather than read from a static palette — a [CustomPainter]
  /// has no [BuildContext], and these must follow the active light/dark
  /// theme.
  final Color starColor;
  final Color coreColor;

  /// Tints a habit's own sparkle/glow — distinct from [starColor]/[coreColor]
  /// so habits read as a separate star family before their smaller size or
  /// different twinkle shape even register.
  final Color habitColor;

  /// Which pairs of [stars] (by index into the victory/goal/dead subset —
  /// see `ConstellationScreen._buildStars`) get a connecting line — built by
  /// `buildConstellationLayout`, so this can branch (a figure's arms and
  /// legs, a teapot's handle) instead of being a single path or loop.
  final List<(int, int)> edges;

  /// No lines are drawn at all until the shape's own graph (victories, goals
  /// and dead stars — never habits) reaches this many stars.
  final int linkThreshold;

  /// How many of [stars] belong to the shape's own point/edge graph
  /// (victory + goal + dead) — used instead of `stars.length` for the
  /// [linkThreshold] comparison, so a project's habits (appended after,
  /// scattered separately) never prematurely trigger the shape's connecting
  /// lines on a barely-started constellation.
  final int shapeStarCount;

  /// Multiply the connecting-line stroke width/alpha and the star/glow
  /// sizes below — all default to 1/0.35 (i.e. no change from before this
  /// existed), leaving `ConstellationScreen`'s own single-project view
  /// untouched. Added for the Galaxy tab (see `ConstellationFieldPainter`),
  /// where constellations sit small and far away in a wide field of view —
  /// making the shape itself much bigger there turned out to look
  /// distorted near the screen edges, so instead these make the same
  /// small shape read clearly through bolder strokes/icons/glow.
  final double lineWidthScale;
  final double lineAlpha;
  final double sparkleScale;
  final double glowScale;

  /// Bumped by the caller whenever [stars] actually changes in a way that
  /// affects rendering (a star added/achieved/deleted/resurrected, a habit
  /// completed) — deliberately NOT a deep list comparison, so pan/zoom
  /// gesture frames never trigger a repaint. Since a star's [ConstellationStar.lit]
  /// can now flip without [stars.length] changing at all (an achieved goal,
  /// a tombstoned star, a habit's streak breaking), correctness here depends
  /// entirely on the caller bumping this — the painter has no cheap way to
  /// detect that change itself.
  final int revision;

  // Tuned against ConstellationScreen's own fixed 1000x1000 canvas — every
  // fixed-pixel size below (sparkle radius, glow sprite scale, line width)
  // is expressed relative to it via [_sizeScale], so this class draws
  // identically there (size is always exactly 1000) while actually
  // shrinking/growing with the Nebula tab's zoom (where `size` is
  // `localSizePx`, which does vary — see ConstellationFieldPainter). Without
  // this, a star's glow stayed a fixed screen-pixel blob regardless of zoom
  // there, quickly looking wildly oversized on a zoomed-out constellation or
  // undersized on a zoomed-in one, while everything else about the shape
  // (star positions, via [_toCanvas]) scaled correctly.
  static const _referenceSize = 1000.0;
  static const _sparkleRadius = 5.5;
  static const _habitSparkleRadius = 3.5;
  static const _dimAlpha = 0.35;
  static const _deadAlpha = 0.15;

  @override
  void paint(Canvas canvas, Size size) {
    final sprite = glowSprite;
    if (sprite == null || stars.isEmpty) return;
    final sizeScale = size.width / _referenceSize;

    if (shapeStarCount >= linkThreshold && linkThreshold > 0) {
      final linePaint = Paint()
        ..color = starColor.withValues(alpha: lineAlpha)
        ..strokeWidth = 1.2 * sizeScale * lineWidthScale
        ..style = PaintingStyle.stroke;
      final shapeStars = stars.where((s) => s.kind != StarKind.habit).toList();
      for (final (a, b) in edges) {
        if (a >= shapeStars.length || b >= shapeStars.length) continue;
        canvas.drawLine(
          _toCanvas(shapeStars[a].position, size),
          _toCanvas(shapeStars[b].position, size),
          linePaint,
        );
      }
    }

    final lit = stars.where((s) => s.kind != StarKind.habit && s.lit).toList();
    final unlitGoals = stars
        .where((s) => s.kind == StarKind.goal && !s.lit)
        .toList();
    final dead = stars.where((s) => s.kind == StarKind.dead).toList();
    final litHabits = stars
        .where((s) => s.kind == StarKind.habit && s.lit)
        .toList();
    final unlitHabits = stars
        .where((s) => s.kind == StarKind.habit && !s.lit)
        .toList();

    _drawGlowAndSparkle(
      canvas,
      size,
      sprite,
      lit,
      tint: starColor,
      sparkleColor: coreColor,
      sparkleRadius: _sparkleRadius * sizeScale * sparkleScale,
      spriteScale: sizeScale * glowScale,
    );
    _drawSparkleOnly(
      canvas,
      size,
      unlitGoals,
      color: coreColor.withValues(alpha: _dimAlpha),
      radius: _sparkleRadius * sizeScale * sparkleScale,
    );
    _drawSparkleOnly(
      canvas,
      size,
      dead,
      color: coreColor.withValues(alpha: _deadAlpha),
      radius: _sparkleRadius * sizeScale * sparkleScale,
      outlineOnly: true,
    );
    _drawGlowAndSparkle(
      canvas,
      size,
      sprite,
      litHabits,
      tint: habitColor,
      sparkleColor: habitColor,
      sparkleRadius: _habitSparkleRadius * sizeScale * sparkleScale,
      spriteScale: sizeScale * 0.55 * glowScale,
    );
    _drawSparkleOnly(
      canvas,
      size,
      unlitHabits,
      color: habitColor.withValues(alpha: _deadAlpha),
      radius: _habitSparkleRadius * sizeScale * sparkleScale,
    );
  }

  void _drawGlowAndSparkle(
    Canvas canvas,
    Size size,
    ui.Image sprite,
    List<ConstellationStar> group, {
    required Color tint,
    required Color sparkleColor,
    required double sparkleRadius,
    double spriteScale = 1,
  }) {
    if (group.isEmpty) return;

    final srcRect = Rect.fromLTWH(
      0,
      0,
      sprite.width.toDouble(),
      sprite.height.toDouble(),
    );
    final transforms = <RSTransform>[];
    final srcRects = <Rect>[];
    final colors = <Color>[];

    for (final star in group) {
      final center = _toCanvas(star.position, size);
      transforms.add(
        RSTransform.fromComponents(
          rotation: 0,
          scale: spriteScale,
          anchorX: sprite.width / 2,
          anchorY: sprite.height / 2,
          translateX: center.dx,
          translateY: center.dy,
        ),
      );
      srcRects.add(srcRect);
      colors.add(tint);
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

    // A miniature echo of `sky_supernova.frag`'s own four-point cross
    // spike — same cardinal-rays shape, just a plain filled Path instead
    // of a shader, and sized off this group's own [sparkleRadius] so a
    // habit's smaller stars get proportionally smaller rays too. Drawn in
    // [tint] (the same gold the glow blob above is tinted) rather than
    // [sparkleColor], so it reads as an extension of the glow's own light
    // reaching outward, with the bright sparkle core still the one crisp
    // white point on top of it.
    final spikes = _spikesPath(sparkleRadius * 3);
    final spikePaint = Paint()..color = tint.withValues(alpha: 0.55);
    for (final star in group) {
      final center = _toCanvas(star.position, size);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.drawPath(spikes, spikePaint);
      canvas.restore();
    }

    final sparkle = _sparklePath(sparkleRadius);
    final corePaint = Paint()..color = sparkleColor;
    for (final star in group) {
      final center = _toCanvas(star.position, size);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.drawPath(sparkle, corePaint);
      canvas.restore();
    }
  }

  void _drawSparkleOnly(
    Canvas canvas,
    Size size,
    List<ConstellationStar> group, {
    required Color color,
    required double radius,
    bool outlineOnly = false,
  }) {
    if (group.isEmpty) return;
    final sparkle = _sparklePath(radius);
    final paint = outlineOnly
        ? (Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1)
        : (Paint()..color = color);
    for (final star in group) {
      final center = _toCanvas(star.position, size);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.drawPath(sparkle, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConstellationPainter oldDelegate) {
    return revision != oldDelegate.revision ||
        glowSprite != oldDelegate.glowSprite ||
        starColor != oldDelegate.starColor ||
        coreColor != oldDelegate.coreColor ||
        habitColor != oldDelegate.habitColor ||
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

/// Four thin rays radiating along the cardinal directions out to [radius]
/// — a plain filled [Path] echo of `sky_supernova.frag`'s own cross spike
/// (wide at the base, tapering to a point), scaled down to sit on a single
/// star instead of filling the screen. A shader can't be reused here (this
/// is a per-star Canvas draw, not a full-screen fragment pass), so this is
/// a hand-built approximation of the same shape rather than a shared
/// formula.
Path _spikesPath(double radius) {
  final halfBase = radius * 0.05;
  final path = Path();
  for (final direction in const [Offset(1, 0), Offset(-1, 0), Offset(0, 1), Offset(0, -1)]) {
    final perp = Offset(-direction.dy, direction.dx) * halfBase;
    final tip = direction * radius;
    path
      ..moveTo(-perp.dx, -perp.dy)
      ..lineTo(perp.dx, perp.dy)
      ..lineTo(tip.dx, tip.dy)
      ..close();
  }
  return path;
}

Offset _toCanvas(Offset normalized, Size size) {
  return Offset(normalized.dx * size.width, normalized.dy * size.height);
}

/// Finds the star nearest a tap, within [hitRadius] logical pixels, in the
/// same normalized-to-canvas coordinate space [ConstellationPainter] paints
/// in. Works regardless of [ConstellationStar.kind]/[ConstellationStar.lit] —
/// a dead star or an unlit goal is just as tappable as a lit victory, since
/// tapping any of them opens something useful (resurrect, "mark achieved",
/// or just viewing).
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
