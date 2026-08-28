/// A single recorded victory: a moment the user got through.
///
/// [number] is a permanent progressive count assigned at creation time
/// (1, 2, 3, ...) and never changes afterwards, even if earlier wins are
/// later removed — it's the "this is your Nth star" label, not a list index.
class Win {
  const Win({
    required this.id,
    required this.number,
    required this.projectId,
    required this.title,
    this.description,
    required this.date,
    required this.intensity,
    this.photoPath,
  }) : assert(intensity >= 1 && intensity <= 5, 'intensity must be 1-5, was $intensity');

  final int id;
  final int number;
  final int projectId;
  final String title;
  final String? description;
  final DateTime date;

  /// How much effort/suffering this win took, 1 (light) to 5 (a lot) — named
  /// to fit the app's star metaphor, like a star's own intensity.
  final int intensity;

  /// Absolute path to an optional photo attached to this win, copied into
  /// app-private storage by [PhotoStorage.save] at pick time (never a raw
  /// picker/cache path, which isn't guaranteed to survive).
  final String? photoPath;

  Win copyWith({
    int? id,
    int? number,
    int? projectId,
    String? title,
    String? description,
    DateTime? date,
    int? intensity,
    String? photoPath,
  }) {
    return Win(
      id: id ?? this.id,
      number: number ?? this.number,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      intensity: intensity ?? this.intensity,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  factory Win.fromJson(Map<String, dynamic> json) {
    return Win(
      id: json['id'] as int,
      number: json['number'] as int,
      projectId: json['projectId'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      intensity: json['intensity'] as int,
      // Absent in every win saved before this field existed — treated as no
      // photo rather than a migration, same as a missing 'description'.
      photoPath: json['photoPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'projectId': projectId,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'intensity': intensity,
      'photoPath': photoPath,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is Win &&
        other.id == id &&
        other.number == number &&
        other.projectId == projectId &&
        other.title == title &&
        other.description == description &&
        other.date == date &&
        other.intensity == intensity &&
        other.photoPath == photoPath;
  }

  @override
  int get hashCode => Object.hash(id, number, projectId, title, description, date, intensity, photoPath);
}
