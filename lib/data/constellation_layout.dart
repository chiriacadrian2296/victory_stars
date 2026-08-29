import 'dart:math' as math;
import 'dart:ui';

import 'constellation_shapes_v2.dart';

/// A shape's connected chain grows this large before overflow stars stop
/// being woven into the pictogram and start scattering instead (see
/// [seededOverflowPosition]) — a guard against the O(n²) bisection search
/// below getting expensive for a project with an implausible number of wins.
const int maxChainedStars = 600;

/// Grows [shape]'s fixed [ConstellationShape.points] outline up to [count]
/// stars by repeatedly bisecting whichever edge of the current chain is
/// currently longest, and inserting the new star at its midpoint.
///
/// This is what replaces sequential placement along a precomputed dense
/// outline: because the *longest remaining gap* is always the one filled
/// next, the pattern thickens evenly on all sides as wins are logged,
/// instead of concentrating new stars along whichever stretch happens to
/// come next in a fixed list. The result is deterministic for a given
/// [count] — recomputing it from scratch always reproduces the same
/// positions, so a star's place in the sky never shifts as more are added.
List<Offset> buildConstellationPositions(ConstellationShape shape, int count) {
  final base = shape.points;
  if (count <= 0 || base.isEmpty) return const [];
  if (count <= base.length) return base.sublist(0, count);

  final chain = List<Offset>.from(base);
  final target = math.min(count, maxChainedStars);
  while (chain.length < target) {
    final n = chain.length;
    final segmentCount = shape.closed ? n : n - 1;
    var longestIndex = 0;
    var longestDistanceSq = -1.0;
    for (var i = 0; i < segmentCount; i++) {
      final a = chain[i];
      final b = chain[(i + 1) % n];
      final distanceSq = (a - b).distanceSquared;
      if (distanceSq > longestDistanceSq) {
        longestDistanceSq = distanceSq;
        longestIndex = i;
      }
    }
    final a = chain[longestIndex];
    final b = chain[(longestIndex + 1) % chain.length];
    chain.insert(
      longestIndex + 1,
      Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2),
    );
  }
  return chain;
}

/// Deterministic placement for a win beyond [maxChainedStars] — vanishingly
/// rare, but must never crash or lose a win. Seeded by the win's own
/// immutable id (never by its position in the list), so a star's position
/// can't shift if the list is ever reordered.
Offset seededOverflowPosition(int seed) {
  final random = math.Random(seed);
  final angle = random.nextDouble() * 2 * math.pi;
  final radius = 0.55 + random.nextDouble() * 0.45;
  return Offset(0.5 + radius * math.cos(angle), 0.5 + radius * math.sin(angle));
}
