/// One day a [Habit] was completed. Day-granularity only — [date] is always
/// normalized to midnight at write time (see `HabitCompletionRepository`),
/// since time-of-day is meaningless for a "once a day" target.
class HabitCompletion {
  const HabitCompletion({
    required this.id,
    required this.habitId,
    required this.date,
  });

  final int id;
  final int habitId;
  final DateTime date;

  factory HabitCompletion.fromJson(Map<String, dynamic> json) {
    return HabitCompletion(
      id: json['id'] as int,
      habitId: json['habitId'] as int,
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'habitId': habitId, 'date': date.toIso8601String()};
  }

  @override
  bool operator ==(Object other) {
    return other is HabitCompletion &&
        other.id == id &&
        other.habitId == habitId &&
        other.date == date;
  }

  @override
  int get hashCode => Object.hash(id, habitId, date);
}
