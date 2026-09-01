import 'dart:async';
import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../data/custom_constellation_repository.dart';
import '../data/habit_completion_repository.dart';
import '../data/habit_repository.dart';
import '../data/project_repository.dart';
import '../data/star_repository.dart';
import '../l10n/app_strings.dart';
import '../l10n/strings_scope.dart';
import '../models/project.dart';
import '../models/star.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';
import '../utils/star_stats.dart';
import '../widgets/responsive_content.dart';
import '../widgets/star_card.dart';
import '../widgets/star_heatmap.dart';
import 'add_habit_screen.dart';
import 'add_star_screen.dart';
import 'admire_stars_screen.dart';
import 'new_project_screen.dart';
import 'stat_detail_screen.dart';
import 'star_reader_screen.dart';

/// The dashboard — one tab of [RootScreen]: a quick read on consistency
/// (total stars, streaks) and a GitHub-contribution-style calendar of when
/// victories were achieved, rather than a flat list (that's now the Stars
/// tab). Still owns the "add" FAB (a chooser between Victory/Goal/Habit),
/// since it's the natural landing tab.
///
/// Never caches a star list in a field — [build] always re-reads
/// [starRepository] fresh. This tab is kept alive (not disposed) by
/// [RootScreen]'s `IndexedStack`, so a cached list would otherwise go stale
/// whenever data changes from a *different* tab.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.starRepository,
    required this.projectRepository,
    required this.habitRepository,
    required this.habitCompletionRepository,
    required this.customConstellationRepository,
  });

  final StarRepository starRepository;
  final ProjectRepository projectRepository;
  final HabitRepository habitRepository;
  final HabitCompletionRepository habitCompletionRepository;
  final CustomConstellationRepository customConstellationRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _CreateChoice { victory, goal, habit, constellation }

class _HomeScreenState extends State<HomeScreen> {
  /// The month the activity calendar is currently showing — always the 1st,
  /// so it can be compared/offset by month without caring what day it was
  /// created on. Defaults to the current month; [_changeDisplayedMonth]
  /// moves it, capped so the user can never page past the present month.
  DateTime _displayedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  bool get _isCurrentMonthDisplayed {
    final now = DateTime.now();
    return _displayedMonth.year == now.year &&
        _displayedMonth.month == now.month;
  }

  void _changeDisplayedMonth(int delta) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final next = DateTime(_displayedMonth.year, _displayedMonth.month + delta);
    setState(() {
      _displayedMonth = next.isAfter(currentMonth) ? currentMonth : next;
    });
  }

  Map<int, Project> _projectsById() {
    return {
      for (final project in widget.projectRepository.getAll())
        project.id: project,
    };
  }

  Future<void> _openAddStarScreen({
    DateTime? initialDate,
    bool initialAchieved = true,
  }) async {
    final result = await Navigator.of(context).push<AddStarResult>(
      MaterialPageRoute(
        builder: (_) => AddStarScreen(
          projectRepository: widget.projectRepository,
          customConstellationRepository: widget.customConstellationRepository,
          initialDate: initialDate,
          initialAchieved: initialAchieved,
        ),
      ),
    );
    if (result == null) return;

    await widget.starRepository.add(
      title: result.title,
      description: result.description,
      projectId: result.projectId,
      targetDate: result.targetDate,
      achievedDate: result.achievedDate,
      intensity: result.intensity,
      photoPath: result.photoPath,
    );
    setState(() {});
  }

  Future<void> _openAddHabitScreen() async {
    final result = await Navigator.of(context).push<AddHabitResult>(
      MaterialPageRoute(
        builder: (_) => AddHabitScreen(
          projectRepository: widget.projectRepository,
          customConstellationRepository: widget.customConstellationRepository,
        ),
      ),
    );
    if (result == null) return;

    await widget.habitRepository.add(
      title: result.title,
      description: result.description,
      projectId: result.projectId,
      reminderHour: result.reminderHour,
      reminderMinute: result.reminderMinute,
    );
    setState(() {});
  }

  void _openTotalStarsDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TotalStarsDetailScreen(
          starRepository: widget.starRepository,
          projectRepository: widget.projectRepository,
        ),
      ),
    );
  }

  void _openCurrentStreakDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            CurrentStreakDetailScreen(starRepository: widget.starRepository),
      ),
    );
  }

  void _openLongestStreakDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            LongestStreakDetailScreen(starRepository: widget.starRepository),
      ),
    );
  }

  void _openAdmireStars() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdmireStarsScreen(
          starRepository: widget.starRepository,
          projectRepository: widget.projectRepository,
        ),
      ),
    );
  }

  Future<void> _openNewProjectScreen() async {
    await Navigator.of(context).push<Project>(
      MaterialPageRoute(
        builder: (_) => NewProjectScreen(
          projectRepository: widget.projectRepository,
          customConstellationRepository: widget.customConstellationRepository,
        ),
      ),
    );
    setState(() {});
  }

  Future<void> _showCreateMenu() async {
    final colors = context.colors;
    final strings = context.strings;

    final choice = await showModalBottomSheet<_CreateChoice>(
      context: context,
      backgroundColor: colors.nightPanel,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.star, color: colors.gold),
                title: Text(
                  strings.addWinFabLabel,
                  style: TextStyle(color: colors.text),
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_CreateChoice.victory),
              ),
              ListTile(
                leading: Icon(Icons.flag_outlined, color: colors.gold),
                title: Text(
                  strings.addGoalFabLabel,
                  style: TextStyle(color: colors.text),
                ),
                onTap: () => Navigator.of(sheetContext).pop(_CreateChoice.goal),
              ),
              ListTile(
                leading: Icon(Icons.repeat, color: colors.gold),
                title: Text(
                  strings.addHabitFabLabel,
                  style: TextStyle(color: colors.text),
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_CreateChoice.habit),
              ),
              ListTile(
                leading: Icon(Icons.auto_awesome, color: colors.gold),
                title: Text(
                  strings.newConstellationOption,
                  style: TextStyle(color: colors.text),
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_CreateChoice.constellation),
              ),
            ],
          ),
        );
      },
    );

    switch (choice) {
      case _CreateChoice.victory:
        await _openAddStarScreen();
      case _CreateChoice.goal:
        await _openAddStarScreen(initialAchieved: false);
      case _CreateChoice.habit:
        await _openAddHabitScreen();
      case _CreateChoice.constellation:
        await _openNewProjectScreen();
      case null:
        break;
    }
  }

  List<Star> _achievedStarsOnDay(DateTime day) {
    return widget.starRepository.getAll().where((s) {
      if (!s.isAchieved) return false;
      final date = s.achievedDate!;
      return date.year == day.year &&
          date.month == day.month &&
          date.day == day.day;
    }).toList();
  }

  Future<void> _openStarReader(
    List<Star> stars,
    int index,
    DateTime day,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StarReaderScreen(
          repository: widget.starRepository,
          initialStars: stars,
          startIndex: index,
          allowEdit: true,
          projectsById: _projectsById(),
          projectRepository: widget.projectRepository,
          customConstellationRepository: widget.customConstellationRepository,
          refreshStars: () => _achievedStarsOnDay(day),
        ),
      ),
    );
    setState(() {});
  }

  Future<void> _openDayDetail(DateTime day) async {
    final colors = context.colors;
    final projectsById = _projectsById();
    final dayStars = _achievedStarsOnDay(day);
    final sheetMaxHeight = MediaQuery.sizeOf(context).height * 0.85;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.nightPanel,
      isScrollControlled: true,
      constraints: dayStars.isEmpty
          ? BoxConstraints(maxHeight: sheetMaxHeight)
          : BoxConstraints.tightFor(height: sheetMaxHeight),
      builder: (sheetContext) {
        return _DayDetailSheet(
          day: day,
          stars: dayStars,
          projectsById: projectsById,
          onStarTap: (stars, index) {
            Navigator.of(sheetContext).pop();
            _openStarReader(stars, index, day);
          },
          onAddForDay: () {
            Navigator.of(sheetContext).pop();
            _openAddStarScreen(initialDate: day);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final achievedStars = widget.starRepository
        .getAll()
        .where((s) => s.isAchieved)
        .toList();
    final dayCounts = starCountsByDay(achievedStars);
    final dayIntensities = starIntensityByDay(achievedStars);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final litToday = (dayCounts[today] ?? 0) > 0;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 100),
          // The scrollable itself spans the full window width (so its
          // auto-attached Scrollbar sits at the true page edge on wide
          // viewports); only its content is capped/centered.
          children: [
            ResponsiveContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.homeEyebrow,
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                      color: colors.goldDim,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.homeTitle,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.homeSubtitle,
                    style: TextStyle(fontSize: 14, color: colors.muted),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    strings.todayStarSectionLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _TodayStarHero(
                    litToday: litToday,
                    onTap: litToday
                        ? () => _openDayDetail(today)
                        : () => _openAddStarScreen(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    strings.activityLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
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
                      month: _displayedMonth,
                      countsByDay: dayCounts,
                      intensityByDay: dayIntensities,
                      onDayTap: _openDayDetail,
                      onPreviousMonth: () => _changeDisplayedMonth(-1),
                      onNextMonth: _isCurrentMonthDisplayed
                          ? null
                          : () => _changeDisplayedMonth(1),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    strings.totalStarsLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _TotalStarsBanner(
                    value: achievedStars.length,
                    onTap: _openTotalStarsDetail,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    strings.streaksSectionLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: strings.currentStreakLabel,
                          value: '${currentStreak(dayCounts)}',
                          onTap: _openCurrentStreakDetail,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: strings.longestStreakLabel,
                          value: '${longestStreak(dayCounts)}',
                          onTap: _openLongestStreakDetail,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'admireStarsFab',
            onPressed: _openAdmireStars,
            backgroundColor: colors.nightPanel,
            foregroundColor: colors.gold,
            elevation: 2,
            shape: CircleBorder(side: BorderSide(color: colors.goldDim)),
            tooltip: strings.admireYourStars,
            child: const Icon(Icons.auto_awesome),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.gold.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FloatingActionButton(
              heroTag: 'addStarFab',
              onPressed: _showCreateMenu,
              backgroundColor: colors.gold,
              elevation: 0,
              shape: const CircleBorder(),
              child: Icon(Icons.add, color: colors.onGold),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderRadius = BorderRadius.circular(12);
    return Material(
      color: colors.nightPanel,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: colors.nightBorder),
            borderRadius: borderRadius,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: colors.gold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: colors.muted),
                  ),
                ],
              ),
              Positioned(
                top: -2,
                right: -2,
                child: Icon(Icons.info_outline, size: 14, color: colors.gold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A wider, more eye-catching presentation for the total-star count — its
/// own row above the streak cards, rather than squeezed into an equal-width
/// slot alongside them, since it's the headline number on the dashboard.
class _TotalStarsBanner extends StatelessWidget {
  const _TotalStarsBanner({required this.value, required this.onTap});

  final int value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderRadius = BorderRadius.circular(16);

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.gold.withValues(alpha: 0.22),
                colors.gold.withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(color: colors.gold.withValues(alpha: 0.45)),
            borderRadius: borderRadius,
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 24, color: colors.gold),
                    const SizedBox(height: 6),
                    Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: colors.text,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -2,
                right: -2,
                child: Icon(Icons.info_outline, size: 16, color: colors.gold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The dashboard's headline element: whether today's star is lit.
///
/// Lit: a big gold star that spins slowly and forever, with a glow that
/// breathes in and out, next to a two-line congratulatory message.
///
/// Unlit: the same star, cold and static, with a status caption below it,
/// and below that a normal pill-shaped gold button. Tapping anywhere opens
/// today's stars if there are any, or the add-star flow if not.
class _TodayStarHero extends StatefulWidget {
  const _TodayStarHero({required this.litToday, required this.onTap});

  final bool litToday;
  final VoidCallback onTap;

  @override
  State<_TodayStarHero> createState() => _TodayStarHeroState();
}

class _TodayStarHeroState extends State<_TodayStarHero>
    with TickerProviderStateMixin {
  late final _glowController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);
  late final _spinController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  late final _shakeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  Timer? _shakeTimer;

  @override
  void initState() {
    super.initState();
    if (widget.litToday) {
      _spinController.repeat();
    } else {
      _startShakeTimer();
    }
  }

  @override
  void didUpdateWidget(_TodayStarHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.litToday == oldWidget.litToday) return;
    if (widget.litToday) {
      _spinController.repeat();
      _shakeTimer?.cancel();
      _shakeTimer = null;
    } else {
      _spinController.stop();
      _startShakeTimer();
    }
  }

  void _startShakeTimer() {
    _shakeTimer ??= Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _shakeController.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _spinController.dispose();
    _shakeController.dispose();
    _shakeTimer?.cancel();
    super.dispose();
  }

  List<BoxShadow> _glow(Color color, double size) {
    final glowT = _glowController.value;
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.25 + 0.3 * glowT),
        blurRadius: size * 0.19 + size * 0.16 * glowT,
        spreadRadius: size * 0.015 + size * 0.05 * glowT,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final width = MediaQuery.sizeOf(context).width;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: widget.litToday
              ? _buildLit(colors, strings, width)
              : _buildUnlit(colors, strings, width),
        ),
      ),
    );
  }

  Widget _buildLit(AppColors colors, AppStrings strings, double width) {
    final starSize = (width / 3).clamp(90.0, 160.0);

    return Column(
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_glowController, _spinController]),
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: _glow(colors.gold, starSize),
              ),
              child: Transform.rotate(
                angle: _spinController.value * 2 * pi,
                child: child,
              ),
            );
          },
          child: Icon(Icons.star, size: starSize, color: colors.gold),
        ),
        const SizedBox(height: 22),
        _highlightedText(
          text: strings.litTodayTitle,
          highlight: strings.litTodayTitleHighlight,
          highlightColor: colors.gold,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colors.text,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        _highlightedText(
          text: strings.litTodaySubtitle,
          highlight: strings.litTodaySubtitleHighlight,
          highlightColor: colors.gold,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.text,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildUnlit(AppColors colors, AppStrings strings, double width) {
    final starSize = (width / 3).clamp(90.0, 160.0);

    return Column(
      children: [
        AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            final t = _shakeController.value;
            final dx = sin(t * pi * 6) * (1 - t) * 8;
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: Icon(Icons.star, size: starSize, color: colors.muted),
        ),
        const SizedBox(height: 20),
        _highlightedText(
          text: strings.notLitTodayLabel,
          highlight: strings.notLitTodayHighlight,
          highlightColor: colors.muted,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colors.text,
          ),
        ),
        const SizedBox(height: 18),
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                color: colors.gold,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: colors.gold.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                  ..._glow(colors.gold, 44),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: child,
            );
          },
          child: Text(
            strings.lightStarCta,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.night,
            ),
          ),
        ),
      ],
    );
  }
}

/// Renders [text] centered with [highlight] (its first occurrence) recolored
/// to [highlightColor] — used to pick out one word within an otherwise
/// single-colored sentence, per language.
Widget _highlightedText({
  required String text,
  required String highlight,
  required Color highlightColor,
  required TextStyle style,
}) {
  final index = text.indexOf(highlight);
  if (index == -1) {
    return Text(text, textAlign: TextAlign.center, style: style);
  }
  return RichText(
    textAlign: TextAlign.center,
    text: TextSpan(
      style: style,
      children: [
        TextSpan(text: text.substring(0, index)),
        TextSpan(
          text: text.substring(index, index + highlight.length),
          style: style.copyWith(color: highlightColor),
        ),
        TextSpan(text: text.substring(index + highlight.length)),
      ],
    ),
  );
}

/// The day-detail bottom sheet's content — a date heading, a search field, a
/// button to log a new victory already dated to [day], and either the
/// matching achieved stars or an empty-state message.
class _DayDetailSheet extends StatefulWidget {
  const _DayDetailSheet({
    required this.day,
    required this.stars,
    required this.projectsById,
    required this.onStarTap,
    required this.onAddForDay,
  });

  final DateTime day;
  final List<Star> stars;
  final Map<int, Project> projectsById;
  final void Function(List<Star> stars, int index) onStarTap;
  final VoidCallback onAddForDay;

  @override
  State<_DayDetailSheet> createState() => _DayDetailSheetState();
}

class _DayDetailSheetState extends State<_DayDetailSheet> {
  String _query = '';

  Text _emptyStateText(AppStrings strings, AppColors colors) {
    return Text(
      widget.stars.isEmpty ? strings.dayDetailEmpty : strings.noSearchResults,
      textAlign: TextAlign.center,
      style: TextStyle(color: colors.muted, fontSize: 14),
    );
  }

  List<Star> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.stars;
    return widget.stars.where((s) {
      return s.title.toLowerCase().contains(query) ||
          (s.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final filtered = _filtered;
    final hasStarsForDay = widget.stars.isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: hasStarsForDay ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatDisplayDate(widget.day, strings),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              style: TextStyle(color: colors.text, fontSize: 15),
              decoration: InputDecoration(
                hintText: strings.searchHint,
                prefixIcon: Icon(Icons.search, color: colors.muted, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: widget.onAddForDay,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: colors.gold.withValues(alpha: 0.12),
                  border: Border.all(color: colors.gold),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: colors.gold),
                    const SizedBox(width: 8),
                    Text(
                      strings.addStarForDayLabel,
                      style: TextStyle(
                        color: colors.gold,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (filtered.isEmpty)
              hasStarsForDay
                  ? Expanded(
                      child: Center(child: _emptyStateText(strings, colors)),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: _emptyStateText(strings, colors)),
                    )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final star = filtered[index];
                    return StarCard(
                      star: star,
                      project: widget.projectsById[star.projectId],
                      onTap: () => widget.onStarTap(filtered, index),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
