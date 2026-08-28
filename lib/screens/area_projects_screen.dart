import 'package:flutter/material.dart';

import '../data/project_repository.dart';
import '../data/win_repository.dart';
import '../l10n/strings_scope.dart';
import '../models/life_area.dart';
import '../models/project.dart';
import '../models/win.dart';
import '../theme/app_colors.dart';
import '../widgets/project_tag.dart';
import '../widgets/win_card.dart';
import 'constellation_screen.dart';
import 'new_project_screen.dart';
import 'win_reader_screen.dart';

enum _ViewMode { constellations, list }

/// One life area's detail screen — Sky's second step after picking an
/// area. Offers two views of the same underlying data, switched via a
/// segmented control rather than living as two separate tabs (they were
/// close enough in purpose that keeping both as top-level destinations was
/// redundant):
/// - Constellations: the area's projects, each showing its own lit-star
///   count; tapping one opens its [ConstellationScreen].
/// - List: every win in the area (across all its projects), flat and
///   searchable by title/description.
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

  Future<void> _createProject() async {
    await Navigator.of(context).push<Project>(
      MaterialPageRoute(
        builder: (_) => NewProjectScreen(projectRepository: widget.projectRepository, presetArea: widget.area),
      ),
    );
    setState(() {});
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
                if (_mode == _ViewMode.constellations)
                  IconButton(
                    onPressed: _createProject,
                    icon: Icon(Icons.add, color: colors.gold),
                    tooltip: strings.newProjectTooltip,
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
                    icon: const Icon(Icons.list, size: 16),
                    label: Text(strings.listModeLabel),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) => setState(() => _mode = selection.first),
              ),
            ),
            if (_mode == _ViewMode.list)
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
                      projects: _projects,
                      areaName: areaName,
                      winRepository: widget.winRepository,
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
    required this.projects,
    required this.areaName,
    required this.winRepository,
    required this.onTap,
  });

  final List<Project> projects;
  final String areaName;
  final WinRepository winRepository;
  final void Function(Project) onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    if (projects.isEmpty) {
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

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: projects.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final project = projects[index];
        final starCount = winRepository.getAllForProject(project.id).length;
        return _ProjectCard(project: project, starCount: starCount, onTap: () => onTap(project));
      },
    );
  }
}

class _WinsList extends StatelessWidget {
  const _WinsList({
    required this.allWins,
    required this.filteredWins,
    required this.projectsById,
    required this.onTap,
  });

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
        return WinCard(
          win: win,
          project: projectsById[win.projectId],
          onTap: () => onTap(filteredWins, index),
        );
      },
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.starCount, required this.onTap});

  final Project project;
  final int starCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.nightPanel,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            border: Border.all(color: colors.nightBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: ProjectTag(project: project, iconSize: 22, fontSize: 16, textColor: colors.text),
              ),
              Text(
                context.strings.starsCount(starCount),
                style: TextStyle(fontSize: 13, color: colors.muted),
              ),
            ],
          ),
        ),
      ),
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
