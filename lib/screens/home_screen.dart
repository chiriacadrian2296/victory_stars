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
import 'crisis_intro_screen.dart';
import 'win_reader_screen.dart';

/// The dashboard — one tab of [RootScreen]: a quick read on consistency
/// (total stars, streaks) and a GitHub-contribution-style calendar of when
/// stars were lit, rather than a flat list (that's now the Stars tab).
/// Still owns the "add a win" FAB, since it's the natural landing tab.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.winRepository, required this.projectRepository});

  final WinRepository winRepository;
  final ProjectRepository projectRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Win> _wins = const [];

  @override
  void initState() {
    super.initState();
    _wins = widget.winRepository.getAll();
  }

  Map<int, Project> _projectsById(ProjectRepository projectRepository) {
    return {for (final project in projectRepository.getAll()) project.id: project};
  }

  Future<void> _openAddWinScreen() async {
    final winRepository = widget.winRepository;
    final projectRepository = widget.projectRepository;

    final result = await Navigator.of(context).push<AddWinResult>(
      MaterialPageRoute(builder: (_) => AddWinScreen(projectRepository: projectRepository)),
    );
    if (result == null) return;

    await winRepository.add(
      title: result.title,
      description: result.description,
      projectId: result.projectId,
      intensity: result.intensity,
    );
    setState(() => _wins = winRepository.getAll());
  }

  Future<void> _openCrisisIntro() async {
    final winRepository = widget.winRepository;
    final projectRepository = widget.projectRepository;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CrisisIntroScreen(
          wins: _wins,
          repository: winRepository,
          projectsById: _projectsById(projectRepository),
          projectRepository: projectRepository,
        ),
      ),
    );
    setState(() => _wins = winRepository.getAll());
  }

  List<Win> _winsOnDay(DateTime day) {
    return _wins.where((w) => w.date.year == day.year && w.date.month == day.month && w.date.day == day.day).toList();
  }

  Future<void> _openWinReader(List<Win> wins, int index, DateTime day) async {
    final winRepository = widget.winRepository;
    final projectRepository = widget.projectRepository;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WinReaderScreen(
          repository: winRepository,
          initialWins: wins,
          startIndex: index,
          allowEdit: true,
          projectsById: _projectsById(projectRepository),
          projectRepository: projectRepository,
          refreshWins: () => _winsOnDay(day),
        ),
      ),
    );
    setState(() => _wins = winRepository.getAll());
  }

  Future<void> _openDayDetail(DateTime day) async {
    final colors = context.colors;
    final strings = context.strings;
    final projectsById = _projectsById(widget.projectRepository);
    final dayWins = _winsOnDay(day);

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
                  Text(strings.dayDetailEmpty, style: TextStyle(color: colors.muted, fontSize: 14))
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
    final dayCounts = winCountsByDay(_wins);

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
            const SizedBox(height: 20),
            _SecondaryButton(icon: Icons.auto_awesome, label: strings.admireYourStars, onPressed: _openCrisisIntro),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _StatCard(label: strings.totalStarsLabel, value: '${_wins.length}'),
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
              child: StarHeatmap(countsByDay: dayCounts, onDayTap: _openDayDetail),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
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
          onPressed: _openAddWinScreen,
          backgroundColor: colors.gold,
          elevation: 0,
          shape: const CircleBorder(),
          child: Icon(Icons.add, color: colors.onGold),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17, color: colors.gold),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        backgroundColor: colors.gold.withValues(alpha: 0.1),
        foregroundColor: colors.gold,
        side: BorderSide(color: colors.goldDim),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
