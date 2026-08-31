import 'dart:math' as math;
import 'dart:ui';

import 'constellation_shapes_v2.dart';

/// A shape's graph grows this large before overflow stars stop being woven
/// into the constellation and start scattering instead (see
/// [seededOverflowPosition]) — a guard against the O(n²) longest-edge search
/// below getting expensive for a project with an implausible number of wins.
const int maxChainedStars = 600;

/// The result of growing a [ConstellationShape] to a target star count:
/// every star's position, and every line segment (as index pairs into
/// [points]) that should connect them.
class ConstellationLayout {
  const ConstellationLayout({required this.points, required this.edges});

  final List<Offset> points;
  final List<(int, int)> edges;
}

/// Grows [shape]'s fixed graph up to [count] stars by repeatedly finding
/// whichever edge in the current graph is longest, and splitting it in two
/// with a new star at its midpoint.
///
/// This is what replaces sequential placement along a precomputed dense
/// outline: because the *longest remaining edge* is always the one split
/// next, the pattern thickens evenly across every branch as wins are
/// logged, instead of concentrating new stars along whichever stretch
/// happens to come next in a fixed list. Works the same whether the shape's
/// base graph is a simple path, a closed loop, or — as with a figure's arms
/// and legs, or a teapot's handle — branches. The result is deterministic
/// for a given [count]: recomputing it from scratch always reproduces the
/// same positions, so a star's place in the sky never shifts as more are
/// added.
ConstellationLayout buildConstellationLayout(
  ConstellationShape shape,
  int count,
) {
  final basePoints = shape.points;
  if (count <= 0 || basePoints.isEmpty) {
    return const ConstellationLayout(points: [], edges: []);
  }
  if (count <= basePoints.length) {
    return ConstellationLayout(
      points: basePoints.sublist(0, count),
      edges: shape.edges,
    );
  }

  final points = List<Offset>.from(basePoints);
  final edges = List<(int, int)>.from(shape.edges);
  final target = math.min(count, maxChainedStars);

  while (points.length < target) {
    var longestIndex = 0;
    var longestDistanceSq = -1.0;
    for (var i = 0; i < edges.length; i++) {
      final (a, b) = edges[i];
      final distanceSq = (points[a] - points[b]).distanceSquared;
      if (distanceSq > longestDistanceSq) {
        longestDistanceSq = distanceSq;
        longestIndex = i;
      }
    }
    final (a, b) = edges[longestIndex];
    final midpoint = Offset(
      (points[a].dx + points[b].dx) / 2,
      (points[a].dy + points[b].dy) / 2,
    );
    final newIndex = points.length;
    points.add(midpoint);
    edges[longestIndex] = (a, newIndex);
    edges.add((newIndex, b));
  }
  return ConstellationLayout(points: points, edges: edges);
}

Offset _seededScatter(
  int seed, {
  required double minRadius,
  required double maxRadius,
}) {
  final random = math.Random(seed);
  final angle = random.nextDouble() * 2 * math.pi;
  final radius = minRadius + random.nextDouble() * (maxRadius - minRadius);
  return Offset(0.5 + radius * math.cos(angle), 0.5 + radius * math.sin(angle));
}

/// Deterministic placement for a star beyond [maxChainedStars] — vanishingly
/// rare, but must never crash or lose a star. Seeded by the star's own
/// immutable id (never by its position in the list), so a star's position
/// can't shift if the list is ever reordered.
Offset seededOverflowPosition(int seed) =>
    _seededScatter(seed, minRadius: 0.55, maxRadius: 1.0);

/// Deterministic placement for a habit's own small, scattered star — a
/// closer band that overlaps the constellation's own footprint (habits sit
/// "around/inside/outside" the shape, not past its edge like overflow
/// stars), seeded by the habit's own immutable id.
Offset seededHabitPosition(int seed) =>
    _seededScatter(seed, minRadius: 0.15, maxRadius: 0.65);
