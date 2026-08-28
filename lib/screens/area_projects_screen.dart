import 'package:flutter/material.dart';

import '../data/project_repository.dart';
import '../data/win_repository.dart';
import '../l10n/strings_scope.dart';
import '../models/life_area.dart';
import '../models/project.dart';
import '../models/win.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';
import '../utils/icon_for_slug.dart';
import '../widgets/win_card.dart';
import 'constellation_screen.dart';
import 'win_reader_screen.dart';

enum _ViewMode { constellations, list }

/// One life area's detail screen — Sky's second step after picking an
/// area. Offers two views of the same underlying data, switched via a
/// segmented control rather than living as two separate tabs (they were
/// close enough in purpose that keeping both as top-level destinations was
/// redundant), sharing one search field that filters whichever is active:
/// - Constellations: the area's projects, each showing its own lit-star
///   count and most recent star; tapping one opens its [ConstellationScreen].
///   Search matches the project name.
/// - Stars: every win in the area (across all its projects), flat, newest
///   first. Search matches title or description.
class AreaProjectsScreen extends StatefulWidget {
  const AreaProjectsScreen({
    super.key,
    required this.area,
    required this.projectRepository,
    required this.winRepository,
  });

  final LifeArea area;
  final ProjectRepository projectRepository;
  final WinRepository winRepository;

  @override
  State<AreaProjectsScreen> createState() => _AreaProjectsScreenState();
}

class _AreaProjectsScreenState extends State<AreaProjectsScreen> {
  _ViewMode _mode = _ViewMode.constellations;
  String _query = '';

  List<Project> get _projects => widget.projectRepository.getProjectsForArea(widget.area);

  Map<int, Project> get _projectsById => {for (final project in _projects) project.id: project};

  List<Win> _winsForProject(int projectId) => widget.winRepository.getAllForProject(projectId);

  List<Project> get _filteredProjects {
    final query = _query.trim().toLowerCase();
    final projects = _projects;
    if (query.isEmpty) return projects;
    return projects.where((p) => p.name.toLowerCase().contains(query)).toList();
  }

  List<Win> get _areaWins {
    final projectIds = _projectsById.keys.toSet();
    return widget.winRepository.getAll().where((w) => projectIds.contains(w.projectId)).toList();
  }

  List<Win> get _filteredWins {
    final query = _query.trim().toLowerCase();
    final wins = _areaWins;
    if (query.isEmpty) return wins;
    return wins.where((w) {
      return w.title.toLowerCase().contains(query) || (w.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Future<void> _openProject(Project project) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConstellationScreen(
          project: project,
          winRepository: widget.winRepository,
          projectRepository: widget.projectRepository,
        ),
      ),
    );
    setState(() {});
  }

  Future<void> _openWinReader(List<Win> wins, int index) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WinReaderScreen(
          repository: widget.winRepository,
          initialWins: wins,
          startIndex: index,
          allowEdit: true,
          projectsById: _projectsById,
          projectRepository: widget.projectRepository,
          refreshWins: () => _filteredWins,
        ),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final areaName = widget.area.displayName(strings);

    return Scaffold(
      backgroundColor: colors.night,
      body: SafeArea(
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
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: colors.text),
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
                onSelectionChanged: (selection) => setState(() => _mode = selection.first),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                style: TextStyle(color: colors.text, fontSize: 15),
                decoration: InputDecoration(
                  hintText: strings.searchHint,
                  prefixIcon: Icon(Icons.search, color: colors.muted, size: 20),
                ),
              ),
            ),
            Expanded(
              child: _mode == _ViewMode.constellations
                  ? _ConstellationsList(
                      allProjects: _projects,
                      filteredProjects: _filteredProjects,
                      areaName: areaName,
                      winsForProject: _winsForProject,
                      onTap: _openProject,
                    )
                  : _WinsList(
                      allWins: _areaWins,
                      filteredWins: _filteredWins,
                      projectsById: _projectsById,
                      onTap: _openWinReader,
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
    required this.winsForProject,
    required this.onTap,
  });

  final List<Project> allProjects;
  final List<Project> filteredProjects;
  final String areaName;
  final List<Win> Function(int projectId) winsForProject;
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
        final wins = winsForProject(project.id);
        return _ProjectCard(
          project: project,
          starCount: wins.length,
          lastWinDate: wins.isEmpty ? null : wins.last.date,
          combinedIntensity: wins.fold<int>(0, (sum, w) => sum + w.intensity),
          onTap: () => onTap(project),
        );
      },
    );
  }
}

class _WinsList extends StatelessWidget {
  const _WinsList({required this.allWins, required this.filteredWins, required this.projectsById, required this.onTap});

  final List<Win> allWins;
  final List<Win> filteredWins;
  final Map<int, Project> projectsById;
  final void Function(List<Win>, int) onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    if (allWins.isEmpty) {
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
    if (filteredWins.isEmpty) {
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
      itemCount: filteredWins.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final win = filteredWins[index];
        return WinCard(win: win, project: projectsById[win.projectId], onTap: () => onTap(filteredWins, index));
      },
    );
  }
}

/// A project ("constellation") card — sized and structured to match
/// [WinCard] (big icon + name up top, a secondary detail row below)
/// instead of the slim single-line row it used to be, so the two views
/// this screen switches between feel like the same family of card.
class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.starCount,
    required this.lastWinDate,
    required this.combinedIntensity,
    required this.onTap,
  });

  final Project project;
  final int starCount;
  final DateTime? lastWinDate;
  final int combinedIntensity;
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
                  decoration: BoxDecoration(color: colors.gold.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(iconForSlug(project.iconSlug), color: colors.gold, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              project.name,
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: colors.text),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right, color: colors.muted, size: 20),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        children: [
                          _StatChip(icon: Icons.star, text: strings.starsCount(starCount)),
                          _StatChip(
                            icon: Icons.auto_awesome_outlined,
                            text: strings.createdOnLabel(formatDisplayDate(project.createdAt, strings)),
                          ),
                          if (lastWinDate != null)
                            _StatChip(
                              icon: Icons.schedule,
                              text: strings.lastStarLabel(formatDisplayDate(lastWinDate!, strings)),
                            ),
                        ],
                      ),
                      // Set apart from the plain icon+text facts above — it's
                      // a rating of how hard-won this constellation's stars
                      // were, not just another count, so it gets its own
                      // gold-tinted pill instead of blending into the row.
                      const SizedBox(height: 10),
                      _IntensityBadge(value: combinedIntensity),
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

/// A gold-tinted pill for a [_ProjectCard]'s combined intensity — visually
/// distinct from (and set below) the plain [_StatChip] facts, since it's a
/// rating rather than just another count.
class _IntensityBadge extends StatelessWidget {
  const _IntensityBadge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
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
          Icon(Icons.bolt, size: 13, color: colors.gold),
          const SizedBox(width: 5),
          Text(
            strings.combinedIntensityValueLabel(value),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.gold),
          ),
        ],
      ),
    );
  }
}

/// One small icon+text fact in a [_ProjectCard]'s info [Wrap] — keeps the
/// three plain stats (stars, created, last star) visually uniform regardless
/// of how many end up on the same line.
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

/// Overrides Material 3's default seed-color (teal) selection styling so
/// the mode switch stays on-brand with the app's gold accent — same
/// pattern as Settings' segmented controls.
ButtonStyle _segmentedButtonStyle(AppColors colors) {
  return SegmentedButton.styleFrom(
    backgroundColor: colors.nightPanel,
    foregroundColor: colors.muted,
    selectedBackgroundColor: colors.gold,
    selectedForegroundColor: colors.onGold,
    side: BorderSide(color: colors.nightBorder),
  );
}
