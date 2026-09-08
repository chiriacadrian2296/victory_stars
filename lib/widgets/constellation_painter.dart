import 'dart:typed_data';
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

/// Compiles `shaders/constellation_flare.frag` once — callers hold the
/// returned [ui.FragmentProgram] (not a [ui.FragmentShader]) and call
/// [ui.FragmentProgram.fragmentShader] fresh each time they actually draw
/// with it (see [ConstellationPainter._drawGlowAndSparkle]): a `.frag`
/// asset only needs compiling once, but each draw needs its *own* shader
/// instance so its uniforms (this group's star positions) can't be
/// overwritten by another draw's before the canvas actually gets
/// rasterized.
Future<ui.FragmentProgram> buildConstellationFlareProgram() {
  return ui.FragmentProgram.fromAsset('shaders/constellation_flare.frag');
}

class ConstellationPainter extends CustomPainter {
  const ConstellationPainter({
    required this.stars,
    required this.flareProgram,
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
    this.time = 0,
  });

  final List<ConstellationStar> stars;

  /// See [buildConstellationFlareProgram] — the compiled
  /// `constellation_flare.frag` a lit star's flare is drawn with. Null
  /// (or a group with too many stars for a single shader pass — see
  /// [_drawGlowAndSparkle]'s own `kMaxFlareStars`) just skips the flare,
  /// leaving the star's identity icon on its own.
  final ui.FragmentProgram? flareProgram;

  /// Seconds, free-running — drives the flare's flicker (see
  /// [_drawGlowAndSparkle]) with the same 2-sine-product formula
  /// `nebula_particles.frag`'s own `flareStarLayer()` uses, so a lit star
  /// here pulses in sync with the same formula the background flare stars
  /// use rather than sitting static. Defaults to 0 (a fixed, non-animated
  /// flicker phase) so any caller that doesn't thread a real clock through
  /// still renders correctly, just without the pulse.
  final double time;

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
    if (stars.isEmpty) return;
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

    _drawGlowAndSparkle(canvas, size, lit, flareRadius: size.width * 0.42);
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
      litHabits,
      flareRadius: size.width * 0.42 * 0.55,
    );
    _drawSparkleOnly(
      canvas,
      size,
      unlitHabits,
      color: habitColor.withValues(alpha: _deadAlpha),
      radius: _habitSparkleRadius * sizeScale * sparkleScale,
    );
  }

  // Comfortably above any real constellation's star count — must match
  // `constellation_flare.frag`'s own `kMaxStars` exactly (positions
  // beyond however many stars actually exist are padded with (-1, -1),
  // which the shader skips).
  static const _kMaxFlareStars = 24;

  void _drawGlowAndSparkle(
    Canvas canvas,
    Size size,
    List<ConstellationStar> group, {
    // A fraction of [size.width] (the caller always passes
    // size.width * someFraction), not of [_sparkleRadius] — that constant
    // is scaled for a small icon and, tied to
    // `kSkyConstellationAngularSpan`'s own tiny sky patch, comes out to a
    // fraction of a pixel at the Galaxy tab's typical zoom, nowhere near
    // big enough for a flare meant to read as one of the bright stars in
    // the sky. [size] itself (a constellation's own on-screen footprint —
    // `localSizePx` in the Galaxy tab, a fixed 1000 in `ConstellationScreen`)
    // scales with zoom the same way the bg's own flare stars do, so tying
    // this to it keeps the ratio between the two roughly constant across
    // zoom levels instead of needing a hand-tuned multiplier per case.
    required double flareRadius,
  }) {
    if (group.isEmpty) return;

    final program = flareProgram;
    if (program == null) return;

    // `constellation_flare.frag` — the exact same glow/spike/core math
    // `nebula_particles.frag`'s own `flareStarLayer()` computes per pixel
    // for the bg stars, just evaluated live against this group's actual
    // star positions instead of a procedural lattice (see that shader's
    // own doc comment for why this replaced two earlier, visibly weaker
    // attempts: a pre-baked sprite stamped via drawAtlas, then a
    // Canvas gradient+Path approximation). One shader pass covers every
    // star in [group] at once — cheaper than one draw call per star, and
    // avoids needing per-star canvas transforms (rotation is computed
    // inside the shader, from each star's own position hash).
    // [positions] are absolute canvas pixels (where to actually draw each
    // star) — these shift continuously as the camera pans/zooms, since
    // [size] itself (a constellation's own on-screen footprint) does.
    // [seeds] are each star's *normalized* 0..1 position within its own
    // constellation's local shape space instead — never affected by the
    // camera at all — used only to seed the shader's per-star hash
    // (flicker phase, rotation). Feeding that hash [positions] instead (an
    // earlier version did) meant its own input value drifted continuously
    // with the camera too, so every star's rotation angle jumped to a
    // essentially new random value on every single pan/zoom frame instead
    // of staying fixed between a star's own occasional flicker.
    final positions = Float32List(_kMaxFlareStars * 2);
    final seeds = Float32List(_kMaxFlareStars * 2);
    for (var i = 0; i < _kMaxFlareStars; i++) {
      if (i < group.length) {
        final center = _toCanvas(group[i].position, size);
        positions[i * 2] = center.dx;
        positions[i * 2 + 1] = center.dy;
        seeds[i * 2] = group[i].position.dx;
        seeds[i * 2 + 1] = group[i].position.dy;
      } else {
        positions[i * 2] = -1;
        positions[i * 2 + 1] = -1;
      }
    }

    // A fresh shader instance per draw, from the already-compiled
    // [program] (cheap — no recompilation) — not one shared instance
    // reused across draws, since this same [program] gets a new shader
    // for every group of every constellation, all within one frame, and
    // sharing a single instance would risk a later draw's `setFloat`
    // calls landing on an earlier draw's uniforms before the canvas is
    // actually rasterized.
    final shader = program.fragmentShader();
    shader.setFloat(0, time);
    shader.setFloat(1, flareRadius);
    for (var i = 0; i < positions.length; i++) {
      shader.setFloat(2 + i, positions[i]);
    }
    for (var i = 0; i < seeds.length; i++) {
      shader.setFloat(2 + positions.length + i, seeds[i]);
    }
    // BlendMode.plus, not the default srcOver — this is the actual
    // structural difference from the bg's own flare stars, not a tuning
    // knob: nebula_particles.frag never has a transparent pixel at all
    // (its main() always writes vec4(color, 1.0) — the flare stars are
    // just added straight into that one always-opaque color before the
    // single write), so real alpha-blend compositing never happens for
    // them. This shader, drawn as its own separate layer over the sky/
    // constellation content beneath it, *does* have to composite through
    // real alpha at its low-alpha edges — and whatever the exact mismatch
    // was (straight vs. premultiplied output, most likely), it kept
    // reading as a dark/rough edge no matter how the falloff curve itself
    // was retuned. Plus mode sidesteps the question entirely: it just
    // adds this shader's (already alpha-weighted) color onto whatever's
    // beneath, the same "pure addition into something already there"
    // relationship the bg stars have with their own nebula backdrop —
    // nothing for a blend-mode mismatch to darken.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = shader
        ..blendMode = BlendMode.plus,
    );
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
        flareProgram != oldDelegate.flareProgram ||
        starColor != oldDelegate.starColor ||
        coreColor != oldDelegate.coreColor ||
        habitColor != oldDelegate.habitColor ||
        stars.length != oldDelegate.stars.length ||
        time != oldDelegate.time;
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
