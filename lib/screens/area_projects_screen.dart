import 'package:flutter/material.dart';

import '../data/custom_constellation_repository.dart';
import '../data/habit_completion_repository.dart';
import '../data/habit_repository.dart';
import '../data/project_repository.dart';
import '../data/star_repository.dart';
import '../l10n/strings_scope.dart';
import '../models/habit.dart';
import '../models/life_area.dart';
import '../models/project.dart';
import '../models/star.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';
import '../utils/habit_stats.dart';
import '../utils/icon_for_slug.dart';
import '../widgets/constellation_painter.dart' show StarKind;
import '../widgets/dead_star_card.dart';
import '../widgets/goal_card.dart';
import '../widgets/habit_card.dart';
import '../widgets/responsive_content.dart';
import '../widgets/star_card.dart';
import 'constellation_screen.dart';
import 'habit_reader_screen.dart';
import 'star_reader_screen.dart';

enum _ViewMode { constellations, list }

/// One flat-list row — either a [Star] (victory/goal/dead, told apart by
/// [kind]) or a [Habit] (pulsar, [kind] always [StarKind.habit]) — wrapped
/// with a shared [sortKey] so the two can be merged into one newest-first
/// list without either side needing to know about the other's shape.
class _AreaEntry {
  _AreaEntry.fromStar(Star star)
    : star = star,
      habit = null,
      kind = star.dead
          ? StarKind.dead
          : (star.isAchieved ? StarKind.victory : StarKind.goal),
      sortKey = star.achievedDate ?? star.createdAt;

  _AreaEntry.fromHabit(Habit habit)
    : star = null,
      habit = habit,
      kind = StarKind.habit,
      sortKey = habit.createdAt;

  final Star? star;
  final Habit? habit;
  final StarKind kind;
  final DateTime sortKey;

  String get title => (star?.title ?? habit!.title);
  String? get description => star?.description ?? habit?.description;
}

/// One life area's detail screen — Sky's second step after picking an
/// area. Offers two views of the same underlying data, switched via a
/// segmented control:
/// - Constellations: the area's projects, each showing its lit-star count,
///   open-goal count, and active-pulsar count; tapping one opens its
///   [ConstellationScreen]. Search matches the project name.
/// - Stars: every star and pulsar in the area (across all its projects),
///   flat, newest first, with a row of toggle chips (below the
///   Constellations/Stars switch) to show/hide each kind — victories, goals,
///   dead stars, pulsars. All four are on by default. Search matches title
///   or description.
class AreaProjectsScreen extends StatefulWidget {
  const AreaProjectsScreen({
    super.key,
    required this.area,
    required this.projectRepository,
    required this.starRepository,
    required this.habitRepository,
    required this.habitCompletionRepository,
    required this.customConstellationRepository,
  });

  final LifeArea area;
  final ProjectRepository projectRepository;
  final StarRepository starRepository;
  final HabitRepository habitRepository;
  final HabitCompletionRepository habitCompletionRepository;
  final CustomConstellationRepository customConstellationRepository;

  @override
  State<AreaProjectsScreen> createState() => _AreaProjectsScreenState();
}

class _AreaProjectsScreenState extends State<AreaProjectsScreen> {
  _ViewMode _mode = _ViewMode.constellations;
  String _query = '';
  final Set<StarKind> _kindFilter = {
    StarKind.victory,
    StarKind.goal,
    StarKind.dead,
    StarKind.habit,
  };

  List<Project> get _projects =>
      widget.projectRepository.getProjectsForArea(widget.area);

  Map<int, Project> get _projectsById => {
    for (final project in _projects) project.id: project,
  };

  List<Star> _starsForProject(int projectId) =>
      widget.starRepository.getAllForProject(projectId);

  int _activeHabitCountForProject(int projectId) {
    var count = 0;
    for (final habit in widget.habitRepository.getAllForProject(projectId)) {
      if (isHabitLit(_completedDaysFor(habit.id))) count++;
    }
    return count;
  }

  Set<DateTime> _completedDaysFor(int habitId) {
    return widget.habitCompletionRepository
        .getAllForHabit(habitId)
        .map((c) => DateTime(c.date.year, c.date.month, c.date.day))
        .toSet();
  }

  List<Project> get _filteredProjects {
    final query = _query.trim().toLowerCase();
    final projects = _projects;
    if (query.isEmpty) return projects;
    return projects.where((p) => p.name.toLowerCase().contains(query)).toList();
  }

  /// Every star and pulsar across the area's projects, of every kind,
  /// newest first — the unfiltered pool the kind-filter counts and the
  /// flat list itself are both drawn from.
  List<_AreaEntry> get _allEntries {
    final projectIds = _projectsById.keys.toSet();
    final entries = <_AreaEntry>[
      for (final star in widget.starRepository.getAll())
        if (projectIds.contains(star.projectId)) _AreaEntry.fromStar(star),
      for (final projectId in projectIds)
        for (final habit in widget.habitRepository.getAllForProject(projectId))
          _AreaEntry.fromHabit(habit),
    ];
    entries.sort((a, b) => b.sortKey.compareTo(a.sortKey));
    return entries;
  }

  List<_AreaEntry> get _filteredEntries {
    final query = _query.trim().toLowerCase();
    return _allEntries.where((e) {
      if (!_kindFilter.contains(e.kind)) return false;
      if (query.isEmpty) return true;
      return e.title.toLowerCase().contains(query) ||
          (e.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  /// The star-only (victory/goal/dead) subset of [_filteredEntries], in the
  /// same order — what [StarReaderScreen]'s prev/next actually browses,
  /// since pulsars aren't part of that reader.
  List<Star> _filteredStarsOnly() {
    return _filteredEntries
        .where((e) => e.kind != StarKind.habit)
        .map((e) => e.star!)
        .toList();
  }

  Future<void> _openProject(Project project) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConstellationScreen(
          project: project,
          starRepository: widget.starRepository,
          projectRepository: widget.projectRepository,
          habitRepository: widget.habitRepository,
          habitCompletionRepository: widget.habitCompletionRepository,
          customConstellationRepository: widget.customConstellationRepository,
        ),
      ),
    );
    setState(() {});
  }

  Future<void> _openStarReader(int index) async {
    final stars = _filteredStarsOnly();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StarReaderScreen(
          repository: widget.starRepository,
          initialStars: stars,
          startIndex: index,
          allowEdit: true,
          projectsById: _projectsById,
          projectRepository: widget.projectRepository,
          customConstellationRepository: widget.customConstellationRepository,
          refreshStars: _filteredStarsOnly,
        ),
      ),
    );
    setState(() {});
  }

  Future<void> _openHabitReader(Habit habit) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HabitReaderScreen(
          habit: habit,
          project: _projectsById[habit.projectId],
          habitRepository: widget.habitRepository,
          habitCompletionRepository: widget.habitCompletionRepository,
          projectRepository: widget.projectRepository,
          customConstellationRepository: widget.customConstellationRepository,
        ),
      ),
    );
    setState(() {});
  }

  void _toggleKind(StarKind kind) {
    setState(() {
      if (!_kindFilter.remove(kind)) _kindFilter.add(kind);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final areaName = widget.area.displayName(strings);
    final allEntries = _mode == _ViewMode.list
        ? _allEntries
        : const <_AreaEntry>[];
    final filteredEntries = _mode == _ViewMode.list
        ? _filteredEntries
        : const <_AreaEntry>[];

    return Scaffold(
      backgroundColor: colors.night,
      body: SafeArea(
        child: Column(
          children: [
            // Only the fixed header chrome is width-capped here — the
            // Expanded list below stays full width so its own scrollbar
            // sits at the true page edge on wide viewports rather than
            // hugging a centered column (see ResponsiveContent's doc).
            ResponsiveContent(
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.arrow_back, color: colors.muted),
                      ),
                      Expanded(
                        child: Text(
                          areaName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: colors.text,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: SegmentedButton<_ViewMode>(
                      style: _segmentedButtonStyle(colors),
                      segments: [
                        ButtonSegment(
                          value: _ViewMode.constellations,
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: Text(strings.constellationsModeLabel),
                        ),
                        ButtonSegment(
                          value: _ViewMode.list,
                          icon: const Icon(Icons.star, size: 16),
                          label: Text(strings.listModeLabel),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (selection) =>
                          setState(() => _mode = selection.first),
                    ),
                  ),
                  if (_mode == _ViewMode.list)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      // A Row, not a Wrap — with 4 chips a label+count Wrap
                      // easily drops to a second line (worse on longer IT/RO
                      // translations), so the label lives below each chip
                      // instead (see _KindFilterChip); centered as a tight
                      // group rather than spread across the full width, so
                      // the four chips read as one control, easier to reach.
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _KindFilterChip(
                            icon: Icons.star,
                            label: strings.starKindVictoryLabel,
                            count: allEntries
                                .where((e) => e.kind == StarKind.victory)
                                .length,
                            selected: _kindFilter.contains(StarKind.victory),
                            onTap: () => _toggleKind(StarKind.victory),
                          ),
                          const SizedBox(width: 10),
                          _KindFilterChip(
                            icon: Icons.flag_outlined,
                            label: strings.starKindGoalLabel,
                            count: allEntries
                                .where((e) => e.kind == StarKind.goal)
                                .length,
                            selected: _kindFilter.contains(StarKind.goal),
                            onTap: () => _toggleKind(StarKind.goal),
                          ),
                          const SizedBox(width: 10),
                          _KindFilterChip(
                            icon: Icons.star_outline,
                            label: strings.starKindDeadLabel,
                            count: allEntries
                                .where((e) => e.kind == StarKind.dead)
                                .length,
                            selected: _kindFilter.contains(StarKind.dead),
                            onTap: () => _toggleKind(StarKind.dead),
                          ),
                          const SizedBox(width: 10),
                          _KindFilterChip(
                            icon: Icons.repeat,
                            label: strings.starKindPulsarChipLabel,
                            count: allEntries
                                .where((e) => e.kind == StarKind.habit)
                                .length,
                            selected: _kindFilter.contains(StarKind.habit),
                            onTap: () => _toggleKind(StarKind.habit),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: TextField(
                      onChanged: (value) => setState(() => _query = value),
                      style: TextStyle(color: colors.text, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: strings.searchHint,
                        prefixIcon: Icon(
                          Icons.search,
                          color: colors.muted,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _mode == _ViewMode.constellations
                  ? _ConstellationsList(
                      allProjects: _projects,
                      filteredProjects: _filteredProjects,
                      areaName: areaName,
                      starsForProject: _starsForProject,
                      activeHabitCountForProject: _activeHabitCountForProject,
                      onTap: _openProject,
                    )
                  : _FlatList(
                      hasAnyEntries: allEntries.isNotEmpty,
                      entries: filteredEntries,
                      projectsById: _projectsById,
                      completedDaysFor: _completedDaysFor,
                      onOpenStar: (entry) => _openStarReader(
                        _filteredStarsOnly().indexWhere(
                          (s) => s.id == entry.star!.id,
                        ),
                      ),
                      onOpenHabit: (habit) => _openHabitReader(habit),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConstellationsList extends StatelessWidget {
  const _ConstellationsList({
    required this.allProjects,
    required this.filteredProjects,
    required this.areaName,
    required this.starsForProject,
    required this.activeHabitCountForProject,
    required this.onTap,
  });

  final List<Project> allProjects;
  final List<Project> filteredProjects;
  final String areaName;
  final List<Star> Function(int projectId) starsForProject;
  final int Function(int projectId) activeHabitCountForProject;
  final void Function(Project) onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    if (allProjects.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Center(
          child: Text(
            strings.areaEmptyProjects(areaName),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: colors.muted),
          ),
        ),
      );
    }
    if (filteredProjects.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Center(
          child: Text(
            strings.noSearchResults,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: colors.muted),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: filteredProjects.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final project = filteredProjects[index];
        final stars = starsForProject(project.id);
        final achievedStars = stars.where((s) => s.isAchieved).toList();
        final openGoals = stars.where((s) => s.isGoal).length;
        final activeHabits = activeHabitCountForProject(project.id);
        return ResponsiveContent(
          child: _ProjectCard(
            project: project,
            starCount: achievedStars.length,
            lastStarDate: achievedStars.isEmpty
                ? null
                : achievedStars
                      .map((s) => s.achievedDate!)
                      .reduce((a, b) => a.isAfter(b) ? a : b),
            combinedIntensity: achievedStars.fold<int>(
              0,
              (sum, s) => sum + s.intensity!,
            ),
            openGoals: openGoals,
            activeHabits: activeHabits,
            onTap: () => onTap(project),
          ),
        );
      },
    );
  }
}

/// The "Stars" flat list — mixed victories/goals/dead stars/pulsars, each
/// rendered by the card suited to its kind.
class _FlatList extends StatelessWidget {
  const _FlatList({
    required this.hasAnyEntries,
    required this.entries,
    required this.projectsById,
    required this.completedDaysFor,
    required this.onOpenStar,
    required this.onOpenHabit,
  });

  final bool hasAnyEntries;
  final List<_AreaEntry> entries;
  final Map<int, Project> projectsById;
  final Set<DateTime> Function(int habitId) completedDaysFor;
  final void Function(_AreaEntry entry) onOpenStar;
  final void Function(Habit habit) onOpenHabit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    if (!hasAnyEntries) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Center(
          child: Text(
            strings.areaWinsEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: colors.muted),
          ),
        ),
      );
    }
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Center(
          child: Text(
            strings.noSearchResults,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: colors.muted),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final project =
            projectsById[entry.star?.projectId ?? entry.habit?.projectId];

        final Widget card;
        switch (entry.kind) {
          case StarKind.victory:
            card = StarCard(
              star: entry.star!,
              project: project,
              onTap: () => onOpenStar(entry),
            );
          case StarKind.goal:
            card = GoalCard(
              star: entry.star!,
              project: project,
              onTap: () => onOpenStar(entry),
            );
          case StarKind.dead:
            card = DeadStarCard(
              star: entry.star!,
              project: project,
              onTap: () => onOpenStar(entry),
            );
          case StarKind.habit:
            final habit = entry.habit!;
            final completedDays = completedDaysFor(habit.id);
            card = HabitCard(
              habit: habit,
              project: project,
              currentStreak: habitCurrentStreak(completedDays),
              isLit: isHabitLit(completedDays),
              onTap: () => onOpenHabit(habit),
            );
        }
        return ResponsiveContent(child: card);
      },
    );
  }
}

/// A toggle chip for one star kind in the "Stars" flat list — icon, label,
/// and a count that stays visible even when unselected, so the user can see
/// what they're hiding, not just what they're showing. Selected chips all
/// use the same gold look regardless of kind — the color used to vary per
/// kind, which read as each chip having its own on-state instead of all
/// four being one consistent filter control.
class _KindFilterChip extends StatelessWidget {
  const _KindFilterChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? colors.gold.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? colors.gold.withValues(alpha: 0.5)
                    : colors.nightBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? colors.gold : colors.muted,
                ),
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? colors.text : colors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Just the kind name, purely a visual label — not part of the tap
        // target above, so accidentally tapping it doesn't toggle anything.
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? colors.gold : colors.muted,
          ),
        ),
      ],
    );
  }
}

/// A project ("constellation") card — big icon + name up top, a secondary
/// detail row below, and gold-tinted metric badges for star count, open
/// goals, and active pulsars.
class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.starCount,
    required this.lastStarDate,
    required this.combinedIntensity,
    required this.openGoals,
    required this.activeHabits,
    required this.onTap,
  });

  final Project project;
  final int starCount;
  final DateTime? lastStarDate;
  final int combinedIntensity;
  final int openGoals;
  final int activeHabits;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final borderRadius = BorderRadius.circular(12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            color: colors.nightPanel,
            border: Border.all(color: colors.nightBorder),
            borderRadius: borderRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colors.gold.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconForSlug(project.iconSlug),
                    color: colors.gold,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: colors.text,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        children: [
                          _StatChip(
                            icon: Icons.auto_awesome_outlined,
                            text: strings.createdOnLabel(
                              formatDisplayDate(project.createdAt, strings),
                            ),
                          ),
                          if (lastStarDate != null)
                            _StatChip(
                              icon: Icons.schedule,
                              text: strings.lastStarLabel(
                                formatDisplayDate(lastStarDate!, strings),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _MetricBadge(
                            icon: Icons.star,
                            text: strings.starsCount(starCount),
                          ),
                          _MetricBadge(
                            icon: Icons.offline_bolt,
                            text: strings.intensityCount(combinedIntensity),
                          ),
                          if (openGoals > 0)
                            _MetricBadge(
                              icon: Icons.flag_outlined,
                              text: strings.openGoalsBadge(openGoals),
                            ),
                          if (activeHabits > 0)
                            _MetricBadge(
                              icon: Icons.repeat,
                              text: strings.activeHabitsBadge(activeHabits),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.gold),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.gold,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colors.goldDim),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(fontSize: 12.5, color: colors.muted)),
      ],
    );
  }
}

ButtonStyle _segmentedButtonStyle(AppColors colors) {
  return SegmentedButton.styleFrom(
    backgroundColor: colors.nightPanel,
    foregroundColor: colors.muted,
    selectedBackgroundColor: colors.gold,
    selectedForegroundColor: colors.onGold,
    side: BorderSide(color: colors.nightBorder),
  );
}
