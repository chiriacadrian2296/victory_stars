import 'dart:ui';

import '../data/constellation_shapes_v2.dart';

/// A constellation shape a user drew themselves in the in-app editor (see
/// `ConstellationEditorScreen`), saved under its own name and reusable
/// across projects — as opposed to the 20 built-in [ConstellationShape]s in
/// `constellation_shapes_v2.dart`, which are fixed and shared by everyone.
/// Wraps a [ConstellationShape] rather than duplicating its `points`/`edges`
/// fields, so every existing consumer of that class (`buildConstellationLayout`,
/// `boundingBoxOf`, `ConstellationPainter`) accepts it unchanged.
///
/// Only ever has a [name] — no description. A shape is a reusable pattern
/// (the same one can be picked for more than one project), so "what it
/// means" belongs to whichever project is using it, not to the shape
/// itself — see `Project.description` for that.
class CustomConstellation {
  const CustomConstellation({
    required this.id,
    required this.name,
    required this.shape,
    required this.createdAt,
  });

  final int id;
  final String name;
  final ConstellationShape shape;
  final DateTime createdAt;

  factory CustomConstellation.fromJson(Map<String, dynamic> json) {
    return CustomConstellation(
      id: json['id'] as int,
      name: json['name'] as String,
      shape: ConstellationShape(
        points: (json['points'] as List<dynamic>)
            .map(
              (p) => Offset(
                (p as List<dynamic>)[0] as double,
                p[1] as double,
              ),
            )
            .toList(),
        edges: (json['edges'] as List<dynamic>)
            .map(
              (e) =>
                  ((e as List<dynamic>)[0] as int, e[1] as int),
            )
            .toList(),
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'points': shape.points.map((p) => [p.dx, p.dy]).toList(),
      'edges': shape.edges.map((e) => [e.$1, e.$2]).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (other is! CustomConstellation) return false;
    if (other.id != id ||
        other.name != name ||
        other.createdAt != createdAt ||
        other.shape.points.length != shape.points.length ||
        other.shape.edges.length != shape.edges.length) {
      return false;
    }
    for (var i = 0; i < shape.points.length; i++) {
      if (other.shape.points[i] != shape.points[i]) return false;
    }
    for (var i = 0; i < shape.edges.length; i++) {
      if (other.shape.edges[i] != shape.edges[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    createdAt,
    Object.hashAll(shape.points),
    Object.hashAll(shape.edges),
  );
}
