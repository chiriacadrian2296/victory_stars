import 'life_area.dart';

/// A user-created project within a [LifeArea] (e.g. "Build this app" under
/// Professional). Its [iconSlug] selects which precomputed constellation
/// shape (see constellation_shapes.dart) its wins light up stars in.
class Project {
  const Project({
    required this.id,
    required this.name,
    required this.area,
    required this.iconSlug,
    required this.createdAt,
  });

  final int id;
  final String name;
  final LifeArea area;
  final String iconSlug;
  final DateTime createdAt;

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as int,
      name: json['name'] as String,
      area: LifeArea.values.byName(json['area'] as String),
      iconSlug: json['iconSlug'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'area': area.name,
      'iconSlug': iconSlug,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    return other is Project &&
        other.id == id &&
        other.name == name &&
        other.area == area &&
        other.iconSlug == iconSlug &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, name, area, iconSlug, createdAt);
}
