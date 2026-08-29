import 'dart:io';
import 'dart:typed_data';

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
import 'photo_crop_screen.dart';

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

/// Popped instead of [AddWinResult] when editing and the user deleted the
/// win instead of saving changes to it. Kept as its own type (rather than a
/// flag on [AddWinResult]) since a delete has none of that class's other,
/// required fields to fill in.
class AddWinDeleteRequested {
  const AddWinDeleteRequested();
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

  // What the form above started out as — captured once, alongside it, so
  // _hasUnsavedChanges has something to compare against regardless of
  // whether this is a blank new-star form or one seeded from an existing
  // win. Deliberately mirrors each field's own initializer.
  late final String _initialTitle = widget.existingWin?.title ?? '';
  late final String _initialDescription = widget.existingWin?.description ?? '';
  late final int? _initialProjectId = (widget.lockedProject ?? widget.contextProject)?.id;
  late final int _initialIntensity = widget.existingWin?.intensity ?? 3;
  late final DateTime? _initialDate = widget.existingWin?.date ?? widget.initialDate;
  late final String? _initialPhotoPath = widget.existingWin?.photoPath;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Whether the form has drifted from how it started — true for a new
  /// star as soon as the user's typed or picked anything, not just when
  /// editing one that already existed. Drives whether leaving the page
  /// needs a confirmation first.
  bool get _hasUnsavedChanges {
    final trimmedDescription = _descriptionController.text.trim();
    final normalizedDescription = trimmedDescription.isEmpty ? null : trimmedDescription;
    final normalizedInitialDescription = _initialDescription.isEmpty ? null : _initialDescription;
    return _titleController.text.trim() != _initialTitle ||
        normalizedDescription != normalizedInitialDescription ||
        _selectedProject?.id != _initialProjectId ||
        _intensity != _initialIntensity ||
        _date != _initialDate ||
        _photoPath != _initialPhotoPath;
  }

  /// Shared by the back button and the system back gesture: leaving with
  /// unsaved changes needs confirmation first, everything else pops right
  /// away.
  Future<void> _handleBack() async {
    if (!_hasUnsavedChanges) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await _confirm(
      title: context.strings.discardChangesConfirmTitle,
      body: context.strings.discardChangesConfirmBody,
      confirmLabel: context.strings.discardChangesAction,
    );
    if (discard && mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmAndDelete() async {
    final confirmed = await _confirm(
      title: context.strings.deleteStarConfirmTitle,
      body: context.strings.deleteStarConfirmBody,
      confirmLabel: context.strings.deleteStarAction,
    );
    if (confirmed && mounted) Navigator.of(context).pop(const AddWinDeleteRequested());
  }

  /// A yes/no dialog styled like the rest of the app's destructive
  /// confirmations (see [SettingsScreen]'s reset-all-data prompt) — a
  /// muted cancel next to a [danger]-colored confirm action.
  Future<bool> _confirm({required String title, required String body, required String confirmLabel}) async {
    final colors = context.colors;
    final strings = context.strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.nightPanel,
        title: Text(title, style: TextStyle(color: colors.text)),
        content: Text(body, style: TextStyle(color: colors.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel, style: TextStyle(color: colors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel, style: TextStyle(color: colors.danger)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
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

  /// Offers camera vs. gallery, sends whatever's picked through
  /// [PhotoCropScreen] to force it into 9:16 — the portrait shape every win
  /// photo is shown in as a full-bleed background (see
  /// win_reader_screen.dart), which a camera shot or an arbitrarily-shaped
  /// gallery photo won't already be — and copies the cropped result into
  /// app-private storage (see
  /// [PhotoStorage]) since neither the picker's own path nor the crop
  /// screen's output are guaranteed to still be valid once this screen is
  /// done with them.
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

      final croppedBytes = await Navigator.of(
        context,
      ).push<Uint8List>(MaterialPageRoute(builder: (_) => PhotoCropScreen(imageFile: File(picked.path))));
      if (croppedBytes == null || !mounted) return;

      final savedPath = await PhotoStorage.saveBytes(croppedBytes);
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
      );
    });
  }

  /// Without this, a star's time-of-day could only ever come from whatever
  /// [DateTime.now] happened to be when the date was picked (or, for a date
  /// that arrived already fixed — like "add a star for this day" from the
  /// dashboard calendar — midnight, since that flow only knows the day, not
  /// a time) — with no way to see or correct it afterward.
  Future<void> _pickTime() async {
    final now = DateTime.now();
    final current = _date;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current?.hour ?? now.hour, minute: current?.minute ?? now.minute),
    );
    if (picked == null) return;
    final base = current ?? DateTime(now.year, now.month, now.day);
    setState(() {
      _date = DateTime(base.year, base.month, base.day, picked.hour, picked.minute);
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

    final scaffold = Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _handleBack,
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                      ? Text(
                                          strings.selectADateHint,
                                          style: TextStyle(color: colors.muted, fontSize: 15),
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : Text(
                                          formatDisplayDate(_date!, strings),
                                          style: TextStyle(color: colors.text, fontSize: 15),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(strings.timeLabel, style: TextStyle(fontSize: 13, color: colors.muted)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickTime,
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
                                Icon(Icons.access_time, size: 16, color: colors.muted),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _date == null
                                      ? Text(
                                          strings.selectATimeHint,
                                          style: TextStyle(color: colors.muted, fontSize: 15),
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : Text(
                                          formatDisplayTime(_date!),
                                          style: TextStyle(color: colors.text, fontSize: 15),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(strings.titleFieldLabel, style: TextStyle(fontSize: 13, color: colors.muted)),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                style: TextStyle(color: colors.text, fontSize: 15),
                decoration: InputDecoration(hintText: strings.titleHint),
                // Typing here alone doesn't otherwise rebuild this widget,
                // which would leave _hasUnsavedChanges (and so the discard-
                // changes prompt) stuck reflecting whatever it was before
                // this keystroke.
                onChanged: (_) => setState(() {}),
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
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              Text(strings.intensityLabel, style: TextStyle(fontSize: 13, color: colors.muted)),
              const SizedBox(height: 10),
              Center(
                child: IntensityBolts(
                  intensity: _intensity,
                  size: 26,
                  spacing: 6,
                  emphasizeLast: true,
                  emphasizedScale: 1.6,
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: FractionallySizedBox(
                  widthFactor: 0.7,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: colors.gold,
                      inactiveTrackColor: colors.nightBorder,
                      thumbColor: colors.gold,
                      overlayColor: Colors.transparent,
                      overlayShape: SliderComponentShape.noOverlay,
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
                ),
              ),
              const SizedBox(height: 20),
              Text(strings.photoLabel, style: TextStyle(fontSize: 13, color: colors.muted)),
              const SizedBox(height: 6),
              _PhotoPicker(photoPath: _photoPath, onPick: _pickPhoto, onRemove: _removePhoto),
              const SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isEditing) ...[
                      // Solid danger-red disc with the app's own background
                      // color cut through for the icon, rather than a dark
                      // disc with a red icon — same treatment the save
                      // button below uses for its own accent color.
                      FloatingActionButton(
                        heroTag: 'deleteWinFab',
                        onPressed: _confirmAndDelete,
                        backgroundColor: colors.danger,
                        elevation: 0,
                        shape: const CircleBorder(),
                        tooltip: strings.deleteStarAction,
                        child: Icon(Icons.delete_outline, color: colors.night),
                      ),
                      const SizedBox(width: 20),
                    ],
                    // Same look (gold, circular, glowing) as the home
                    // dashboard's own FAB — just without its long-press
                    // menu, since there's nothing here to choose between.
                    // Always the same check icon; only the disc's own color
                    // (and the glow) says whether the form is ready to save.
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _titleController,
                      builder: (context, value, child) {
                        // Editing also requires an actual change — a form
                        // that already validly describes the win it was
                        // opened from has nothing new worth saving yet.
                        final canSave =
                            value.text.trim().isNotEmpty &&
                            _selectedProject != null &&
                            (!widget.isEditing || _hasUnsavedChanges);
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: canSave
                                ? [
                                    BoxShadow(
                                      color: colors.gold.withValues(alpha: 0.35),
                                      blurRadius: 20,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]
                                : null,
                          ),
                          child: FloatingActionButton(
                            heroTag: 'saveWinFab',
                            onPressed: canSave ? _save : null,
                            backgroundColor: canSave ? colors.gold : colors.muted,
                            elevation: 0,
                            shape: const CircleBorder(),
                            tooltip: widget.isEditing ? strings.saveChanges : strings.lightThisStar,
                            child: Icon(Icons.check, color: colors.night),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Unsaved changes — whether that's an edit gone unsaved or a new star
    // half filled-in — need a confirmation before the system back gesture/
    // button is allowed to actually leave the page — the app bar's own back
    // button routes through the same _handleBack instead of popping
    // directly.
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: scaffold,
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
    // Matches the 9:16 every win photo is saved as (see PhotoCropScreen), so
    // the preview isn't misleadingly squarer than what actually gets shown
    // as the star's background.
    final previewWidth = MediaQuery.sizeOf(context).width * 0.88;
    final previewHeight = previewWidth * 16 / 9;
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
                child: Image.file(File(path), width: previewWidth, height: previewHeight, fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: -6,
              right: -6,
              child: InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colors.night,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.gold),
                  ),
                  child: Icon(Icons.close, size: 22, color: colors.gold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
