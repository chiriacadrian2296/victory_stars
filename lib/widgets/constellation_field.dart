import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/constellation_shapes_v2.dart';
import '../models/habit.dart';
import '../models/project.dart';
import '../models/star.dart';
import 'constellation_painter.dart';

/// One project's constellation, already built (see
/// `buildConstellationRenderStars`) and given a stable spot in the shared
/// pannable/zoomable world the Nebula tab scatters every constellation
/// across.
class PlacedConstellation {
  const PlacedConstellation({
    required this.project,
    required this.shape,
    required this.worldPosition,
    required this.stars,
    required this.habits,
    required this.renderStars,
    required this.edges,
    required this.shapeStarCount,
  });

  final Project project;
  final ConstellationShape? shape;

  /// Center of this constellation's own local unit square, in world-space
  /// units (see [worldToScreen]) — stable across sessions as long as
  /// [index] (the value this was built from, via [constellationWorldPosition])
  /// doesn't change, which it won't for an existing project since newer
  /// ones are always appended after it.
  final Offset worldPosition;

  /// Project-scoped, kept alongside [renderStars] so tapping a star can
  /// look its full [Star]/[Habit] back up by id without needing to search
  /// every other constellation's list too.
  final List<Star> stars;
  final List<Habit> habits;

  final List<ConstellationStar> renderStars;
  final List<(int, int)> edges;
  final int shapeStarCount;
}

/// The Nebula tab's world is a sky sphere — the camera (see [SkyCamera])
/// sits at its center, like a viewer inside an HDRI environment map.
/// Content (a constellation's spot in the sky) is still placed with a
/// fixed (azimuth, elevation) pair in turns — [Offset.dx]/[Offset.dy] —
/// since content never rotates and a stable, world-referenced coordinate
/// is exactly what it needs; only the *camera* uses a full free
/// orientation with no such reference (see [SkyCamera] for why).
///
/// [PlacedConstellation.worldPosition]'s elevation is always kept within
/// ±[kSkyMaxContentElevationTurns] so no constellation ever sits close to
/// where azimuth stops mattering (the poles of *this* fixed coordinate
/// system — content still has them, only the camera doesn't).
const double kSkyMaxContentElevationTurns = 0.22;

/// How much of the sky sphere one constellation's own local 0..1 space
/// covers, in turns — independent of [zoom], so shrinking this is what
/// makes every constellation read as one small patch of a much bigger sky
/// instead of ballooning to fill the screen at any zoom level. Tried much
/// larger (0.8) first to make constellations easier to spot in the
/// now-farther-feeling sky, but a shape that big started looking visibly
/// distorted near the edges of a wide field of view (the flat-patch
/// approximation this class draws each constellation as breaks down at
/// that size) — kept small instead, and made findable through
/// `ConstellationFieldPainter`'s own bolder line/icon/glow sizing instead
/// of through sheer size.
const double kSkyConstellationAngularSpan = 0.15;

/// Where the [index]-th constellation (by stable creation order — see
/// `NebulaScreen._loadData`) sits on the sky sphere: a 2D Kronecker
/// (additive-recurrence) sequence — azimuth and elevation each advance by
/// their own irrational step per index — which spreads points evenly with
/// no collisions and, unlike a classic Fibonacci sphere, needs no fixed
/// total point count up front (elevation's formula would otherwise shift
/// as more projects are added, moving every existing constellation).
/// Deterministic and index-only (not id-based), so an existing project's
/// spot in the sky never moves as more are added.
Offset constellationWorldPosition(int index) {
  const azimuthStep = 0.6180339887498949; // golden ratio conjugate
  const elevationStep = 0.4142135623730951; // sqrt(2) - 1
  final azimuth = (index * azimuthStep) % 1.0;
  final elevationUnit = (index * elevationStep) % 1.0;
  final elevation = kSkyMaxContentElevationTurns * (2 * elevationUnit - 1);
  return Offset(azimuth, elevation);
}

const double _twoPi = 2 * math.pi;

/// A plain (x, y, z) vector — deliberately not a class: every use below is
/// short-lived (built, dotted/crossed/rotated a few times, then either
/// discarded or folded into a [SkyCamera]), so a record avoids the
/// ceremony of a whole vector-math type for that. Structural, not
/// nominal, so it never causes a "private type in public API" problem
/// even where it flows out through [SkyCamera]'s own public fields.
typedef _Vec3 = (double x, double y, double z);

double _dot(_Vec3 a, _Vec3 b) => a.$1 * b.$1 + a.$2 * b.$2 + a.$3 * b.$3;

_Vec3 _cross(_Vec3 a, _Vec3 b) => (
  a.$2 * b.$3 - a.$3 * b.$2,
  a.$3 * b.$1 - a.$1 * b.$3,
  a.$1 * b.$2 - a.$2 * b.$1,
);

_Vec3 _scaled(_Vec3 v, double s) => (v.$1 * s, v.$2 * s, v.$3 * s);

_Vec3 _minus(_Vec3 a, _Vec3 b) => (a.$1 - b.$1, a.$2 - b.$2, a.$3 - b.$3);

_Vec3 _add(_Vec3 a, _Vec3 b) => (a.$1 + b.$1, a.$2 + b.$2, a.$3 + b.$3);

_Vec3 _normalized(_Vec3 v) {
  final length = math.sqrt(_dot(v, v));
  return (v.$1 / length, v.$2 / length, v.$3 / length);
}

/// Rotates [v] by [angle] radians around [axis] (must already be unit
/// length) via Rodrigues' rotation formula — the one piece of vector math
/// [SkyCamera] actually needs, since rotating around an arbitrary
/// (camera-relative, not world-fixed) axis is what lets it turn freely
/// with no poles.
_Vec3 _rotateAroundAxis(_Vec3 v, _Vec3 axis, double angle) {
  final cosA = math.cos(angle);
  final sinA = math.sin(angle);
  final crossAV = _cross(axis, v);
  final axisDotV = _dot(axis, v);
  return (
    v.$1 * cosA + crossAV.$1 * sinA + axis.$1 * axisDotV * (1 - cosA),
    v.$2 * cosA + crossAV.$2 * sinA + axis.$2 * axisDotV * (1 - cosA),
    v.$3 * cosA + crossAV.$3 * sinA + axis.$3 * axisDotV * (1 - cosA),
  );
}

/// The point on the unit sky sphere at [azimuthTurns]/[elevationTurns] —
/// y is "up", matching the nebula shader's own spherical-to-Cartesian
/// convention exactly, so a constellation's rendered position and the
/// animated background it sits over always agree. Only ever used for
/// fixed *content* (a constellation's spot) and once, to seed a
/// [SkyCamera]'s starting orientation — the camera itself never touches
/// azimuth/elevation again after that, only relative rotations.
_Vec3 _directionOn(double azimuthTurns, double elevationTurns) {
  final azimuth = azimuthTurns * _twoPi;
  final elevation = elevationTurns * _twoPi;
  final cosEl = math.cos(elevation);
  return (
    cosEl * math.cos(azimuth),
    math.sin(elevation),
    cosEl * math.sin(azimuth),
  );
}

/// A free-orientation camera at the center of the sky sphere — no fixed
/// "world up" reference, so there's nothing that plays the role of a pole
/// at all, the same way spinning a globe with your hand has no direction
/// that's special. [forward] is where it's looking; [right]/[up] span the
/// flat tangent plane [worldToScreen] projects onto.
///
/// An earlier version of this pinned orientation to two fixed angles
/// (azimuth around world-up, elevation above/below it) — simple, but
/// *any* such 2-angle parameterization has poles by construction (the
/// points where azimuth stops mattering), and every fix attempted for the
/// artifacts that caused — clamping elevation, letting it wrap, patching
/// the sign flip in the "right" vector right at a pole crossing — was
/// chasing the same root cause instead of removing it. [rotated] is what
/// actually removes it: every drag rotates the *current* basis around its
/// *own* [right]/[up] axes rather than re-deriving from world-fixed
/// angles, exactly how any trackball/arcball control (spinning a 3D
/// object by hand, e.g. in Blender) avoids gimbal issues entirely.
class SkyCamera {
  const SkyCamera._(this.forward, this.right, this.up);

  /// Builds a starting orientation looking toward a fixed
  /// (azimuth, elevation) — the *only* place this class still touches
  /// world-fixed angles, since some starting point has to come from
  /// somewhere (see `NebulaScreen`'s "open centered on Love" logic). Every
  /// [rotated] call afterward moves on from here relative to itself, never
  /// referencing azimuth/elevation again.
  factory SkyCamera.lookingAt({
    required double azimuthTurns,
    required double elevationTurns,
  }) {
    final forward = _directionOn(azimuthTurns, elevationTurns);
    final azimuth = azimuthTurns * _twoPi;
    final right = (-math.sin(azimuth), 0.0, math.cos(azimuth));
    final up = _cross(right, forward);
    return SkyCamera._(forward, right, up);
  }

  final (double, double, double) forward;
  final (double, double, double) right;
  final (double, double, double) up;

  /// A new camera turned by a screen-drag-style delta, in turns —
  /// [horizontalTurns] rotates around the camera's *own current* [up]
  /// axis, [verticalTurns] around its (just-updated) [right] axis. Signed
  /// so a positive [horizontalTurns] looks left and a positive
  /// [verticalTurns] looks up — see `NebulaScreen._rotateCamera`, the only
  /// caller, for where those signs are actually chosen from drag input.
  SkyCamera rotated({
    required double horizontalTurns,
    required double verticalTurns,
  }) {
    final horizontalAngle = horizontalTurns * _twoPi;
    final verticalAngle = verticalTurns * _twoPi;

    var newForward = _rotateAroundAxis(forward, up, horizontalAngle);
    var newRight = _rotateAroundAxis(right, up, horizontalAngle);
    // `up` itself is unchanged by this step — it's the rotation axis.

    newForward = _rotateAroundAxis(newForward, newRight, verticalAngle);
    var newUp = _rotateAroundAxis(up, newRight, verticalAngle);
    // `newRight` itself is unchanged by this step, for the same reason.

    // Re-orthonormalize against floating-point drift accumulating over a
    // long session of small rotations — cheap, and keeps forward/right/up
    // an exact orthonormal basis indefinitely instead of only
    // approximately.
    newForward = _normalized(newForward);
    newRight = _normalized(
      _minus(newRight, _scaled(newForward, _dot(newRight, newForward))),
    );
    newUp = _cross(newRight, newForward);

    return SkyCamera._(newForward, newRight, newUp);
  }

  /// A new camera rotated so that whatever was in direction [from]
  /// (typically wherever the cursor started a drag — see
  /// [screenToDirection]) now lies exactly in direction [to] (typically
  /// the cursor's current position) — an exact "grab and drag" alignment,
  /// via the single rotation (found through [from] × [to] as its axis,
  /// their angle between as its angle) that maps one straight onto the
  /// other, rather than [rotated]'s screen-pixels-to-turns approximation.
  /// `NebulaScreen` uses this exclusively for live dragging (recomputed
  /// from the *drag's starting* camera every frame, not accumulated
  /// step-by-step, so tiny per-frame errors can never build up over a
  /// long drag) and [rotated] only for the momentum glide afterward,
  /// where there's no cursor position left to align to.
  SkyCamera rotatedToAlign(
    (double, double, double) from,
    (double, double, double) to,
  ) {
    final axisRaw = _cross(from, to);
    final axisLength = math.sqrt(_dot(axisRaw, axisRaw));
    // Already (anti)parallel — either no rotation is needed, or [from] and
    // [to] are exact opposites, a degenerate case with no single
    // well-defined axis that a drag gesture wouldn't realistically produce
    // anyway (it would mean the cursor jumped to the exact antipode of
    // where it started).
    if (axisLength < 1e-9) return this;

    final axis = _scaled(axisRaw, 1 / axisLength);
    final angle = math.acos(_dot(from, to).clamp(-1.0, 1.0));

    var newForward = _normalized(_rotateAroundAxis(forward, axis, angle));
    var newRight = _rotateAroundAxis(right, axis, angle);
    newRight = _normalized(
      _minus(newRight, _scaled(newForward, _dot(newRight, newForward))),
    );
    final newUp = _cross(newRight, newForward);

    return SkyCamera._(newForward, newRight, newUp);
  }

  /// A new camera twisted so the *rendered sky* turns by [angle] radians
  /// clockwise (positive = clockwise, matching `ScaleUpdateDetails.rotation`
  /// and `_RollKnob`'s own convention) around its *own* [forward] axis — a
  /// two-finger rotate gesture, the roll pan/zoom never touch. [forward]
  /// itself never changes: rolling only spins what's already in view, the
  /// way tilting a photo in a viewer doesn't change what's centered in it.
  ///
  /// Note the *negated* angle below: rotating the [right]/[up] basis
  /// vectors clockwise by θ makes everything projected through them (see
  /// [worldToScreen]) appear to spin counterclockwise instead — the same
  /// inversion a camera pan has versus the content it looks at. Passing
  /// `-angle` to the actual basis rotation is what makes a clockwise finger
  /// twist produce a clockwise-*looking* sky, which is the contract every
  /// caller relies on (empirically confirmed backwards before this fix —
  /// see NebulaScreen's roll handling).
  SkyCamera rolled(double angle) {
    if (angle == 0) return this;
    final newRight = _normalized(_rotateAroundAxis(right, forward, -angle));
    final newUp = _cross(newRight, forward);
    return SkyCamera._(forward, newRight, newUp);
  }
}

/// The result of [worldToScreen]: where [world] lands on screen, plus how
/// much the stereographic projection has magnified things there relative
/// to dead-center (1 there, growing gently past 1 toward the edge of a
/// wide field of view) — used only to size a constellation's own sprite
/// consistently with the projection itself (see [ConstellationFieldPainter])
/// instead of every one rendering at a flat fixed size regardless of how
/// far off-center it is.
class ScreenProjection {
  const ScreenProjection(this.position, this.perspectiveScale);
  final Offset position;
  final double perspectiveScale;
}

/// Projects [world] (azimuth, elevation in turns) through [camera] — 1
/// world unit of tangent-plane distance is 1 screen height at [zoom] 1,
/// same convention the old flat-plane version of this function used.
/// Returns null if [world] is far enough behind the camera that the
/// projection breaks down — there's nothing sensible to draw there.
///
/// Stereographic, not the simpler gnomonic (plain divide-by-depth)
/// projection a first pass at this used: gnomonic keeps straight lines
/// straight but stretches anything away from dead-center into ellipses at
/// a wide field of view — the classic "wide-angle lens" look, which reads
/// as an oblong/football-shaped world instead of a sphere once the camera
/// pulls back far enough to matter. Stereographic is conformal (it
/// doesn't stretch circles into ellipses, at any field of view up to
/// nearly 180°), which is what actually looks like a sphere from the
/// inside — the same projection "little planet" panorama viewers use.
///
/// Unlike the flat/wrapped-plane math this replaced, a real camera has no
/// seam and no "second copy" of anything to worry about: within a field
/// of view under 180°, at most one direction in the whole sky can ever
/// land at a given screen position, by construction — so, unlike before,
/// zooming out further can never make a constellation repeat or jump.
ScreenProjection? worldToScreen(
  Offset world,
  SkyCamera camera,
  double zoom,
  Size screenSize,
) {
  final direction = _directionOn(world.dx, world.dy);
  final z = _dot(direction, camera.forward);
  if (z < -0.5) return null;
  final scale = 2 / (1 + z);
  final x = _dot(direction, camera.right) * scale;
  final y = _dot(direction, camera.up) * scale;
  return ScreenProjection(
    Offset(
      screenSize.width / 2 + x * zoom * screenSize.height,
      screenSize.height / 2 - y * zoom * screenSize.height,
    ),
    scale,
  );
}

/// The inverse of [worldToScreen]'s projection: the 3D direction that
/// [screen] corresponds to, for [camera]/[zoom]/[screenSize] — inverting
/// the exact same stereographic math, not an approximation, so it's what
/// makes `NebulaScreen`'s "grab and drag" tracking (see
/// [SkyCamera.rotatedToAlign]) exact rather than the small-angle guess a
/// flat pixel delta would be. Never returns null (unlike the forward
/// direction) — every screen point has a well-defined direction to invert
/// back to, even ones a real camera wouldn't ever render (there's no
/// analogous "behind the camera" case running this backwards).
(double, double, double) screenToDirection(
  Offset screen,
  SkyCamera camera,
  double zoom,
  Size screenSize,
) {
  final tx = (screen.dx - screenSize.width / 2) / zoom / screenSize.height;
  final ty = -(screen.dy - screenSize.height / 2) / zoom / screenSize.height;
  final rho2 = tx * tx + ty * ty;
  final denom = 4 + rho2;
  return _normalized((
    camera.right.$1 * (4 * tx / denom) +
        camera.up.$1 * (4 * ty / denom) +
        camera.forward.$1 * ((4 - rho2) / denom),
    camera.right.$2 * (4 * tx / denom) +
        camera.up.$2 * (4 * ty / denom) +
        camera.forward.$2 * ((4 - rho2) / denom),
    camera.right.$3 * (4 * tx / denom) +
        camera.up.$3 * (4 * ty / denom) +
        camera.forward.$3 * ((4 - rho2) / denom),
  ));
}

/// The lowest [NebulaScreen] should ever let its camera zoom out to — a
/// real perspective camera (see [worldToScreen]) has no structural reason
/// to cap this the way the old flat-plane math needed a
/// repeat-avoidance floor, so this is just picked for how wide a field of
/// view still feels like a "big sky" rather than a shrunk-down, distant
/// one. Halved from an original 0.6 (which put the screen's near edge at
/// roughly atan(0.5 / 0.6) ≈ 40° off-axis, ~80° of vertical field of
/// view) so max zoom-out reaches a noticeably wider ~118° instead — part
/// of pushing the *entire* zoom range farther back, see
/// `NebulaScreen._maxZoom`'s own comment.
const double minZoomWithoutRepeats = 0.3;

/// How far [camera] has rolled away from "level" (its own zero-roll,
/// [SkyCamera.lookingAt]-style orientation) at wherever it's currently
/// looking — a compass-style reading independent of which way it's
/// panned, used to drive the roll knob's orbiting indicator dot (see
/// `_RollKnob` in `nebula_screen.dart`) so there's a way to actually see
/// how far you've rolled instead of just feeling it.
double cameraRollAngle(SkyCamera camera) =>
    _rollAngleAt(camera.forward, camera.up);

/// Shared by [_projectConstellationTransform] and [cameraRollAngle]: how
/// far [cameraUp] has rotated, around [direction], away from the canonical
/// (zero-roll) tangent frame at that exact spot on the sphere — see
/// [_projectConstellationTransform]'s own doc comment for the related full
/// derivation (this is the same "canonical tangent frame" idea, just
/// measuring rotation alone rather than the full transform).
double _rollAngleAt(_Vec3 direction, _Vec3 cameraUp) {
  final azimuth = math.atan2(direction.$3, direction.$1);
  final canonicalRight = (-math.sin(azimuth), 0.0, math.cos(azimuth));
  final canonicalUp = _cross(canonicalRight, direction);

  final upAlongDirection = _dot(cameraUp, direction);
  final upTangent = _normalized(
    _minus(cameraUp, _scaled(direction, upAlongDirection)),
  );

  // Negated: canvas.rotate() turns *clockwise* for a positive angle in
  // Flutter's canvas coordinate space, which is the opposite sense from
  // this angle's own atan2(x, y) convention — confirmed backwards
  // on-screen (constellation shape rotating opposite the background grid)
  // before this negation.
  return -math.atan2(
    _dot(upTangent, canonicalRight),
    _dot(upTangent, canonicalUp),
  );
}

/// The on-screen affine transform (rotation, non-uniform scale, *and*
/// skew all at once) that carries [worldPosition]'s own local 0..1
/// constellation space into screen pixels — the single source of truth
/// [ConstellationFieldPainter.paint] and [hitTestField] both build on.
///
/// A constellation dead-center in view, facing the camera square-on,
/// reads as a plain flat square — same as the old rotation-only version
/// of this. But toward the edge of a wide field of view, a flat patch
/// tangent to the sphere is being looked at *from an angle*, the same way
/// a picture hung on a wall looks like a parallelogram, not a rectangle,
/// once you're not standing square in front of it — and the background
/// sky already renders that way for free, per-pixel, in the shader. A
/// constellation drawn as a plain rotated square right next to it looked
/// wrong specifically for missing that skew/foreshortening — this fixes
/// it by using the *actual* local transform, not just its rotation.
///
/// Computed as the numerical derivative of the exact same stereographic
/// projection [worldToScreen] itself uses, evaluated at [worldPosition]
/// via two points nudged by [_epsilon] along its own canonical (zero-roll)
/// tangent frame — the same "true north/east" convention
/// [SkyCamera.lookingAt] and [_rollAngleAt] both use. [_epsilon] is a
/// small angle in radians, not a pixel count — small enough that the
/// derivative is accurate, nowhere near small enough to lose precision
/// against a direction vector's own unit length.
class _ConstellationTransform {
  const _ConstellationTransform(this.center, this.right, this.up);

  /// Where [worldPosition]'s own center lands on screen — matches
  /// [worldToScreen]'s own `position` exactly.
  final Offset center;

  /// Where a step of one full local-space unit (0..1) along the
  /// constellation's own canonical "right" axis ends up, in screen
  /// pixels *relative to [center]* — the transform's first column.
  final Offset right;

  /// Same as [right], for the canonical "up" axis — the transform's
  /// second column.
  final Offset up;
}

const double _epsilon = 0.01;

_ConstellationTransform? _projectConstellationTransform(
  Offset worldPosition,
  SkyCamera camera,
  double zoom,
  Size screenSize,
  double angularSpan,
) {
  final direction = _directionOn(worldPosition.dx, worldPosition.dy);
  final azimuth = worldPosition.dx * _twoPi;
  final canonicalRight = (-math.sin(azimuth), 0.0, math.cos(azimuth));
  final canonicalUp = _cross(canonicalRight, direction);

  Offset? projectOffset(_Vec3 dir) {
    final z = _dot(dir, camera.forward);
    if (z < -0.5) return null;
    final scale = 2 / (1 + z);
    final x = _dot(dir, camera.right) * scale;
    final y = _dot(dir, camera.up) * scale;
    return Offset(x * zoom * screenSize.height, -y * zoom * screenSize.height);
  }

  final centerOffset = projectOffset(direction);
  final rightOffset = projectOffset(
    _normalized(_add(direction, _scaled(canonicalRight, _epsilon))),
  );
  final upOffset = projectOffset(
    _normalized(_add(direction, _scaled(canonicalUp, _epsilon))),
  );
  if (centerOffset == null || rightOffset == null || upOffset == null) {
    return null;
  }

  // Per radian of tangent-plane angle so far — scaled down to per local
  // 0..1 unit (matching how every other size in this file already treats
  // kSkyConstellationAngularSpan) by multiplying by angularSpan below.
  final rightVec = (rightOffset - centerOffset) / _epsilon * angularSpan;
  final upVec = (upOffset - centerOffset) / _epsilon * angularSpan;

  return _ConstellationTransform(
    Offset(
      screenSize.width / 2 + centerOffset.dx,
      screenSize.height / 2 + centerOffset.dy,
    ),
    rightVec,
    upVec,
  );
}

/// Finds whichever constellation (if any) has a star under [screenPos] —
/// checks each constellation whose own on-screen footprint could plausibly
/// contain the tap before reusing [hitTestStar] unmodified, in that
/// constellation's own local pixel space, to find the actual star.
(PlacedConstellation, ConstellationStar)? hitTestField(
  Offset screenPos,
  List<PlacedConstellation> placed,
  SkyCamera camera,
  double zoom,
  Size screenSize,
) {
  for (final constellation in placed) {
    final transform = _projectConstellationTransform(
      constellation.worldPosition,
      camera,
      zoom,
      screenSize,
      kSkyConstellationAngularSpan,
    );
    if (transform == null) continue;

    // Undo the same skew/rotation `ConstellationFieldPainter.paint` draws
    // with (see [_projectConstellationTransform]) by inverting its 2x2
    // basis, so the tap lands in the shape's own flat local space — a
    // plain axis-aligned check against the still-transformed [screenPos]
    // would miss taps once the camera's off dead-center or rolled.
    final relative = screenPos - transform.center;
    final det =
        transform.right.dx * transform.up.dy -
        transform.up.dx * transform.right.dy;
    if (det.abs() < 1e-9) continue;
    final w = (relative.dx * transform.up.dy - transform.up.dx * relative.dy) / det;
    final h = (transform.right.dx * relative.dy - relative.dx * transform.right.dy) / det;

    // Wider than the shape's own 0..1 footprint since overflow/habit stars
    // can sit up to radius 1.0 from center — 0.8 (of a *half*-width) keeps
    // them tappable without bloating the box enough to start overlapping
    // tidy neighbors.
    if (w.abs() > 0.8 || h.abs() > 0.8) continue;

    final localSizePx = (transform.right.distance + transform.up.distance) / 2;
    final localTap = Offset((w + 0.5) * localSizePx, (h + 0.5) * localSizePx);
    final star = hitTestStar(
      localTap,
      Size.square(localSizePx),
      constellation.renderStars,
    );
    if (star != null) return (constellation, star);
  }
  return null;
}

double _smoothstep(double edge0, double edge1, double x) {
  final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// Star-name labels are implemented (see [ConstellationFieldPainter.paint])
/// but switched off for now — with many stars close together they piled up
/// and overlapped too much to read cleanly. Left in place, gated behind
/// this flag, rather than deleted, since the plan is to revisit the
/// crowding problem (spacing/collision-avoidance, most likely) and turn
/// them back on later.
const bool _kShowStarLabels = false;

/// Where, on the log-zoom scale, constellation-name labels finish fading
/// out and star-name labels finish fading in (see [ConstellationFieldPainter]
/// — `_kLabelFadeLogRange` either side of this is the actual crossfade
/// width). Log rather than linear zoom since [SkyCamera]/`NebulaScreen`
/// zoom is inherently multiplicative (min 0.3 to max 30, a 100x span) —
/// a fixed linear threshold would land at a wildly different *relative*
/// zoom depending on where in that span it fell. Narrow range — the
/// crossfade itself should happen quickly, over a small zoom change, not
/// gradually over a huge one. Only matters while [_kShowStarLabels] is
/// back on — with it off, the constellation label just stays fully
/// visible at every zoom instead of ever handing off to anything.
const double _kLabelSwitchLogZoom = 0.9; // ln(zoom) ≈ zoom 2.5
const double _kLabelFadeLogRange = 0.25; // ≈ crossfades over a ~1.6x zoom span

/// Shared by both constellation- and star-name labels — a single size
/// (not a bigger one for one kind and a smaller one for the other, as
/// tried first) reads as more consistent switching between the two.
/// Slightly smaller now that the constellation label is the only one ever
/// on screen (see [_kShowStarLabels]) and stays up throughout, rather than
/// only briefly at the widest zoom-out.
const double _kLabelFontSize = 11;

/// A single small screen-space label: a white pill with dark-navy text,
/// centered on [anchor] — always horizontal, never affected by
/// [_projectConstellationTransform]'s own rotation/skew, so it stays
/// readable no matter how the camera's turned. Colors are fixed rather
/// than pulled from the active theme — the Galaxy tab's sky is dark
/// regardless of light/dark mode, and these need to read clearly against
/// it either way.
/// Longer than this, a name gets cut short with a trailing ellipsis — a
/// long title otherwise made its own pill wide enough to overlap
/// neighboring labels, exactly what a short, fixed-width badge is meant
/// to avoid.
const int _kLabelMaxChars = 30;

String _truncateLabel(String text) {
  if (text.length <= _kLabelMaxChars) return text;
  return '${text.substring(0, _kLabelMaxChars - 1)}…';
}

void _drawPillLabel(
  Canvas canvas,
  Offset anchor,
  String text,
  double fontSize,
  double alpha,
) {
  if (alpha <= 0.01 || text.isEmpty) return;

  final textPainter = TextPainter(
    text: TextSpan(
      text: _truncateLabel(text),
      style: TextStyle(
        color: const Color(0xFF0D1220).withValues(alpha: alpha),
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        height: 1,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final paddingH = fontSize * 0.55;
  final paddingV = fontSize * 0.3;
  final rect = Rect.fromCenter(
    center: anchor,
    width: textPainter.width + paddingH * 2,
    height: textPainter.height + paddingV * 2,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
    Paint()..color = Colors.white.withValues(alpha: alpha * 0.7),
  );
  textPainter.paint(
    canvas,
    Offset(anchor.dx - textPainter.width / 2, anchor.dy - textPainter.height / 2),
  );
}

/// Paints every [placed] constellation over the shared [camera]/[zoom] —
/// reuses [ConstellationPainter] completely unmodified, once per
/// constellation, inside a save/transform/restore block that maps its own
/// local 0..1 space onto wherever [_projectConstellationTransform] puts
/// it — including that transform's rotation/skew, not just its position.
class ConstellationFieldPainter extends CustomPainter {
  const ConstellationFieldPainter({
    required this.placed,
    required this.camera,
    required this.zoom,
    required this.glowSprite,
    required this.starColor,
    required this.coreColor,
    required this.habitColor,
    required this.revision,
  });

  final List<PlacedConstellation> placed;
  final SkyCamera camera;
  final double zoom;
  final ui.Image? glowSprite;
  final Color starColor;
  final Color coreColor;
  final Color habitColor;
  final int revision;

  @override
  void paint(Canvas canvas, Size size) {
    // A constellation near the edge of the sky view projects to a center
    // point outside this canvas's own bounds — expected, since only part
    // of it should be visible. But `Stack`'s default clip only catches a
    // *Positioned* child's box exceeding its bounds; it has no way to see
    // that a CustomPainter's own raw Canvas calls drew past its size, so
    // without this the overflow paints straight through into whatever
    // sits to this pane's own left (the sidebar, on wide layouts) instead
    // of just disappearing off-screen like a real off-center object would.
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    // Shared by every constellation this frame — a crossfade between
    // constellation-name and star-name labels driven by [zoom] alone (see
    // `_kLabelSwitchLogZoom`'s own comment). Label *size* deliberately
    // doesn't vary with zoom at all right now (each kind just draws at
    // its own fixed size below) — simpler, and reads as more useful this
    // way; a zoom-scaled size may come back later.
    final logZoom = math.log(zoom);
    final starLabelAlpha = _kShowStarLabels
        ? _smoothstep(
            _kLabelSwitchLogZoom - _kLabelFadeLogRange,
            _kLabelSwitchLogZoom + _kLabelFadeLogRange,
            logZoom,
          )
        : 0.0;
    final constellationLabelAlpha = _kShowStarLabels
        ? 1 - starLabelAlpha
        : 1.0;

    for (final constellation in placed) {
      final transform = _projectConstellationTransform(
        constellation.worldPosition,
        camera,
        zoom,
        size,
        kSkyConstellationAngularSpan,
      );
      if (transform == null) continue;
      final localSizePx =
          (transform.right.distance + transform.up.distance) / 2;

      canvas.save();
      // Maps this constellation's own local 0..localSizePx square (top-left
      // origin, same space ConstellationPainter always draws in) onto
      // wherever it actually belongs on screen — including the
      // rotation/skew/foreshortening [_projectConstellationTransform]
      // computed, not just a plain translate+uniform-scale, so it reads as
      // painted onto the sphere itself rather than pasted flat over it.
      canvas.transform(
        Float64List.fromList([
          transform.right.dx / localSizePx,
          transform.right.dy / localSizePx,
          0,
          0,
          transform.up.dx / localSizePx,
          transform.up.dy / localSizePx,
          0,
          0,
          0,
          0,
          1,
          0,
          transform.center.dx -
              (transform.right.dx + transform.up.dx) / 2,
          transform.center.dy -
              (transform.right.dy + transform.up.dy) / 2,
          0,
          1,
        ]),
      );
      ConstellationPainter(
        stars: constellation.renderStars,
        glowSprite: glowSprite,
        revision: revision,
        starColor: starColor,
        coreColor: coreColor,
        habitColor: habitColor,
        edges: constellation.edges,
        linkThreshold: constellation.shape?.points.length ?? 0,
        shapeStarCount: constellation.shapeStarCount,
        // Bolder than ConstellationScreen's own single-project defaults —
        // at kSkyConstellationAngularSpan's now much smaller size, a
        // constellation needs to read through thicker lines/icons/glow
        // rather than through sheer size (which, tried first, badly
        // distorted near the edges of a wide field of view).
        lineWidthScale: 3.5,
        lineAlpha: 0.9,
        sparkleScale: 2.2,
        glowScale: 1.8,
      ).paint(canvas, Size.square(localSizePx));
      canvas.restore();

      // Labels are drawn *outside* the save/transform block above —
      // plain screen space, deliberately never subjected to the same
      // rotation/skew as the constellation itself, so they stay
      // horizontal and readable no matter how the camera's turned.
      if (constellationLabelAlpha > 0.01) {
        _drawPillLabel(
          canvas,
          transform.center + Offset(0, localSizePx * 0.55 + 10),
          constellation.project.name,
          _kLabelFontSize,
          constellationLabelAlpha,
        );
      }
      if (_kShowStarLabels && starLabelAlpha > 0.01) {
        for (final star in constellation.renderStars) {
          final starScreenPos =
              transform.center +
              transform.right * (star.position.dx - 0.5) +
              transform.up * (star.position.dy - 0.5);
          // Pushed out *away from the constellation's own center*, along
          // the same direction the star already sits from it — the
          // connecting lines all run through/near that center, so
          // radiating outward keeps a label clear of them without
          // actually knowing where every line is. Falls back to straight
          // down only for a star sitting right on the center itself,
          // where that direction is meaningless.
          //
          // The *distance* is measured from the constellation's own
          // center, like the constellation label's own offset just above
          // — not a fixed step from the star's own position — so every
          // star label clears the whole shape's outer edge the same way,
          // rather than landing just past whichever one star happens to
          // be closest to (and possibly still well inside the shape's
          // overall footprint if that star sits near its center). Never
          // closer than the star's own actual distance either, in case an
          // overflow/habit star already sits past that edge itself.
          final fromCenter = starScreenPos - transform.center;
          final outward = fromCenter.distance > 4
              ? fromCenter / fromCenter.distance
              : const Offset(0, 1);
          final labelDistance = math.max(
            fromCenter.distance,
            localSizePx * 0.55,
          );
          _drawPillLabel(
            canvas,
            transform.center + outward * (labelDistance + 14),
            star.label,
            _kLabelFontSize,
            starLabelAlpha,
          );
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ConstellationFieldPainter oldDelegate) {
    return revision != oldDelegate.revision ||
        camera != oldDelegate.camera ||
        zoom != oldDelegate.zoom ||
        glowSprite != oldDelegate.glowSprite ||
        placed.length != oldDelegate.placed.length;
  }
}
