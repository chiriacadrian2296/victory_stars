import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/photo_storage.dart';
import '../data/project_repository.dart';
import '../l10n/strings_scope.dart';
import '../models/life_area.dart';
import '../models/project.dart';
import '../models/win.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';
import '../widgets/area_tag.dart';
import '../widgets/intensity_bolts.dart';
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
    required this.date,
    this.photoPath,
  });

  final String title;
  final String? description;
  final int projectId;
  final int intensity;
  final DateTime date;

  /// Already-saved app-private path (see [PhotoStorage]), or null for no
  /// photo — never a raw picker path.
  final String? photoPath;
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
    this.initialDate,
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

  /// Pre-fills the date field when creating a new win (e.g. opened from a
  /// specific day on the dashboard calendar) — ignored when [existingWin] is
  /// set, since editing always seeds the date from the win's own.
  final DateTime? initialDate;

  bool get isEditing => existingWin != null;

  @override
  State<AddWinScreen> createState() => _AddWinScreenState();
}

class _CreateNewProject {
  const _CreateNewProject();
}

class _GoBackToAreaPicker {
  const _GoBackToAreaPicker();
}

class _AddWinScreenState extends State<AddWinScreen> {
  late final _titleController = TextEditingController(text: widget.existingWin?.title ?? '');
  late final _descriptionController = TextEditingController(text: widget.existingWin?.description ?? '');
  late Project? _selectedProject = widget.lockedProject ?? widget.contextProject;
  late int _intensity = widget.existingWin?.intensity ?? 3;

  /// Null until the user actually picks a date (or when editing, seeded
  /// from the win's real date) — the field shows a placeholder rather than
  /// presupposing today, even though today is still what the date picker
  /// itself opens to, and what gets saved if the user never touches this.
  late DateTime? _date = widget.existingWin?.date ?? widget.initialDate;
  late String? _photoPath = widget.existingWin?.photoPath;

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
        date: _date ?? DateTime.now(),
        photoPath: _photoPath,
      ),
    );
  }

  /// Offers camera vs. gallery, then immediately copies whatever's picked
  /// into app-private storage (see [PhotoStorage]) — the picker's own path
  /// isn't guaranteed to still be valid once this screen is done with it.
  Future<void> _pickPhoto() async {
    final colors = context.colors;
    final strings = context.strings;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: colors.nightPanel,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_camera_outlined, color: colors.gold),
                title: Text(strings.takePhotoOption, style: TextStyle(color: colors.text)),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: colors.gold),
                title: Text(strings.choosePhotoOption, style: TextStyle(color: colors.text)),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (source == null || !mounted) return;

    // The picker/camera intent can fail for reasons outside our control
    // (no camera on this device or emulator, permission denied, no gallery
    // app installed) — surfaced here instead of failing silently, since a
    // tap that visibly does nothing is indistinguishable from a bug.
    try {
      final picked = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 85);
      if (picked == null || !mounted) return;

      final savedPath = await PhotoStorage.save(picked);
      if (!mounted) return;
      setState(() => _photoPath = savedPath);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.photoPickError)));
    }
  }

  void _removePhoto() {
    setState(() => _photoPath = null);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = _date;
    final picked = await showDatePicker(
      context: context,
      initialDate: current == null || current.isAfter(today) ? today : current,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        current?.hour ?? now.hour,
        current?.minute ?? now.minute,
        current?.second ?? now.second,
        current?.millisecond ?? now.millisecond,
      );
    });
  }

  /// A two-step picker — area (supernova) first, then that area's own
  /// constellations — rather than one flat list of every project across
  /// every area. Loops back to the area sheet if the user taps its back
  /// arrow, so switching areas doesn't mean re-opening the picker from
  /// scratch.
  Future<void> _openProjectPicker() async {
    final repository = widget.projectRepository;
    if (repository == null) return;

    while (mounted) {
      final area = await _pickArea();
      if (area == null || !mounted) return;

      final result = await _pickProjectInArea(repository, area);
      if (!mounted) return;
      if (result is _GoBackToAreaPicker) continue;

      if (result is Project) {
        setState(() => _selectedProject = result);
      } else if (result is _CreateNewProject) {
        final created = await Navigator.of(context).push<Project>(
          MaterialPageRoute(
            builder: (_) => NewProjectScreen(projectRepository: repository, presetArea: area),
          ),
        );
        if (created != null && mounted) {
          setState(() => _selectedProject = created);
        }
      }
      return;
    }
  }

  Future<LifeArea?> _pickArea() {
    final colors = context.colors;
    final strings = context.strings;

    return showModalBottomSheet<LifeArea>(
      context: context,
      backgroundColor: colors.nightPanel,
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
                  style: TextStyle(fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w600, color: colors.muted),
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

  Future<Object?> _pickProjectInArea(ProjectRepository repository, LifeArea area) {
    final colors = context.colors;

    return showModalBottomSheet<Object>(
      context: context,
      backgroundColor: colors.nightPanel,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _ProjectPickerSheet(area: area, projects: repository.getProjectsForArea(area));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

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
                    icon: Icon(Icons.arrow_back, color: colors.muted),
                  ),
                  Text(
                    widget.isEditing ? strings.editStarEyebrow : strings.newStarEyebrow,
                    style: TextStyle(fontSize: 12, letterSpacing: 1.4, fontWeight: FontWeight.w600, color: colors.gold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                strings.addWinQuestion,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24, color: colors.text),
              ),
              if (_selectedProject != null) ...[
                const SizedBox(height: 14),
                AreaTag(area: _selectedProject!.area, iconSize: 22, fontSize: 20),
              ],
              const SizedBox(height: 24),
              if (widget.lockedProject == null) ...[
                Text(strings.projectLabel, style: TextStyle(fontSize: 13, color: colors.muted)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _openProjectPicker,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: colors.nightPanel,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.nightBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _selectedProject != null
                              ? ProjectTag(
                                  project: _selectedProject!,
                                  iconSize: 18,
                                  fontSize: 15,
                                  textColor: colors.text,
                                )
                              : Text(strings.selectAProject, style: TextStyle(color: colors.muted, fontSize: 15)),
                        ),
                        Icon(Icons.expand_more, color: colors.muted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text(strings.dateLabel, style: TextStyle(fontSize: 13, color: colors.muted)),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.nightPanel,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.nightBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: colors.muted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _date == null
                            ? Text(strings.selectADateHint, style: TextStyle(color: colors.muted, fontSize: 15))
                            : Text(
                                formatDisplayDate(_date!, strings),
                                style: TextStyle(color: colors.text, fontSize: 15),
                              ),
                      ),
                      Icon(Icons.expand_more, color: colors.muted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(strings.titleFieldLabel, style: TextStyle(fontSize: 13, color: colors.muted)),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                style: TextStyle(color: colors.text, fontSize: 15),
                decoration: InputDecoration(hintText: strings.titleHint),
              ),
              const SizedBox(height: 20),
              Text(strings.detailsLabel, style: TextStyle(fontSize: 13, color: colors.muted)),
              const SizedBox(height: 6),
              TextField(
                controller: _descriptionController,
                minLines: 4,
                maxLines: 6,
                style: TextStyle(color: colors.text, fontSize: 15),
                decoration: InputDecoration(hintText: strings.detailsHint),
              ),
              const SizedBox(height: 20),
              Text(strings.intensityLabel, style: TextStyle(fontSize: 13, color: colors.muted)),
              const SizedBox(height: 10),
              Center(child: IntensityBolts(intensity: _intensity, size: 22, spacing: 6, emphasizeLast: true)),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: colors.gold,
                  inactiveTrackColor: colors.nightBorder,
                  thumbColor: colors.gold,
                  overlayColor: colors.gold.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: _intensity.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  // No label/value-indicator bubble — the star row above
                  // already shows the value more clearly, and the bubble
                  // ends up covering those stars while dragging.
                  onChanged: (value) => setState(() => _intensity = value.round()),
                ),
              ),
              const SizedBox(height: 20),
              Text(strings.photoLabel, style: TextStyle(fontSize: 13, color: colors.muted)),
              const SizedBox(height: 6),
              _PhotoPicker(photoPath: _photoPath, onPick: _pickPhoto, onRemove: _removePhoto),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _titleController,
                  builder: (context, value, child) {
                    final canSave = value.text.trim().isNotEmpty && _selectedProject != null;
                    return ElevatedButton(
                      onPressed: canSave ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.gold,
                        foregroundColor: colors.onGold,
                        disabledBackgroundColor: colors.nightBorder,
                        disabledForegroundColor: colors.muted,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        widget.isEditing ? strings.saveChanges : strings.lightThisStar,
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

/// The second step of [_AddWinScreenState._openProjectPicker] — search plus
/// a prominent create-new action, scoped to whatever [area] the user picked
/// in the first step, instead of one flat list of every constellation.
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
    return widget.projects.where((p) => p.name.toLowerCase().contains(query)).toList();
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
                  onPressed: () => Navigator.of(context).pop(const _GoBackToAreaPicker()),
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
                      strings.newProject,
                      style: TextStyle(color: colors.gold, fontWeight: FontWeight.w600, fontSize: 15),
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
                              ? strings.areaEmptyProjects(widget.area.displayName(strings))
                              : strings.noSearchResults,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.muted, fontSize: 14),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => Divider(color: colors.nightBorder, height: 1),
                      itemBuilder: (context, index) {
                        final project = filtered[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: ProjectTag(project: project, fontSize: 15, textColor: colors.text),
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

/// Either an empty tappable placeholder (no photo yet) or a preview of the
/// current photo, with a small remove button over its corner.
class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.photoPath, required this.onPick, required this.onRemove});

  final String? photoPath;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final path = photoPath;

    if (path == null) {
      return InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: colors.nightPanel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.nightBorder),
          ),
          child: Column(
            children: [
              Icon(Icons.add_a_photo_outlined, color: colors.muted, size: 22),
              const SizedBox(height: 8),
              Text(strings.addPhotoHint, style: TextStyle(color: colors.muted, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    final borderRadius = BorderRadius.circular(10);
    final previewSize = MediaQuery.sizeOf(context).width * 0.88;
    return SizedBox(
      width: double.infinity,
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            InkWell(
              onTap: onPick,
              borderRadius: borderRadius,
              child: ClipRRect(
                borderRadius: borderRadius,
                child: Image.file(File(path), width: previewSize, height: previewSize, fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: -6,
              right: -6,
              child: InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.night,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.nightBorder),
                  ),
                  child: Icon(Icons.close, size: 14, color: colors.muted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
