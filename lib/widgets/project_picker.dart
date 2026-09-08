import 'package:flutter/material.dart';

import '../data/custom_constellation_repository.dart';
import '../data/project_repository.dart';
import '../l10n/strings_scope.dart';
import '../models/life_area.dart';
import '../models/project.dart';
import '../screens/new_project_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_style.dart';
import 'area_tag.dart';
import 'project_tag.dart';

class _CreateNewProject {
  const _CreateNewProject();
}

class _GoBackToAreaPicker {
  const _GoBackToAreaPicker();
}

/// A two-step picker — area (supernova) first, then that area's own
/// constellations — rather than one flat list of every project across every
/// area. Loops back to the area sheet if the user taps its back arrow, so
/// switching areas doesn't mean re-opening the picker from scratch. Offers
/// an inline "create new project" action, pushing [NewProjectScreen] scoped
/// to whichever area was picked. Shared by every add/edit form that needs to
/// assign or reassign a star/habit to a project.
Future<Project?> pickProject(
  BuildContext context,
  ProjectRepository repository,
  CustomConstellationRepository customConstellationRepository,
) async {
  while (context.mounted) {
    final area = await _pickArea(context);
    if (area == null || !context.mounted) return null;

    final result = await _pickProjectInArea(context, repository, area);
    if (!context.mounted) return null;
    if (result is _GoBackToAreaPicker) continue;

    if (result is Project) return result;
    if (result is _CreateNewProject) {
      final created = await Navigator.of(context).push<Project>(
        MaterialPageRoute(
          builder: (_) => NewProjectScreen(
            projectRepository: repository,
            customConstellationRepository: customConstellationRepository,
            presetArea: area,
          ),
        ),
      );
      return created;
    }
    return null;
  }
  return null;
}

Future<LifeArea?> _pickArea(BuildContext context) {
  final colors = context.colors;
  final strings = context.strings;

  return showModalBottomSheet<LifeArea>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                strings.areaLabel,
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                  color: colors.muted,
                ),
              ),
            ),
            for (final area in LifeArea.values)
              ListTile(
                title: AreaTag(area: area, iconSize: 20, fontSize: 16),
                trailing: Icon(Icons.chevron_right, color: colors.muted),
                onTap: () => Navigator.of(sheetContext).pop(area),
              ),
          ],
        ),
      );
    },
  );
}

Future<Object?> _pickProjectInArea(
  BuildContext context,
  ProjectRepository repository,
  LifeArea area,
) {
  return showModalBottomSheet<Object>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return _ProjectPickerSheet(
        area: area,
        projects: repository.getProjectsForArea(area),
      );
    },
  );
}

/// The second step of [pickProject] — search plus a prominent create-new
/// action, scoped to whatever [area] the user picked in the first step,
/// instead of one flat list of every constellation.
class _ProjectPickerSheet extends StatefulWidget {
  const _ProjectPickerSheet({required this.area, required this.projects});

  final LifeArea area;
  final List<Project> projects;

  @override
  State<_ProjectPickerSheet> createState() => _ProjectPickerSheetState();
}

class _ProjectPickerSheetState extends State<_ProjectPickerSheet> {
  String _query = '';

  List<Project> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.projects;
    return widget.projects
        .where((p) => p.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final filtered = _filtered;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () =>
                      Navigator.of(context).pop(const _GoBackToAreaPicker()),
                  icon: Icon(Icons.arrow_back, color: colors.muted),
                ),
                const SizedBox(width: 4),
                AreaTag(area: widget.area, iconSize: 18, fontSize: 16),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              style: TextStyle(color: colors.text, fontSize: 15),
              decoration: InputDecoration(
                hintText: strings.searchHint,
                prefixIcon: Icon(Icons.search, color: colors.muted, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () => Navigator.of(context).pop(const _CreateNewProject()),
              borderRadius: BorderRadius.circular(kRadiusField),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: selectableDecoration(colors, selected: true),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: colors.gold),
                    const SizedBox(width: 8),
                    Text(
                      strings.newProject,
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
            const SizedBox(height: 8),
            Flexible(
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          _query.isEmpty
                              ? strings.areaEmptyProjects(
                                  widget.area.displayName(strings),
                                )
                              : strings.noSearchResults,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.muted, fontSize: 14),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          Divider(color: colors.nightBorder, height: 1),
                      itemBuilder: (context, index) {
                        final project = filtered[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: ProjectTag(
                            project: project,
                            fontSize: 15,
                            textColor: colors.text,
                          ),
                          onTap: () => Navigator.of(context).pop(project),
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
