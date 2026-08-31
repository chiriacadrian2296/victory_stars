/// v1 supports only [daily] — kept as an enum (rather than hardcoding "once a
/// day" straight into the logic) so a future weekly/custom frequency is a new
/// value plus new handling, not a schema rewrite.
enum HabitFrequency { daily }

/// A recurring habit tracked separately from a project's constellation shape
/// — its own small, scattered star, lit only while its daily streak (see
/// `habit_stats.dart`) is unbroken.
class Habit {
  const Habit({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    required this.createdAt,
    this.frequency = HabitFrequency.daily,
    this.targetPerPeriod = 1,
    this.reminderHour,
    this.reminderMinute,
  });

  final int id;
  final int projectId;
  final String title;
  final String? description;
  final DateTime createdAt;

  /// Always [HabitFrequency.daily] in v1.
  final HabitFrequency frequency;

  /// Always 1 in v1 — stored explicitly rather than assumed, so "twice a
  /// day" is a value change later, not a schema rewrite.
  final int targetPerPeriod;

  /// null = inherits the app's single global reminder time
  /// ([SettingsController]). Not yet acted on by [ReminderService] in v1 —
  /// see its own doc comment.
  final int? reminderHour;
  final int? reminderMinute;

  Habit copyWith({
    int? id,
    int? projectId,
    String? title,
    String? description,
    DateTime? createdAt,
    HabitFrequency? frequency,
    int? targetPerPeriod,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return Habit(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      frequency: frequency ?? this.frequency,
      targetPerPeriod: targetPerPeriod ?? this.targetPerPeriod,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as int,
      projectId: json['projectId'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      frequency: HabitFrequency.values.byName(
        json['frequency'] as String? ?? 'daily',
      ),
      targetPerPeriod: json['targetPerPeriod'] as int? ?? 1,
      reminderHour: json['reminderHour'] as int?,
      reminderMinute: json['reminderMinute'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'frequency': frequency.name,
      'targetPerPeriod': targetPerPeriod,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is Habit &&
        other.id == id &&
        other.projectId == projectId &&
        other.title == title &&
        other.description == description &&
        other.createdAt == createdAt &&
        other.frequency == frequency &&
        other.targetPerPeriod == targetPerPeriod &&
        other.reminderHour == reminderHour &&
        other.reminderMinute == reminderMinute;
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    title,
    description,
    createdAt,
    frequency,
    targetPerPeriod,
    reminderHour,
    reminderMinute,
  );
}
