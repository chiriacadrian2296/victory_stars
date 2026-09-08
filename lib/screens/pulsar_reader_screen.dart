import 'package:flutter/material.dart';

import '../data/custom_constellation_repository.dart';
import '../data/habit_completion_repository.dart';
import '../data/habit_repository.dart';
import '../data/project_repository.dart';
import '../l10n/strings_scope.dart';
import '../models/habit.dart';
import '../models/project.dart';
import '../models/star_kind.dart';
import '../theme/app_colors.dart';
import '../utils/habit_stats.dart';
import '../widgets/area_tag.dart';
import '../widgets/intensity_bolts.dart';
import '../widgets/project_tag.dart';
import '../widgets/responsive_content.dart';
import '../widgets/star_glyph.dart';
import '../widgets/star_heatmap.dart';
import 'star_form_screen.dart';

/// A pulsar's own detail/dashboard screen — current streak, the intensity
/// of the effort it costs each day, a [StarHeatmap] of its history, and a
/// big "mark today done" action. Not a prev/next full-bleed browser like
/// [StarReaderScreen]: a pulsar isn't one of a sequence of past moments,
/// it's a single ongoing thing.
///
/// A pulsar that's been deleted is a dead star (see [Habit.dead]) — this
/// screen then drops the whole dashboard and offers only what a dead star
/// can do: be reignited, always as a pulsar again.
class PulsarReaderScreen extends StatefulWidget {
  const PulsarReaderScreen({
    super.key,
    required this.habit,
    required this.project,
    required this.habitRepository,
    required this.habitCompletionRepository,
    required this.projectRepository,
    required this.customConstellationRepository,
  });

  final Habit habit;
  final Project? project;
  final HabitRepository habitRepository;
  final HabitCompletionRepository habitCompletionRepository;
  final ProjectRepository projectRepository;
  final CustomConstellationRepository customConstellationRepository;

  @override
  State<PulsarReaderScreen> createState() => _PulsarReaderScreenState();
}

class _PulsarReaderScreenState extends State<PulsarReaderScreen> {
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
        builder: (_) => StarFormScreen(
          existingHabit: _habit,
          contextProject: widget.project,
          projectRepository: widget.projectRepository,
          customConstellationRepository: widget.customConstellationRepository,
        ),
      ),
    );
    if (result == null) return;

    // A tombstone, not an erasure — the pulsar stays in the sky as a dead
    // star. Popping back out is still right: what's left isn't this
    // dashboard, and the caller reloads either way.
    if (result is StarFormDeleteRequested) {
      await widget.habitRepository.delete(_habit.id);
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final formResult = result as StarFormResult;
    final updated = await widget.habitRepository.update(
      id: _habit.id,
      title: formResult.title,
      description: formResult.description,
      projectId: formResult.projectId,
      intensity: formResult.intensity ?? _habit.intensity,
      reminderHour: formResult.reminderHour,
      reminderMinute: formResult.reminderMinute,
    );
    setState(() => _habit = updated);
  }

  /// Brings this dead pulsar back — as a pulsar, never as anything else.
  /// What a dead star can become is decided by what it was, so the form
  /// opens locked to [StarKind.pulsar] with no kind switch at all.
  Future<void> _reignite() async {
    final result = await Navigator.of(context).push<Object>(
      MaterialPageRoute(
        builder: (_) => StarFormScreen(
          existingHabit: _habit,
          contextProject: widget.project,
          projectRepository: widget.projectRepository,
          customConstellationRepository: widget.customConstellationRepository,
          hideDelete: true,
        ),
      ),
    );
    if (result is! StarFormResult) return;
    final updated = await widget.habitRepository.resurrect(
      _habit.id,
      title: result.title,
      description: result.description,
      projectId: result.projectId,
      intensity: result.intensity ?? _habit.intensity,
      reminderHour: result.reminderHour,
      reminderMinute: result.reminderMinute,
      completionRepository: widget.habitCompletionRepository,
    );
    if (mounted) setState(() => _habit = updated);
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
          // The scrollable itself spans the full window width (so its
          // auto-attached Scrollbar sits at the true page edge on wide
          // viewports); only its content is capped/centered.
          children: [
            ResponsiveContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      if (!_habit.dead)
                        IconButton(
                          onPressed: _edit,
                          icon: Icon(Icons.edit_outlined, color: colors.muted),
                        ),
                    ],
                  ),
                  if (widget.project != null) ...[
                    const SizedBox(height: 8),
                    AreaTag(
                      area: widget.project!.area,
                      iconSize: 20,
                      fontSize: 16,
                    ),
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
                  if (_habit.dead) ...[
                    const SizedBox(height: 36),
                    Center(child: StarGlyph(kind: StarKind.dead, size: 44)),
                    const SizedBox(height: 20),
                    Text(
                      StarKind.dead.label(strings),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      strings.deadPulsarBody,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: colors.muted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _reignite,
                        icon: const Icon(Icons.auto_fix_high),
                        label: Text(strings.reigniteAction),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.gold,
                          foregroundColor: colors.onGold,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
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
                        const SizedBox(height: 16),
                        // What keeping this up costs you on any given day —
                        // the same 1-5 scale every other kind of star
                        // carries, and the reason a two-minute habit and a
                        // punishing one don't read as the same thing.
                        IntensityBolts(
                          intensity: _habit.intensity,
                          size: 20,
                          spacing: 4,
                          emphasizeLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    clipBehavior: Clip.antiAlias,
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
                        doneToday
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                      ),
                      label: Text(
                        doneToday
                            ? strings.habitDoneTodayLabel
                            : strings.markHabitDoneAction,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: doneToday
                            ? colors.nightPanel
                            : colors.gold,
                        foregroundColor: doneToday
                            ? colors.gold
                            : colors.onGold,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
