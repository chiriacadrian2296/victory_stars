import '../data/project_repository.dart';
import '../data/star_repository.dart';
import '../models/life_area.dart';
import '../models/star.dart';

/// Total victories logged across every project in [area], summed over that
/// area's projects — used by both Sky's aggregate area counts and the
/// Stars tab's area picker, so the two stay consistent. Goals and dead stars
/// don't count as a "star" here — only achieved ones do.
int starsInArea(
  LifeArea area,
  ProjectRepository projectRepository,
  StarRepository starRepository,
) {
  var total = 0;
  for (final project in projectRepository.getProjectsForArea(area)) {
    total += starRepository
        .getAllForProject(project.id)
        .where((s) => s.isLit)
        .length;
  }
  return total;
}

/// Total intensity of every achieved victory across every project in
/// [area], summed the same way [starsInArea] sums counts — used by the
/// Supernova detail screen's big stat row.
int totalIntensityInArea(
  LifeArea area,
  ProjectRepository projectRepository,
  StarRepository starRepository,
) {
  var total = 0;
  for (final project in projectRepository.getProjectsForArea(area)) {
    for (final star in starRepository.getAllForProject(project.id)) {
      if (star.isLit) total += star.intensity ?? 0;
    }
  }
  return total;
}

/// Groups achieved [stars] by calendar day (time-of-day discarded, [Star.dead]
/// and unachieved goals excluded by the caller before this is called),
/// counting how many were achieved on each day. Used to drive the
/// dashboard's activity heatmap and streak calculations.
Map<DateTime, int> starCountsByDay(List<Star> stars) {
  final counts = <DateTime, int>{};
  for (final star in stars) {
    final achievedDate = star.achievedDate;
    if (achievedDate == null) continue;
    final day = DateTime(
      achievedDate.year,
      achievedDate.month,
      achievedDate.day,
    );
    counts[day] = (counts[day] ?? 0) + 1;
  }
  return counts;
}

/// Groups achieved [stars] by calendar day, summing each day's intensities —
/// the total "brightness" for that day, used to scale the dashboard
/// calendar's per-star glow.
Map<DateTime, int> starIntensityByDay(List<Star> stars) {
  final totals = <DateTime, int>{};
  for (final star in stars) {
    final achievedDate = star.achievedDate;
    final intensity = star.intensity;
    if (achievedDate == null || intensity == null) continue;
    final day = DateTime(
      achievedDate.year,
      achievedDate.month,
      achievedDate.day,
    );
    totals[day] = (totals[day] ?? 0) + intensity;
  }
  return totals;
}

/// A run of consecutive days with at least one win. [length] is 0 (with
/// [start] and [end] both null) when there's nothing to report.
class StreakRange {
  const StreakRange({required this.length, this.start, this.end});

  final int length;
  final DateTime? start;
  final DateTime? end;
}

/// Consecutive days with at least one win, counting back from [today]
/// (defaults to now) until the first day with none. Zero-length if today has
/// no win yet — a streak that isn't still "alive" doesn't count as current.
int currentStreak(Map<DateTime, int> countsByDay, {DateTime? today}) {
  return currentStreakRange(countsByDay, today: today).length;
}

/// Same streak [currentStreak] measures, but with the date range it spans
/// (ending on [today]) — used by the dashboard's streak detail screen.
StreakRange currentStreakRange(
  Map<DateTime, int> countsByDay, {
  DateTime? today,
}) {
  final now = today ?? DateTime.now();
  var day = DateTime(now.year, now.month, now.day);
  final end = day;
  var streak = 0;
  while ((countsByDay[day] ?? 0) > 0) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  if (streak == 0) return const StreakRange(length: 0);
  return StreakRange(
    length: streak,
    start: end.subtract(Duration(days: streak - 1)),
    end: end,
  );
}

/// The longest run of consecutive days with at least one win, anywhere in
/// [countsByDay] — not necessarily ending today.
int longestStreak(Map<DateTime, int> countsByDay) {
  return longestStreakRange(countsByDay).length;
}

/// Same streak [longestStreak] measures, but with the date range it spans —
/// used by the dashboard's streak detail screen.
StreakRange longestStreakRange(Map<DateTime, int> countsByDay) {
  if (countsByDay.isEmpty) return const StreakRange(length: 0);
  final days = countsByDay.keys.toList()..sort();

  var longest = 1;
  var longestStart = days.first;
  var longestEnd = days.first;
  var currentLength = 1;
  var currentStart = days.first;
  for (var i = 1; i < days.length; i++) {
    final gap = days[i].difference(days[i - 1]).inDays;
    if (gap == 1) {
      currentLength++;
    } else {
      currentLength = 1;
      currentStart = days[i];
    }
    if (currentLength > longest) {
      longest = currentLength;
      longestStart = currentStart;
      longestEnd = days[i];
    }
  }
  return StreakRange(length: longest, start: longestStart, end: longestEnd);
}
