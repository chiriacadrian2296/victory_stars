import 'package:flutter/material.dart';

import '../data/project_repository.dart';
import '../data/win_repository.dart';
import '../l10n/strings_scope.dart';
import '../models/life_area.dart';
import '../models/project.dart';
import '../theme/app_colors.dart';
import '../widgets/project_tag.dart';
import 'constellation_screen.dart';
import 'new_project_screen.dart';

/// Lists the projects within one [LifeArea], each showing its own lit-star
/// count. Tapping a project opens its [ConstellationScreen]; the header's
/// add icon creates a new project already scoped to this area (the FAB is
/// reserved for Home's own "add a win" action).
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
  late List<Project> _projects = widget.projectRepository.getProjectsForArea(widget.area);

  void _refresh() {
    setState(() => _projects = widget.projectRepository.getProjectsForArea(widget.area));
  }

  Future<void> _createProject() async {
    final created = await Navigator.of(context).push<Project>(
      MaterialPageRoute(
        builder: (_) => NewProjectScreen(projectRepository: widget.projectRepository, presetArea: widget.area),
      ),
    );
    if (created != null) _refresh();
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
    _refresh();
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
                  ),
                ),
                IconButton(
                  onPressed: _createProject,
                  icon: Icon(Icons.add, color: colors.gold),
                  tooltip: strings.newProjectTooltip,
                ),
              ],
            ),
            Expanded(
              child: _projects.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Center(
                        child: Text(
                          strings.areaEmptyProjects(areaName),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: colors.muted),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                      itemCount: _projects.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final project = _projects[index];
                        final starCount = widget.winRepository.getAllForProject(project.id).length;
                        return _ProjectCard(
                          project: project,
                          starCount: starCount,
                          onTap: () => _openProject(project),
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
