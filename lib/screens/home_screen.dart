import 'package:flutter/material.dart';

import '../data/project_repository.dart';
import '../data/win_repository.dart';
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
    );
    setState(() {});
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
            Row(
              children: [
                Expanded(
                  child: _StatCard(label: strings.totalStarsLabel, value: '${wins.length}'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(label: strings.currentStreakLabel, value: '${currentStreak(dayCounts)}'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(label: strings.longestStreakLabel, value: '${longestStreak(dayCounts)}'),
                ),
              ],
            ),
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
              child: StarHeatmap(
                countsByDay: dayCounts,
                intensityByDay: dayIntensities,
                onDayTap: _openDayDetail,
              ),
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
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: colors.nightPanel,
        border: Border.all(color: colors.nightBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
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
    );
  }
}
