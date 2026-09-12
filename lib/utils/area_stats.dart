import '../data/habit_completion_repository.dart';
import '../data/habit_repository.dart';
import '../data/project_repository.dart';
import '../data/star_repository.dart';
import '../models/life_area.dart';
import '../utils/habit_stats.dart';

/// Open (not yet achieved, not dead) goals across every project in [area] —
/// mirrors `star_stats.dart`'s [starsInArea], same "loop over the area's
/// projects, sum per-project" pattern.
int openGoalsInArea(
  LifeArea area,
  ProjectRepository projectRepository,
  StarRepository starRepository,
) {
  var total = 0;
  for (final project in projectRepository.getProjectsForArea(area)) {
    total += starRepository
        .getAllForProject(project.id)
        .where((s) => s.isUnlit)
        .length;
  }
  return total;
}

/// Currently-lit habits across every project in [area].
int litHabitsInArea(
  LifeArea area,
  ProjectRepository projectRepository,
  HabitRepository habitRepository,
  HabitCompletionRepository habitCompletionRepository,
) {
  var total = 0;
  for (final project in projectRepository.getProjectsForArea(area)) {
    for (final habit in habitRepository.getAllForProject(project.id)) {
      final countsByDay = habitCompletionCountsByDay(
        habitCompletionRepository.getAllForHabit(habit.id),
      );
      if (isHabitLit(habit, countsByDay)) total++;
    }
  }
  return total;
}
