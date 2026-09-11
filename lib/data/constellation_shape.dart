// The shape a constellation is drawn from: a graph of keypoints and the
// line segments joining them.
//
// Not an icon silhouette and not a single closed path — real constellations
// branch (a figure's arms and legs, a teapot's handle), so `edges` is a free
// list of index pairs into `points` rather than an implicit "connect them in
// order" rule.
//
// Two things produce one: the in-app editor, which saves what the user drew
// as a `StarsShape`, and the ready-made library in
// `constellation_presets.dart`. Both land in the same normalized 0..1 box
// (see `normalizeEditorPoints`), so nothing downstream needs to know which
// one it's looking at.
//
// Overflow stars beyond `points.length` are NOT stored here:
// `buildConstellationLayout` (constellation_layout.dart) grows the graph by
// repeatedly bisecting its current longest edge, so the pattern thickens
// evenly instead of piling stars along one branch.
import 'dart:ui';

class ConstellationShape {
  final List<Offset> points;
  final List<(int, int)> edges;
  const ConstellationShape({required this.points, required this.edges});
}
