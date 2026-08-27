import 'package:flutter/material.dart';

import '../data/project_repository.dart';
import '../models/project.dart';
import '../models/win.dart';
import '../theme/app_colors.dart';
import '../widgets/area_tag.dart';
import '../widgets/intensity_stars.dart';
import '../widgets/project_tag.dart';
import 'new_project_screen.dart';

/// What the user entered, handed back to whoever pushed this screen.
/// Trimming and blank-to-null normalization for [description] happen in
/// [WinRepository.add]/[WinRepository.update], not here, so that logic
/// lives in one place regardless of whether this was an add or an edit.
class AddWinResult {
  const AddWinResult({
    required this.title,
    this.description,
    required this.projectId,
    required this.intensity,
  });

  final String title;
  final String? description;
  final int projectId;
  final int intensity;
}

/// Also doubles as the edit screen: pass [existingWin] to pre-fill the
/// fields with a win's current title/description/intensity. The caller
/// decides whether the returned [AddWinResult] should create a new win or
/// update an existing one — this screen just collects the form input
/// either way, project and area included: editing a win lets you move it
/// to a different project (and, through it, a different area) exactly the
/// same way creating one does.
///
/// A project must be resolved one of two ways:
/// - [lockedProject]: the project is already known (e.g. opened from that
///   project's own constellation screen) and isn't user-selectable here.
/// - [projectRepository]: no project is implied yet, so a picker lets the
///   user choose an existing project or create a new one inline. Required
///   whenever [lockedProject] isn't given — including when editing, since
///   the picker is how a win's project gets reassigned.
class AddWinScreen extends StatefulWidget {
  const AddWinScreen({
    super.key,
    this.existingWin,
    this.lockedProject,
    this.projectRepository,
    this.contextProject,
  }) : assert(
         lockedProject != null || projectRepository != null,
         'Provide lockedProject (pre-scoped, no picker) or projectRepository (picker, for add or edit).',
       );

  final Win? existingWin;
  final Project? lockedProject;
  final ProjectRepository? projectRepository;

  /// The existing win's current project, resolved by the caller — seeds the
  /// picker's initial selection when editing.
  final Project? contextProject;

  bool get isEditing => existingWin != null;

  @override
  State<AddWinScreen> createState() => _AddWinScreenState();
}

class _CreateNewProject {
  const _CreateNewProject();
}

class _AddWinScreenState extends State<AddWinScreen> {
  late final _titleController = TextEditingController(text: widget.existingWin?.title ?? '');
  late final _descriptionController = TextEditingController(text: widget.existingWin?.description ?? '');
  late Project? _selectedProject = widget.lockedProject ?? widget.contextProject;
  late int _intensity = widget.existingWin?.intensity ?? 3;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    final project = _selectedProject;
    if (title.isEmpty || project == null) return;

    Navigator.of(context).pop(
      AddWinResult(
        title: title,
        description: _descriptionController.text,
        projectId: project.id,
        intensity: _intensity,
      ),
    );
  }

  Future<void> _openProjectPicker() async {
    final repository = widget.projectRepository;
    if (repository == null) return;
    final projects = repository.getAll();

    final result = await showModalBottomSheet<Object>(
      context: context,
      backgroundColor: AppColors.nightPanel,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.add, color: AppColors.gold),
                title: const Text(
                  'New project',
                  style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.of(sheetContext).pop(const _CreateNewProject()),
              ),
              if (projects.isNotEmpty) const Divider(color: AppColors.nightBorder, height: 1),
              for (final project in projects)
                ListTile(
                  title: ProjectTag(project: project, fontSize: 15, textColor: AppColors.text),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: AreaTag(area: project.area, iconSize: 13, fontSize: 12),
                  ),
                  onTap: () => Navigator.of(sheetContext).pop(project),
                ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    if (result is Project) {
      setState(() => _selectedProject = result);
    } else if (result is _CreateNewProject) {
      final created = await Navigator.of(context).push<Project>(
        MaterialPageRoute(builder: (_) => NewProjectScreen(projectRepository: repository)),
      );
      if (created != null && mounted) {
        setState(() => _selectedProject = created);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.muted),
                  ),
                  Text(
                    widget.isEditing ? 'EDIT STAR' : 'NEW STAR',
                    style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'What did you get through?',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: AppColors.text,
                ),
              ),
              if (_selectedProject != null) ...[
                const SizedBox(height: 14),
                AreaTag(area: _selectedProject!.area, iconSize: 22, fontSize: 20),
              ],
              const SizedBox(height: 24),
              if (widget.lockedProject == null) ...[
                const Text(
                  'Project',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _openProjectPicker,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.nightPanel,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.nightBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _selectedProject != null
                              ? ProjectTag(
                                  project: _selectedProject!,
                                  iconSize: 18,
                                  fontSize: 15,
                                  textColor: AppColors.text,
                                )
                              : const Text(
                                  'Select a project',
                                  style: TextStyle(color: AppColors.muted, fontSize: 15),
                                ),
                        ),
                        const Icon(Icons.expand_more, color: AppColors.muted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const Text(
                'In a few words',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: AppColors.text, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'E.g. I held on after a rejection and kept going',
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Details (optional)',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _descriptionController,
                minLines: 4,
                maxLines: 6,
                style: const TextStyle(color: AppColors.text, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'What made this moment hard, and how you got through it',
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Intensity — how much this took out of you',
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                  IntensityStars(intensity: _intensity, size: 16),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.gold,
                  inactiveTrackColor: AppColors.nightBorder,
                  thumbColor: AppColors.gold,
                  overlayColor: AppColors.gold.withValues(alpha: 0.2),
                  valueIndicatorColor: AppColors.gold,
                  valueIndicatorTextStyle: const TextStyle(color: AppColors.onGold, fontWeight: FontWeight.w600),
                ),
                child: Slider(
                  value: _intensity.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '$_intensity',
                  onChanged: (value) => setState(() => _intensity = value.round()),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _titleController,
                  builder: (context, value, child) {
                    final canSave = value.text.trim().isNotEmpty && _selectedProject != null;
                    return ElevatedButton(
                      onPressed: canSave ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.onGold,
                        disabledBackgroundColor: AppColors.nightBorder,
                        disabledForegroundColor: AppColors.muted,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        widget.isEditing ? 'Save changes' : 'Light this star',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
