import '../models/habit.dart';
import '../models/habit_completion.dart';

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Monday of the calendar week containing [day] — [HabitFrequency.weekly]'s
/// own period boundary, a hard reset every Monday rather than a rolling
/// 7-day window (`DateTime.weekday` is 1 for Monday..7 for Sunday).
DateTime _weekStart(DateTime day) =>
    day.subtract(Duration(days: day.weekday - 1));

/// Groups [completions] by calendar day, counting how many were logged on
/// each day — 0 or 1 for a [HabitFrequency.daily] habit whose target is 1
/// (see [HabitCompletionRepository.markDone]'s idempotency), but can be
/// higher for a daily habit whose target is more than 1 (see
/// [HabitCompletionRepository.logInstance]) or for [StarHeatmap], which
/// expects a count map regardless.
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

/// Whether [day] counts as "met" for [habit] — the one place both
/// frequencies' own definition of a satisfied day lives. A [daily] habit
/// needs that day's own count to reach [Habit.targetPerPeriod] (e.g. 3 of 3
/// meditation sessions); a [weekly] habit only needs *a* completion that
/// day — its target is a count of distinct days, not a per-day count, so a
/// second same-day session never counts as a second day.
bool _dayMet(Habit habit, Map<DateTime, int> countsByDay, DateTime day) {
  final count = countsByDay[day] ?? 0;
  return habit.frequency == HabitFrequency.daily
      ? count >= habit.targetPerPeriod
      : count >= 1;
}

/// How many of [weekStart]'s own 7 days (Monday..Sunday) are [_dayMet] —
/// safe to call on a week still in progress, since a day that hasn't
/// happened yet simply has no completions and so isn't met, the same as a
/// missed one; it never needs to be excluded separately.
int _weekMetDays(Habit habit, Map<DateTime, int> countsByDay, DateTime weekStart) {
  var count = 0;
  for (var i = 0; i < 7; i++) {
    if (_dayMet(habit, countsByDay, weekStart.add(Duration(days: i)))) {
      count++;
    }
  }
  return count;
}

/// Whether a habit's star should currently read as lit, given how many
/// times it's been completed on which days.
///
/// [HabitFrequency.daily]: true as soon as either today or yesterday has
/// met [Habit.targetPerPeriod] — at 9am, having met yesterday's target but
/// not yet today's, the habit is still lit, since there's time left before
/// today's implicit midnight deadline. The instant the calendar rolls to a
/// new day without that day's target having been met, both checks turn
/// false and the star goes dark immediately — this looks back exactly one
/// day, never further.
///
/// [HabitFrequency.weekly]: true once this calendar week (Monday reset, no
/// grace across the boundary) has already met its target, **or** while
/// meeting it by Sunday is still mathematically possible — i.e. the days
/// already met plus every day still left in the week (today included) add
/// up to at least the target. It only goes dark the moment that stops being
/// true, not the instant a single day is skipped.
bool isHabitLit(Habit habit, Map<DateTime, int> countsByDay, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  if (habit.frequency == HabitFrequency.daily) {
    final yesterday = today.subtract(const Duration(days: 1));
    return _dayMet(habit, countsByDay, today) ||
        _dayMet(habit, countsByDay, yesterday);
  }

  final weekStart = _weekStart(today);
  final doneDays = _weekMetDays(habit, countsByDay, weekStart);
  if (doneDays >= habit.targetPerPeriod) return true;
  final daysElapsed = today.difference(weekStart).inDays + 1;
  final daysRemaining = 7 - daysElapsed;
  return doneDays + daysRemaining >= habit.targetPerPeriod;
}

/// [HabitFrequency.daily]: today's raw completion count, for a "2/3 today"
/// progress display on a habit whose target is more than 1 — meaningless
/// (always 0 or 1) for a target of exactly 1, so callers only show this for
/// `targetPerPeriod > 1`.
int habitDailyProgress(
  Habit habit,
  Map<DateTime, int> countsByDay, {
  DateTime? now,
}) {
  final today = _dateOnly(now ?? DateTime.now());
  return countsByDay[today] ?? 0;
}

/// [HabitFrequency.weekly]: how many of this calendar week's days have
/// already been met, for a "2/3 this week" progress display.
int habitWeeklyProgress(
  Habit habit,
  Map<DateTime, int> countsByDay, {
  DateTime? now,
}) {
  final today = _dateOnly(now ?? DateTime.now());
  return _weekMetDays(habit, countsByDay, _weekStart(today));
}

/// Consecutive periods met — days for [HabitFrequency.daily], calendar
/// weeks for [HabitFrequency.weekly] — 0 once the habit isn't lit at all
/// (see [isHabitLit]).
///
/// Deliberately not a generalization of `star_stats.dart`'s `currentStreak`
/// (which requires today specifically to have a value) — a habit's own
/// grace before its deadline needs different anchoring per frequency.
int habitCurrentStreak(
  Habit habit,
  Map<DateTime, int> countsByDay, {
  DateTime? now,
}) {
  final today = _dateOnly(now ?? DateTime.now());
  if (!isHabitLit(habit, countsByDay, now: today)) return 0;

  if (habit.frequency == HabitFrequency.daily) {
    var day = _dayMet(habit, countsByDay, today)
        ? today
        : today.subtract(const Duration(days: 1));
    var streak = 0;
    while (_dayMet(habit, countsByDay, day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // A week still in progress only joins the streak once it's actually met
  // its target — [isHabitLit] can already be true purely because meeting it
  // by Sunday is still *possible*, which isn't the same as having done it.
  var weekStart = _weekStart(today);
  if (_weekMetDays(habit, countsByDay, weekStart) < habit.targetPerPeriod) {
    weekStart = weekStart.subtract(const Duration(days: 7));
  }
  var streak = 0;
  while (_weekMetDays(habit, countsByDay, weekStart) >= habit.targetPerPeriod) {
    streak++;
    weekStart = weekStart.subtract(const Duration(days: 7));
  }
  return streak;
}
