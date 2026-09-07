import 'package:flutter/material.dart';

import '../data/area_vision_repository.dart';
import '../data/custom_constellation_repository.dart';
import '../data/habit_completion_repository.dart';
import '../data/habit_repository.dart';
import '../data/project_repository.dart';
import '../data/star_repository.dart';
import '../l10n/app_strings.dart';
import '../l10n/strings_scope.dart';
import '../models/habit.dart';
import '../models/life_area.dart';
import '../models/project.dart';
import '../models/star.dart';
import '../screens/area_detail_screen.dart';
import '../screens/constellation_screen.dart';
import '../screens/habit_reader_screen.dart';
import '../screens/star_reader_screen.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';
import '../utils/habit_stats.dart';
import '../utils/icon_for_slug.dart';
import 'area_filter_sheet.dart';
import 'area_tag.dart';
import 'constellation_painter.dart' show StarKind;
import 'dead_star_card.dart';
import 'goal_card.dart';
import 'habit_card.dart';
import 'navigate_here_button.dart';
import 'responsive_content.dart';
import 'sky_navigation_target.dart';
import 'star_card.dart';

enum _SkyMode { supernovas, constellations, stars }

/// One flat-list row — either a [Star] (victory/goal/dead, told apart by
/// [kind]) or a [Habit] (pulsar, [kind] always [StarKind.habit]) — wrapped
/// with a shared [sortKey] so the two can be merged into one newest-first
/// list without either side needing to know about the other's shape.
class _SkyEntry {
  _SkyEntry.fromStar(Star star)
    : star = star,
      habit = null,
      kind = star.dead
          ? StarKind.dead
          : (star.isAchieved ? StarKind.victory : StarKind.goal),
      sortKey = star.achievedDate ?? star.createdAt;

  _SkyEntry.fromHabit(Habit habit)
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

/// A switch between three views of the same underlying data — Supernovas
/// (the 8 fixed life areas, tap one for its own detail page), Constellations
/// (every project across whichever areas are in the area filter, tap one to
/// open its [ConstellationScreen]), and Stars (every star and pulsar across
/// those same areas, flat, newest first, further narrowed by a kind-filter
/// row). Constellations and Stars share one area filter (default: every
/// area), opened from [showAreaFilterSheet].
///
/// The Galaxy tab's search popup (`GalaxySearchScreen`) is this widget's
/// only caller — every card's "take me there" button calls [onNavigateTo]
/// unconditionally, and [onModeLabelChanged] is how the popup's own AppBar
/// title tracks whichever of the three views is currently selected, since
/// that label used to be drawn inline here (freeing that vertical space was
/// the point of moving it up into the popup's title bar).
class SkyExplorerView extends StatefulWidget {
  const SkyExplorerView({
    super.key,
    required this.projectRepository,
    required this.starRepository,
    required this.habitRepository,
    required this.habitCompletionRepository,
    required this.customConstellationRepository,
    required this.areaVisionRepository,
    required this.onNavigateTo,
    required this.onModeLabelChanged,
  });

  final ProjectRepository projectRepository;
  final StarRepository starRepository;
  final HabitRepository habitRepository;
  final HabitCompletionRepository habitCompletionRepository;
  final CustomConstellationRepository customConstellationRepository;
  final AreaVisionRepository areaVisionRepository;

  /// See [SkyNavigationTarget] — called when a card's "take me there" button
  /// is tapped.
  final ValueChanged<SkyNavigationTarget> onNavigateTo;

  /// Called once on mount and again every time the selected level
  /// (Supernovas/Constellations/Stars) changes, with that level's own
  /// already-localized name.
  final ValueChanged<String> onModeLabelChanged;

  @override
  State<SkyExplorerView> createState() => _SkyExplorerViewState();
}

class _SkyExplorerViewState extends State<SkyExplorerView> {
  _SkyMode _mode = _SkyMode.supernovas;
  String _query = '';
  Set<StarKind> _kindFilter = {
    StarKind.victory,
    StarKind.goal,
    StarKind.dead,
    StarKind.habit,
  };
  Set<LifeArea> _areaFilter = {...LifeArea.values};

  List<Project> get _filteredAreaProjects => widget.projectRepository
      .getAll()
      .where((p) => _areaFilter.contains(p.area))
      .toList();

  Map<int, Project> get _projectsById => {
    for (final project in _filteredAreaProjects) project.id: project,
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
    final projects = _filteredAreaProjects;
    if (query.isEmpty) return projects;
    return projects.where((p) => p.name.toLowerCase().contains(query)).toList();
  }

  /// Every star and pulsar across the filtered areas' projects, of every
  /// kind, newest first — the unfiltered pool the kind-filter counts and the
  /// flat list itself are both drawn from.
  List<_SkyEntry> get _allEntries {
    final projectIds = _projectsById.keys.toSet();
    final entries = <_SkyEntry>[
      for (final star in widget.starRepository.getAll())
        if (projectIds.contains(star.projectId)) _SkyEntry.fromStar(star),
      for (final projectId in projectIds)
        for (final habit in widget.habitRepository.getAllForProject(projectId))
          _SkyEntry.fromHabit(habit),
    ];
    entries.sort((a, b) => b.sortKey.compareTo(a.sortKey));
    return entries;
  }

  List<_SkyEntry> get _filteredEntries {
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

  String _labelFor(_SkyMode mode, AppStrings strings) => switch (mode) {
    _SkyMode.supernovas => strings.skyModeSupernovas,
    _SkyMode.constellations => strings.constellationsModeLabel,
    _SkyMode.stars => strings.listModeLabel,
  };

  @override
  void initState() {
    super.initState();
    // Deferred a frame — this fires a callback that ends up calling setState
    // on the parent (`GalaxySearchScreen`'s AppBar title), which isn't safe
    // to do synchronously while this widget is still mounting/building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onModeLabelChanged(_labelFor(_mode, context.strings));
    });
  }

  Future<void> _openArea(LifeArea area) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AreaDetailScreen(
          area: area,
          areaVisionRepository: widget.areaVisionRepository,
          projectRepository: widget.projectRepository,
          starRepository: widget.starRepository,
        ),
      ),
    );
    setState(() {});
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
          onNavigateTo: (project) => widget.onNavigateTo(SkyStarTarget(project)),
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

  Future<void> _openAreaFilter() async {
    final result = await showAreaFilterSheet(
      context,
      selectedAreas: _areaFilter,
      selectedKinds: _mode == _SkyMode.stars ? _kindFilter : null,
    );
    if (result == null) return;
    setState(() {
      _areaFilter = result.areas;
      final kinds = result.kinds;
      if (kinds != null) _kindFilter = kinds;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final allEntries = _mode == _SkyMode.stars ? _allEntries : const <_SkyEntry>[];
    final filteredEntries = _mode == _SkyMode.stars
        ? _filteredEntries
        : const <_SkyEntry>[];
    final areaFilterActive = _areaFilter.length != LifeArea.values.length;

    return Container(
      color: colors.night,
      child: Column(
        children: [
          // Only the fixed header chrome is width-capped here — the
          // Expanded list below stays full width so its own scrollbar
          // sits at the true page edge on wide viewports rather than
          // hugging a centered column (see ResponsiveContent's doc).
          ResponsiveContent(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                  child: SegmentedButton<_SkyMode>(
                    style: _segmentedButtonStyle(colors),
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: _SkyMode.supernovas,
                        icon: Icon(Icons.flare, size: 20),
                      ),
                      ButtonSegment(
                        value: _SkyMode.constellations,
                        icon: Icon(Icons.auto_awesome, size: 20),
                      ),
                      ButtonSegment(
                        value: _SkyMode.stars,
                        icon: Icon(Icons.star, size: 20),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (selection) {
                      final mode = selection.first;
                      setState(() => _mode = mode);
                      widget.onModeLabelChanged(_labelFor(mode, strings));
                    },
                  ),
                ),
                if (_mode != _SkyMode.supernovas) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (value) =>
                                setState(() => _query = value),
                            style: TextStyle(
                              color: colors.text,
                              fontSize: 15,
                            ),
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
                        const SizedBox(width: 10),
                        _AreaFilterButton(
                          active: areaFilterActive,
                          tooltip: strings.filterAreasAction,
                          onTap: _openAreaFilter,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: switch (_mode) {
              // All 8 cards are meant to read as one screen, no scrolling
              // needed — LayoutBuilder + a min-height ConstrainedBox lets
              // them center within the available space on any normal
              // phone, while SingleChildScrollView is just a safety net
              // for unusually short screens or large text scales, rather
              // than the primary way this is meant to be viewed (same
              // pattern as AdmireStarsScreen's area picker).
              _SkyMode.supernovas => LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: ResponsiveContent(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < LifeArea.values.length; i++) ...[
                                if (i > 0) const SizedBox(height: 10),
                                _AreaCard(
                                  area: LifeArea.values[i],
                                  onTap: () => _openArea(LifeArea.values[i]),
                                  onNavigateTo: () => widget.onNavigateTo(
                                    SkyAreaTarget(LifeArea.values[i]),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              _SkyMode.constellations => _ConstellationsList(
                hasAnyProjects: _filteredAreaProjects.isNotEmpty,
                filteredProjects: _filteredProjects,
                starsForProject: _starsForProject,
                activeHabitCountForProject: _activeHabitCountForProject,
                onTap: _openProject,
                onNavigateTo: widget.onNavigateTo,
              ),
              _SkyMode.stars => _FlatList(
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
                onNavigateTo: widget.onNavigateTo,
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({
    required this.area,
    required this.onTap,
    required this.onNavigateTo,
  });

  final LifeArea area;
  final VoidCallback onTap;
  final VoidCallback onNavigateTo;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return Material(
      color: colors.nightPanel,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: colors.nightBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Mirrors the trailing button's own width so the tag stays
              // visually centered rather than skewed toward the left edge.
              const SizedBox(width: 34),
              Expanded(
                child: Center(
                  child: AreaTag(area: area, iconSize: 20, fontSize: 16),
                ),
              ),
              NavigateHereButton(
                onTap: onNavigateTo,
                tooltip: strings.takeMeThereAction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The filter trigger next to the search field on the Constellations/Stars
/// views — opens [showAreaFilterSheet]. Gold-highlighted (with a small dot)
/// whenever the current filter excludes at least one area, so it's obvious
/// at a glance that the list isn't showing everything.
class _AreaFilterButton extends StatelessWidget {
  const _AreaFilterButton({
    required this.active,
    required this.tooltip,
    required this.onTap,
  });

  final bool active;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? colors.gold.withValues(alpha: 0.14) : colors.nightPanel,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(
                color: active
                    ? colors.gold.withValues(alpha: 0.5)
                    : colors.nightBorder,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.tune,
                  size: 20,
                  color: active ? colors.gold : colors.muted,
                ),
                if (active)
                  Positioned(
                    top: 9,
                    right: 9,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: colors.gold,
                        shape: BoxShape.circle,
                      ),
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

class _ConstellationsList extends StatelessWidget {
  const _ConstellationsList({
    required this.hasAnyProjects,
    required this.filteredProjects,
    required this.starsForProject,
    required this.activeHabitCountForProject,
    required this.onTap,
    required this.onNavigateTo,
  });

  final bool hasAnyProjects;
  final List<Project> filteredProjects;
  final List<Star> Function(int projectId) starsForProject;
  final int Function(int projectId) activeHabitCountForProject;
  final void Function(Project) onTap;
  final ValueChanged<SkyNavigationTarget> onNavigateTo;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    if (!hasAnyProjects) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Center(
          child: Text(
            strings.skyEmptyConstellations,
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
            onNavigateTo: () => onNavigateTo(SkyProjectTarget(project)),
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
    required this.onNavigateTo,
  });

  final bool hasAnyEntries;
  final List<_SkyEntry> entries;
  final Map<int, Project> projectsById;
  final Set<DateTime> Function(int habitId) completedDaysFor;
  final void Function(_SkyEntry entry) onOpenStar;
  final void Function(Habit habit) onOpenHabit;
  final ValueChanged<SkyNavigationTarget> onNavigateTo;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    if (!hasAnyEntries) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Center(
          child: Text(
            strings.skyEmptyStars,
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
        // No project resolved (stale data) means no world position to jump
        // to either — the button is simply omitted for that card.
        final navigateTo = project == null
            ? null
            : () => onNavigateTo(SkyStarTarget(project));

        final Widget card;
        switch (entry.kind) {
          case StarKind.victory:
            card = StarCard(
              star: entry.star!,
              project: project,
              onTap: () => onOpenStar(entry),
              onNavigateTo: navigateTo,
            );
          case StarKind.goal:
            card = GoalCard(
              star: entry.star!,
              project: project,
              onTap: () => onOpenStar(entry),
              onNavigateTo: navigateTo,
            );
          case StarKind.dead:
            card = DeadStarCard(
              star: entry.star!,
              project: project,
              onTap: () => onOpenStar(entry),
              onNavigateTo: navigateTo,
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
              onNavigateTo: navigateTo,
            );
        }
        return ResponsiveContent(child: card);
      },
    );
  }
}

/// A project ("constellation") card — big icon + name up top, which area it
/// belongs to (results span every area in the filter, so this is no longer
/// implicit from context), a secondary detail row below, and gold-tinted
/// metric badges for star count, open goals, and active pulsars.
class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.starCount,
    required this.lastStarDate,
    required this.combinedIntensity,
    required this.openGoals,
    required this.activeHabits,
    required this.onTap,
    required this.onNavigateTo,
  });

  final Project project;
  final int starCount;
  final DateTime? lastStarDate;
  final int combinedIntensity;
  final int openGoals;
  final int activeHabits;
  final VoidCallback onTap;
  final VoidCallback onNavigateTo;

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
                      const SizedBox(height: 4),
                      AreaTag(area: project.area, iconSize: 14, fontSize: 13),
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
                const SizedBox(width: 8),
                NavigateHereButton(
                  onTap: onNavigateTo,
                  tooltip: strings.takeMeThereAction,
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
