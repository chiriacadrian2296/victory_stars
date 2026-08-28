import '../data/project_repository.dart';
import '../data/win_repository.dart';
import '../models/life_area.dart';
import '../models/win.dart';

/// Total wins logged across every project in [area], summed over that
/// area's projects — used by both Sky's aggregate area counts and the
/// Stars tab's area picker, so the two stay consistent.
int starsInArea(LifeArea area, ProjectRepository projectRepository, WinRepository winRepository) {
  var total = 0;
  for (final project in projectRepository.getProjectsForArea(area)) {
    total += winRepository.getAllForProject(project.id).length;
  }
  return total;
}

/// Groups [wins] by calendar day (time-of-day discarded), counting how many
/// were logged on each day. Used to drive the dashboard's activity heatmap
/// and streak calculations.
Map<DateTime, int> winCountsByDay(List<Win> wins) {
  final counts = <DateTime, int>{};
  for (final win in wins) {
    final day = DateTime(win.date.year, win.date.month, win.date.day);
    counts[day] = (counts[day] ?? 0) + 1;
  }
  return counts;
}

/// Groups [wins] by calendar day, summing each day's win intensities — the
/// total "brightness" for that day, used to scale the dashboard calendar's
/// per-star glow.
Map<DateTime, int> winIntensityByDay(List<Win> wins) {
  final totals = <DateTime, int>{};
  for (final win in wins) {
    final day = DateTime(win.date.year, win.date.month, win.date.day);
    totals[day] = (totals[day] ?? 0) + win.intensity;
  }
  return totals;
}

/// Consecutive days with at least one win, counting back from [today]
/// (defaults to now) until the first day with none. Zero if today has no
/// win yet — a streak that isn't still "alive" doesn't count as current.
int currentStreak(Map<DateTime, int> countsByDay, {DateTime? today}) {
  final now = today ?? DateTime.now();
  var day = DateTime(now.year, now.month, now.day);
  var streak = 0;
  while ((countsByDay[day] ?? 0) > 0) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}

/// The longest run of consecutive days with at least one win, anywhere in
/// [countsByDay] — not necessarily ending today.
int longestStreak(Map<DateTime, int> countsByDay) {
  if (countsByDay.isEmpty) return 0;
  final days = countsByDay.keys.toList()..sort();
  var longest = 1;
  var current = 1;
  for (var i = 1; i < days.length; i++) {
    final gap = days[i].difference(days[i - 1]).inDays;
    current = gap == 1 ? current + 1 : 1;
    if (current > longest) longest = current;
  }
  return longest;
}
