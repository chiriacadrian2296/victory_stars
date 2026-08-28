import 'dart:async';
import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../data/project_repository.dart';
import '../data/win_repository.dart';
import '../l10n/app_strings.dart';
import '../l10n/strings_scope.dart';
import '../models/project.dart';
import '../models/win.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';
import '../utils/win_stats.dart';
import '../widgets/star_heatmap.dart';
import '../widgets/win_card.dart';
import 'add_win_screen.dart';
import 'admire_stars_screen.dart';
import 'new_project_screen.dart';
import 'stat_detail_screen.dart';
import 'win_reader_screen.dart';

/// The dashboard — one tab of [RootScreen]: a quick read on consistency
/// (total stars, streaks) and a GitHub-contribution-style calendar of when
/// stars were lit, rather than a flat list (that's now the Stars tab).
/// Still owns the "add a win" FAB, since it's the natural landing tab.
///
/// Never caches a win list in a field — [build] always re-reads
/// [winRepository] fresh. This tab is kept alive (not disposed) by
/// [RootScreen]'s `IndexedStack`, so a cached list would otherwise go stale
/// whenever data changes from a *different* tab (e.g. seeding or resetting
/// from Settings) instead of from here. The empty `setState(() {})` calls
/// after local mutations exist only to trigger that fresh re-read
/// immediately, without waiting for an unrelated rebuild (e.g. a tab
/// switch) to happen to reveal it.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.winRepository, required this.projectRepository});

  final WinRepository winRepository;
  final ProjectRepository projectRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _CreateChoice { star, constellation }

class _HomeScreenState extends State<HomeScreen> {
  Map<int, Project> _projectsById() {
    return {for (final project in widget.projectRepository.getAll()) project.id: project};
  }

  Future<void> _openAddWinScreen() async {
    final result = await Navigator.of(context).push<AddWinResult>(
      MaterialPageRoute(builder: (_) => AddWinScreen(projectRepository: widget.projectRepository)),
    );
    if (result == null) return;

    await widget.winRepository.add(
      title: result.title,
      description: result.description,
      projectId: result.projectId,
      intensity: result.intensity,
      date: result.date,
      photoPath: result.photoPath,
    );
    setState(() {});
  }

  void _openTotalStarsDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TotalStarsDetailScreen(
          winRepository: widget.winRepository,
          projectRepository: widget.projectRepository,
        ),
      ),
    );
  }

  void _openCurrentStreakDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CurrentStreakDetailScreen(winRepository: widget.winRepository)),
    );
  }

  void _openLongestStreakDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LongestStreakDetailScreen(winRepository: widget.winRepository)),
    );
  }

  void _openAdmireStars() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdmireStarsScreen(
          winRepository: widget.winRepository,
          projectRepository: widget.projectRepository,
        ),
      ),
    );
  }

  Future<void> _openNewProjectScreen() async {
    await Navigator.of(context).push<Project>(
      MaterialPageRoute(builder: (_) => NewProjectScreen(projectRepository: widget.projectRepository)),
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
                title: Text(strings.addWinFabLabel, style: TextStyle(color: colors.text)),
                onTap: () => Navigator.of(sheetContext).pop(_CreateChoice.star),
              ),
              ListTile(
                leading: Icon(Icons.auto_awesome, color: colors.gold),
                title: Text(strings.newConstellationOption, style: TextStyle(color: colors.text)),
                onTap: () => Navigator.of(sheetContext).pop(_CreateChoice.constellation),
              ),
            ],
          ),
        );
      },
    );

    switch (choice) {
      case _CreateChoice.star:
        await _openAddWinScreen();
      case _CreateChoice.constellation:
        await _openNewProjectScreen();
      case null:
        break;
    }
  }

  List<Win> _winsOnDay(DateTime day) {
    return widget.winRepository.getAll().where((w) {
      return w.date.year == day.year && w.date.month == day.month && w.date.day == day.day;
    }).toList();
  }

  Future<void> _openWinReader(List<Win> wins, int index, DateTime day) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WinReaderScreen(
          repository: widget.winRepository,
          initialWins: wins,
          startIndex: index,
          allowEdit: true,
          projectsById: _projectsById(),
          projectRepository: widget.projectRepository,
          refreshWins: () => _winsOnDay(day),
        ),
      ),
    );
    setState(() {});
  }

  Future<void> _openDayDetail(DateTime day) async {
    final colors = context.colors;
    final strings = context.strings;
    final projectsById = _projectsById();
    final dayWins = _winsOnDay(day);
    // Empty days would otherwise pop up a tiny sheet (just the date + one
    // line) that feels jarringly different in size from a day with wins —
    // give it the same rough footprint instead.
    final emptyStateHeight = MediaQuery.of(context).size.height * 0.3;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.nightPanel,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatDisplayDate(day, strings),
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: colors.text),
                ),
                const SizedBox(height: 16),
                if (dayWins.isEmpty)
                  SizedBox(
                    height: emptyStateHeight,
                    child: Center(
                      child: Text(strings.dayDetailEmpty, style: TextStyle(color: colors.muted, fontSize: 14)),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: dayWins.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final win = dayWins[index];
                        return WinCard(
                          win: win,
                          project: projectsById[win.projectId],
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _openWinReader(dayWins, index, day);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final wins = widget.winRepository.getAll();
    final dayCounts = winCountsByDay(wins);
    final dayIntensities = winIntensityByDay(wins);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final litToday = (dayCounts[today] ?? 0) > 0;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 100),
          children: [
            Text(
              strings.homeEyebrow,
              style: TextStyle(fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w600, color: colors.goldDim),
            ),
            const SizedBox(height: 6),
            Text(
              strings.homeTitle,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: colors.text),
            ),
            const SizedBox(height: 6),
            Text(strings.homeSubtitle, style: TextStyle(fontSize: 14, color: colors.muted)),
            const SizedBox(height: 24),
            // The dashboard's headline element — whether today's star is lit
            // is the one thing worth knowing at a glance, so it leads, ahead
            // of the calendar and the totals/streaks tiles below it.
            Text(
              strings.todayStarSectionLabel,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.muted),
            ),
            const SizedBox(height: 10),
            _TodayStarHero(litToday: litToday, onTap: litToday ? () => _openDayDetail(today) : _openAddWinScreen),
            const SizedBox(height: 24),
            Text(
              strings.activityLabel,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.muted),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.nightPanel,
                border: Border.all(color: colors.nightBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: StarHeatmap(countsByDay: dayCounts, intensityByDay: dayIntensities, onDayTap: _openDayDetail),
            ),
            const SizedBox(height: 24),
            Text(
              strings.totalStarsLabel,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.muted),
            ),
            const SizedBox(height: 10),
            _TotalStarsBanner(value: wins.length, onTap: _openTotalStarsDetail),
            const SizedBox(height: 24),
            Text(
              strings.streaksSectionLabel,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.muted),
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Only on Home — not worth chasing down from every tab, and this
          // is the natural landing screen anyway.
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
          GestureDetector(
            // Hold for a choice between logging a star or starting a whole
            // new constellation, instead of only ever landing on the
            // single-star flow.
            onLongPress: _showCreateMenu,
            child: Container(
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
                heroTag: 'addWinFab',
                onPressed: _openAddWinScreen,
                backgroundColor: colors.gold,
                elevation: 0,
                shape: const CircleBorder(),
                child: Icon(Icons.add, color: colors.onGold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.onTap});

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
                  Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colors.gold)),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: colors.muted),
                  ),
                ],
              ),
              // A small affordance hinting these cards open a detail
              // screen, rather than being purely decorative stats. A plain
              // info glyph rather than a chevron, since a chevron implies
              // "more content this way" which reads oddly on a square card.
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
              colors: [colors.gold.withValues(alpha: 0.22), colors.gold.withValues(alpha: 0.05)],
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
                      style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: colors.text, height: 1),
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
/// and below that a normal pill-shaped gold button sized to its own text
/// (not a big disc) — same gold and drop shadow as the '+' FAB, plus a
/// breathing glow instead of a static one. Tapping anywhere opens today's
/// wins if there are any, or the add-win flow if not.
class _TodayStarHero extends StatefulWidget {
  const _TodayStarHero({required this.litToday, required this.onTap});

  final bool litToday;
  final VoidCallback onTap;

  @override
  State<_TodayStarHero> createState() => _TodayStarHeroState();
}

class _TodayStarHeroState extends State<_TodayStarHero> with TickerProviderStateMixin {
  // Breathes continuously in both states — it drives the star's glow when
  // lit and the button's glow when unlit — while the spin is star-only.
  late final _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
    ..repeat(reverse: true);
  late final _spinController = AnimationController(vsync: this, duration: const Duration(seconds: 18));

  // A short, decaying wiggle on the unlit star, replayed on its own timer —
  // just enough motion every so often to draw the eye back to this corner
  // of the dashboard without being distracting the rest of the time.
  late final _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
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
          child: widget.litToday ? _buildLit(colors, strings, width) : _buildUnlit(colors, strings, width),
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
              decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: _glow(colors.gold, starSize)),
              child: Transform.rotate(angle: _spinController.value * 2 * pi, child: child),
            );
          },
          child: Icon(Icons.star, size: starSize, color: colors.gold),
        ),
        const SizedBox(height: 22),
        _highlightedText(
          text: strings.litTodayTitle,
          highlight: strings.litTodayTitleHighlight,
          highlightColor: colors.gold,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, height: 1.25),
        ),
        const SizedBox(height: 6),
        _highlightedText(
          text: strings.litTodaySubtitle,
          highlight: strings.litTodaySubtitleHighlight,
          highlightColor: colors.gold,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, height: 1.35),
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
          // Same size as the lit version's first line, so the two states
          // don't jump around in scale when the star gets lit or unlit.
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colors.text),
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
                  // The same static drop shadow the '+' FAB uses, plus the
                  // breathing glow layered on top of it.
                  BoxShadow(color: colors.gold.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6)),
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
            // Same size as the lit version's second line, for the same
            // reason as the caption above. Colored with the page's own
            // background instead of white, so it reads as cut out of the
            // gold pill rather than printed on it.
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.night),
          ),
        ),
      ],
    );
  }
}

/// Renders [text] centered with [highlight] (its first occurrence) recolored
/// to [highlightColor] — used to pick out one word (e.g. "star", "light")
/// within an otherwise single-colored sentence, per language.
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
