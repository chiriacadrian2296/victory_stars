import 'package:flutter/material.dart';

import '../data/habit_completion_repository.dart';
import '../data/habit_repository.dart';
import '../data/project_repository.dart';
import '../l10n/strings_scope.dart';
import '../models/habit.dart';
import '../models/project.dart';
import '../theme/app_colors.dart';
import '../utils/habit_stats.dart';
import '../widgets/area_tag.dart';
import '../widgets/project_tag.dart';
import '../widgets/star_heatmap.dart';
import 'add_habit_screen.dart';

/// A habit's own detail/dashboard screen — current streak, a
/// [StarHeatmap] of its completion history, and a big "mark today done"
/// action. Not a prev/next full-bleed browser like [StarReaderScreen]: a
/// habit isn't "one of a sequence of past moments", it's a single ongoing
/// thing.
class HabitReaderScreen extends StatefulWidget {
  const HabitReaderScreen({
    super.key,
    required this.habit,
    required this.project,
    required this.habitRepository,
    required this.habitCompletionRepository,
    required this.projectRepository,
  });

  final Habit habit;
  final Project? project;
  final HabitRepository habitRepository;
  final HabitCompletionRepository habitCompletionRepository;
  final ProjectRepository projectRepository;

  @override
  State<HabitReaderScreen> createState() => _HabitReaderScreenState();
}

class _HabitReaderScreenState extends State<HabitReaderScreen> {
  late Habit _habit = widget.habit;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _toggleToday(bool done) async {
    if (done) {
      await widget.habitCompletionRepository.unmarkDone(_habit.id, _today);
    } else {
      await widget.habitCompletionRepository.markDone(_habit.id);
    }
    setState(() {});
  }

  Future<void> _edit() async {
    final result = await Navigator.of(context).push<Object>(
      MaterialPageRoute(
        builder: (_) => AddHabitScreen(
          existingHabit: _habit,
          contextProject: widget.project,
          projectRepository: widget.projectRepository,
        ),
      ),
    );
    if (result == null) return;

    if (result is AddHabitDeleteRequested) {
      await widget.habitRepository.delete(
        _habit.id,
        completionRepository: widget.habitCompletionRepository,
      );
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final addResult = result as AddHabitResult;
    final updated = await widget.habitRepository.update(
      id: _habit.id,
      title: addResult.title,
      description: addResult.description,
      projectId: addResult.projectId,
      reminderHour: addResult.reminderHour,
      reminderMinute: addResult.reminderMinute,
    );
    setState(() => _habit = updated);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final completions = widget.habitCompletionRepository.getAllForHabit(
      _habit.id,
    );
    final countsByDay = habitCompletionCountsByDay(completions);
    final completedDays = countsByDay.keys.toSet();
    final streak = habitCurrentStreak(completedDays);
    final doneToday = countsByDay.containsKey(_today);

    return Scaffold(
      backgroundColor: colors.night,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.arrow_back, color: colors.muted),
                ),
                Expanded(
                  child: Text(
                    _habit.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: colors.text,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: _edit,
                  icon: Icon(Icons.edit_outlined, color: colors.muted),
                ),
              ],
            ),
            if (widget.project != null) ...[
              const SizedBox(height: 8),
              AreaTag(area: widget.project!.area, iconSize: 20, fontSize: 16),
              const SizedBox(height: 6),
              ProjectTag(project: widget.project!, fontSize: 14),
            ],
            if (_habit.description != null) ...[
              const SizedBox(height: 14),
              Text(
                _habit.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.muted,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Text(
                    '$streak',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: colors.gold,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.habitCurrentStreakLabel,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.muted,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.nightPanel,
                border: Border.all(color: colors.nightBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: StarHeatmap(
                countsByDay: countsByDay,
                intensityByDay: countsByDay,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _toggleToday(doneToday),
                icon: Icon(
                  doneToday ? Icons.check_circle : Icons.radio_button_unchecked,
                ),
                label: Text(
                  doneToday
                      ? strings.habitDoneTodayLabel
                      : strings.markHabitDoneAction,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: doneToday ? colors.nightPanel : colors.gold,
                  foregroundColor: doneToday ? colors.gold : colors.onGold,
                  side: doneToday ? BorderSide(color: colors.gold) : null,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            if (doneToday) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => _toggleToday(true),
                  child: Text(
                    strings.undoHabitTodayAction,
                    style: TextStyle(color: colors.muted),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
