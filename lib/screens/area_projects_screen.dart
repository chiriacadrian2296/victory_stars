import 'package:flutter/material.dart';

import '../data/project_repository.dart';
import '../data/win_repository.dart';
import '../models/life_area.dart';
import '../models/project.dart';
import '../theme/app_colors.dart';
import '../utils/icon_for_slug.dart';
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
        builder: (_) => ConstellationScreen(project: project, winRepository: widget.winRepository),
      ),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.night,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: AppColors.muted),
                ),
                Expanded(
                  child: Text(
                    widget.area.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: AppColors.text),
                  ),
                ),
                IconButton(
                  onPressed: _createProject,
                  icon: const Icon(Icons.add, color: AppColors.gold),
                  tooltip: 'New project',
                ),
              ],
            ),
            Expanded(
              child: _projects.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Center(
                        child: Text(
                          'No projects yet in ${widget.area.displayName}. '
                          'Start one to begin lighting stars here.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: AppColors.muted),
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
    return Material(
      color: AppColors.nightPanel,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.nightBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(iconForSlug(project.iconSlug), color: AppColors.gold, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  project.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.text),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$starCount star${starCount == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
