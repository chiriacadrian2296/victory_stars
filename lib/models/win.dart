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
  });

  final int id;
  final int number;
  final int projectId;
  final String title;
  final String? description;
  final DateTime date;

  Win copyWith({
    int? id,
    int? number,
    int? projectId,
    String? title,
    String? description,
    DateTime? date,
  }) {
    return Win(
      id: id ?? this.id,
      number: number ?? this.number,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
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
        other.date == date;
  }

  @override
  int get hashCode => Object.hash(id, number, projectId, title, description, date);
}
