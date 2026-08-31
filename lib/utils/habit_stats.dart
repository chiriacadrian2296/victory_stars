import '../models/habit_completion.dart';

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Groups [completions] by calendar day, counting how many were logged on
/// each day — always 0 or 1 for a single habit (see
/// [HabitCompletionRepository.markDone]'s idempotency), but this also feeds
/// [StarHeatmap] which expects a count map.
Map<DateTime, int> habitCompletionCountsByDay(
  List<HabitCompletion> completions,
) {
  final counts = <DateTime, int>{};
  for (final completion in completions) {
    final day = _dateOnly(completion.date);
    counts[day] = (counts[day] ?? 0) + 1;
  }
  return counts;
}

/// Whether a habit's star should currently read as lit, given the set of
/// days it's been completed on.
///
/// True as soon as either today or yesterday has been completed: at 9am,
/// having completed yesterday but not yet today, the habit is still lit —
/// there's time left before today's implicit midnight deadline. The instant
/// the calendar rolls to a new day without that day having been completed,
/// both checks turn false and the star goes dark immediately — this looks
/// back exactly one day, never further, which is what gives the "no grace
/// period beyond one day" behavior.
bool isHabitLit(Set<DateTime> completedDays, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final yesterday = today.subtract(const Duration(days: 1));
  return completedDays.contains(today) || completedDays.contains(yesterday);
}

/// Consecutive days completed, counting back from today if already done
/// today, or from yesterday otherwise (so a streak still reports its true,
/// growing length before today's box is checked) — 0 once the habit isn't
/// lit at all (see [isHabitLit]).
///
/// Deliberately not a generalization of `star_stats.dart`'s `currentStreak`
/// (which requires today specifically to have a value) — a habit's
/// one-day grace before the deadline needs different anchoring.
int habitCurrentStreak(Set<DateTime> completedDays, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  if (!isHabitLit(completedDays, now: today)) return 0;

  var day = completedDays.contains(today)
      ? today
      : today.subtract(const Duration(days: 1));
  var streak = 0;
  while (completedDays.contains(day)) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}
