import 'life_area.dart';

/// A user-created project within a [LifeArea] (e.g. "Build this app" under
/// Professional). Its [iconSlug] selects only the badge icon shown in
/// project lists — purely cosmetic, unrelated to its constellation. The
/// actual shape its wins light up stars in is the hand-drawn
/// [customConstellationId] (see `CustomConstellationRepository`), which
/// every project is expected to have — `NewProjectScreen` requires picking
/// or drawing one before a project can be created. It's still nullable here
/// because pre-editor projects only get one lazily, via
/// `backfillMissingConstellations`.
class Project {
  const Project({
    required this.id,
    required this.name,
    required this.area,
    required this.iconSlug,
    this.customConstellationId,
    this.description,
    required this.createdAt,
  });

  final int id;
  final String name;
  final LifeArea area;
  final String iconSlug;
  final int? customConstellationId;

  /// Optional, freeform — what this project is about. Never required,
  /// unlike [name].
  final String? description;
  final DateTime createdAt;

  Project copyWith({
    int? id,
    String? name,
    LifeArea? area,
    String? iconSlug,
    int? customConstellationId,
    String? description,
    DateTime? createdAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      area: area ?? this.area,
      iconSlug: iconSlug ?? this.iconSlug,
      customConstellationId: customConstellationId ?? this.customConstellationId,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as int,
      name: json['name'] as String,
      area: LifeArea.values.byName(json['area'] as String),
      iconSlug: json['iconSlug'] as String,
      customConstellationId: json['customConstellationId'] as int?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'area': area.name,
      'iconSlug': iconSlug,
      if (customConstellationId != null)
        'customConstellationId': customConstellationId,
      if (description != null) 'description': description,
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
        other.customConstellationId == customConstellationId &&
        other.description == description &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    area,
    iconSlug,
    customConstellationId,
    description,
    createdAt,
  );
}
