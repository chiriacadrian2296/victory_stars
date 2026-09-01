import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/custom_constellation_repository.dart';
import '../data/photo_storage.dart';
import '../data/project_repository.dart';
import '../l10n/strings_scope.dart';
import '../models/project.dart';
import '../models/star.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';
import '../widgets/area_tag.dart';
import '../widgets/intensity_bolts.dart';
import '../widgets/photo_picker.dart';
import '../widgets/project_picker.dart';
import '../widgets/project_tag.dart';
import '../widgets/responsive_content.dart';
import 'photo_crop_screen.dart';

/// What the user entered, handed back to whoever pushed this screen.
/// Trimming and blank-to-null normalization for [description] happen in
/// [StarRepository], not here, so that logic lives in one place regardless
/// of whether this was an add or an edit.
class AddStarResult {
  const AddStarResult({
    required this.title,
    this.description,
    required this.projectId,
    required this.achieved,
    this.targetDate,
    this.achievedDate,
    this.intensity,
    this.photoPath,
  });

  final String title;
  final String? description;
  final int projectId;

  /// Whether the "already achieved" toggle was on when this was saved —
  /// true means [achievedDate]/[intensity] are set (a victory); false means
  /// this is a goal, and [targetDate] (optional) is the only date that
  /// applies.
  final bool achieved;
  final DateTime? targetDate;
  final DateTime? achievedDate;
  final int? intensity;

  /// Already-saved app-private path (see [PhotoStorage]), or null for no
  /// photo — never a raw picker path.
  final String? photoPath;
}

/// Popped instead of [AddStarResult] when editing and the user deleted the
/// star instead of saving changes to it — see [StarRepository.delete]: this
/// tombstones the star rather than removing it.
class AddStarDeleteRequested {
  const AddStarDeleteRequested();
}

/// A single form for both victories and goals — they're the same
/// underlying [Star], differing only in whether the "already achieved"
/// toggle is on. Also doubles as the edit screen: pass [existingStar] to
/// pre-fill every field, including the toggle (derived from whether the
/// star already has an [Star.achievedDate]).
///
/// A project must be resolved one of two ways:
/// - [lockedProject]: the project is already known (e.g. opened from that
///   project's own constellation screen) and isn't user-selectable here.
/// - [projectRepository]: no project is implied yet, so [pickProject] lets
///   the user choose an existing project or create a new one inline.
///   Required whenever [lockedProject] isn't given — including when
///   editing, since the picker is how a star's project gets reassigned.
class AddStarScreen extends StatefulWidget {
  const AddStarScreen({
    super.key,
    this.existingStar,
    this.lockedProject,
    this.projectRepository,
    this.customConstellationRepository,
    this.contextProject,
    this.initialDate,
    this.initialAchieved = true,
    this.hideDelete = false,
  }) : assert(
         lockedProject != null ||
             (projectRepository != null &&
                 customConstellationRepository != null),
         'Provide lockedProject (pre-scoped, no picker) or both projectRepository and customConstellationRepository (picker, for add or edit).',
       );

  final Star? existingStar;
  final Project? lockedProject;
  final ProjectRepository? projectRepository;

  /// Required alongside [projectRepository] whenever [lockedProject] isn't
  /// given — the project picker offers an inline "create new project"
  /// action that needs it (see [pickProject]).
  final CustomConstellationRepository? customConstellationRepository;

  /// The existing star's current project, resolved by the caller — seeds
  /// the picker's initial selection when editing.
  final Project? contextProject;

  /// Pre-fills the achieved date when creating a new victory directly (e.g.
  /// opened from a specific day on the dashboard calendar) — ignored when
  /// [existingStar] is set or when the achieved toggle starts off.
  final DateTime? initialDate;

  /// Which side of the achieved/goal toggle a brand new star starts on —
  /// set by whichever entry (Victory vs Goal) the caller's FAB chooser used.
  /// Ignored when [existingStar] is set, since editing always derives the
  /// toggle from the star's own state.
  final bool initialAchieved;

  /// Hides the delete FAB — used when this screen is really a "resurrect a
  /// dead star" flow (see `StarReaderScreen._editOrResurrectCurrent`), since
  /// a dead star has nothing further to delete.
  final bool hideDelete;

  bool get isEditing => existingStar != null;

  @override
  State<AddStarScreen> createState() => _AddStarScreenState();
}

class _AddStarScreenState extends State<AddStarScreen> {
  late final _titleController = TextEditingController(
    text: widget.existingStar?.title ?? '',
  );
  late final _descriptionController = TextEditingController(
    text: widget.existingStar?.description ?? '',
  );
  late Project? _selectedProject =
      widget.lockedProject ?? widget.contextProject;
  late bool _achieved = widget.existingStar != null
      ? widget.existingStar!.achievedDate != null
      : widget.initialAchieved;
  late int _intensity = widget.existingStar?.intensity ?? 3;

  /// Null until the user actually picks a date (or when editing an achieved
  /// star, seeded from its real achieved date).
  late DateTime? _date =
      widget.existingStar?.achievedDate ??
      (widget.initialAchieved ? widget.initialDate : null);
  late DateTime? _targetDate = widget.existingStar?.targetDate;
  late String? _photoPath = widget.existingStar?.photoPath;

  // What the form above started out as — captured once, alongside it, so
  // _hasUnsavedChanges has something to compare against regardless of
  // whether this is a blank new-star form or one seeded from an existing
  // star. Deliberately mirrors each field's own initializer.
  late final String _initialTitle = widget.existingStar?.title ?? '';
  late final String _initialDescription =
      widget.existingStar?.description ?? '';
  late final int? _initialProjectId =
      (widget.lockedProject ?? widget.contextProject)?.id;
  late final bool _initialAchieved = _achieved;
  late final int _initialIntensity = widget.existingStar?.intensity ?? 3;
  late final DateTime? _initialDate = _date;
  late final DateTime? _initialTargetDate = widget.existingStar?.targetDate;
  late final String? _initialPhotoPath = widget.existingStar?.photoPath;

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
    final normalizedDescription = trimmedDescription.isEmpty
        ? null
        : trimmedDescription;
    final normalizedInitialDescription = _initialDescription.isEmpty
        ? null
        : _initialDescription;
    return _titleController.text.trim() != _initialTitle ||
        normalizedDescription != normalizedInitialDescription ||
        _selectedProject?.id != _initialProjectId ||
        _achieved != _initialAchieved ||
        (_achieved &&
            (_intensity != _initialIntensity || _date != _initialDate)) ||
        (!_achieved && _targetDate != _initialTargetDate) ||
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
    if (confirmed && mounted)
      Navigator.of(context).pop(const AddStarDeleteRequested());
  }

  /// A yes/no dialog styled like the rest of the app's destructive
  /// confirmations (see [SettingsScreen]'s reset-all-data prompt) — a
  /// muted cancel next to a [danger]-colored confirm action.
  Future<bool> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
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
      AddStarResult(
        title: title,
        description: _descriptionController.text,
        projectId: project.id,
        achieved: _achieved,
        targetDate: _achieved ? null : _targetDate,
        achievedDate: _achieved ? (_date ?? DateTime.now()) : null,
        intensity: _achieved ? _intensity : null,
        photoPath: _achieved ? _photoPath : null,
      ),
    );
  }

  void _showCannotSaveMessage() {
    final colors = context.colors;
    final strings = context.strings;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.nightPanel,
        content: Text(
          strings.cannotSaveMissingInfo,
          style: TextStyle(color: colors.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.gotIt, style: TextStyle(color: colors.gold)),
          ),
        ],
      ),
    );
  }

  /// Offers camera vs. gallery, sends whatever's picked through
  /// [PhotoCropScreen] to force it into 9:16, and copies the cropped result
  /// into app-private storage (see [PhotoStorage]).
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
                title: Text(
                  strings.takePhotoOption,
                  style: TextStyle(color: colors.text),
                ),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: colors.gold),
                title: Text(
                  strings.choosePhotoOption,
                  style: TextStyle(color: colors.text),
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (source == null || !mounted) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      final croppedBytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          builder: (_) => PhotoCropScreen(imageFile: File(picked.path)),
        ),
      );
      if (croppedBytes == null || !mounted) return;

      final savedPath = await PhotoStorage.saveBytes(croppedBytes);
      if (!mounted) return;
      setState(() => _photoPath = savedPath);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.photoPickError)));
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

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final current = _date;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: current?.hour ?? now.hour,
        minute: current?.minute ?? now.minute,
      ),
    );
    if (picked == null) return;
    final base = current ?? DateTime(now.year, now.month, now.day);
    setState(() {
      _date = DateTime(
        base.year,
        base.month,
        base.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _pickTargetDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 20),
    );
    if (picked == null) return;
    setState(() => _targetDate = picked);
  }

  Future<void> _openProjectPicker() async {
    final repository = widget.projectRepository;
    final customConstellationRepository = widget.customConstellationRepository;
    if (repository == null || customConstellationRepository == null) return;
    final picked = await pickProject(
      context,
      repository,
      customConstellationRepository,
    );
    if (picked != null && mounted) {
      setState(() => _selectedProject = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    final scaffold = Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: ResponsiveContent(
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
                      widget.isEditing
                          ? strings.editStarEyebrow
                          : strings.newStarEyebrow,
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w600,
                        color: colors.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: _AchievedToggle(
                    achieved: _achieved,
                    onChanged: (value) => setState(() => _achieved = value),
                  ),
                ),
                const SizedBox(height: 20),
                // A fixed minimum height, not just a Text — the goal question
                // is much longer than the victory one and wraps to 2 lines,
                // so without this the constellation field (and everything
                // below it) starts at a different Y depending on which
                // question is showing. minHeight (not a fixed height) so an
                // unexpectedly long translation still isn't clipped. Centered
                // within that reserved space so the shorter, 1-line victory
                // question doesn't sit stuck to the top of it.
                Container(
                  constraints: const BoxConstraints(minHeight: 76),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _achieved
                        ? strings.addWinQuestion
                        : strings.addGoalQuestion,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      color: colors.text,
                    ),
                  ),
                ),
                if (_selectedProject != null) ...[
                  const SizedBox(height: 14),
                  AreaTag(
                    area: _selectedProject!.area,
                    iconSize: 22,
                    fontSize: 20,
                  ),
                ],
                const SizedBox(height: 24),
                if (widget.lockedProject == null) ...[
                  Text(
                    strings.projectLabel,
                    style: TextStyle(fontSize: 13, color: colors.muted),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _openProjectPicker,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
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
                                : Text(
                                    strings.selectAProject,
                                    style: TextStyle(
                                      color: colors.muted,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                          Icon(Icons.expand_more, color: colors.muted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (_achieved) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _DateField(
                          label: strings.dateLabel,
                          hint: strings.selectADateHint,
                          icon: Icons.calendar_today,
                          text: _date == null
                              ? null
                              : formatDisplayDate(_date!, strings),
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateField(
                          label: strings.timeLabel,
                          hint: strings.selectATimeHint,
                          icon: Icons.access_time,
                          text: _date == null
                              ? null
                              : formatDisplayTime(_date!),
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  _DateField(
                    label: strings.targetDateLabel,
                    hint: strings.selectATargetDateHint,
                    icon: Icons.flag_outlined,
                    text: _targetDate == null
                        ? null
                        : formatDisplayDate(_targetDate!, strings),
                    onTap: _pickTargetDate,
                  ),
                  const SizedBox(height: 20),
                ],
                Text(
                  strings.titleFieldLabel,
                  style: TextStyle(fontSize: 13, color: colors.muted),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: colors.text, fontSize: 15),
                  decoration: InputDecoration(hintText: strings.titleHint),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),
                Text(
                  strings.detailsLabel,
                  style: TextStyle(fontSize: 13, color: colors.muted),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _descriptionController,
                  minLines: 4,
                  maxLines: 6,
                  style: TextStyle(color: colors.text, fontSize: 15),
                  decoration: InputDecoration(hintText: strings.detailsHint),
                  onChanged: (_) => setState(() {}),
                ),
                if (_achieved) ...[
                  const SizedBox(height: 20),
                  Text(
                    strings.intensityLabel,
                    style: TextStyle(fontSize: 13, color: colors.muted),
                  ),
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
                          onChanged: (value) =>
                              setState(() => _intensity = value.round()),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    strings.photoLabel,
                    style: TextStyle(fontSize: 13, color: colors.muted),
                  ),
                  const SizedBox(height: 6),
                  PhotoPicker(
                    photoPath: _photoPath,
                    onPick: _pickPhoto,
                    onRemove: _removePhoto,
                  ),
                ],
                const SizedBox(height: 20),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.isEditing && !widget.hideDelete) ...[
                        FloatingActionButton(
                          heroTag: 'deleteStarFab',
                          onPressed: _confirmAndDelete,
                          backgroundColor: colors.danger,
                          elevation: 0,
                          shape: const CircleBorder(),
                          tooltip: strings.deleteStarAction,
                          child: Icon(
                            Icons.delete_outline,
                            color: colors.night,
                          ),
                        ),
                        const SizedBox(width: 20),
                      ],
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _titleController,
                        builder: (context, value, child) {
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
                                        color: colors.gold.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: FloatingActionButton(
                              heroTag: 'saveStarFab',
                              onPressed: canSave
                                  ? _save
                                  : _showCannotSaveMessage,
                              backgroundColor: canSave
                                  ? colors.gold
                                  : colors.muted,
                              elevation: 0,
                              shape: const CircleBorder(),
                              tooltip: widget.isEditing
                                  ? strings.saveChanges
                                  : strings.lightThisStar,
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
      ),
    );

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

/// A two-way switch between "already achieved" (a victory) and "future
/// goal" — the one control that decides which half of the form below shows.
class _AchievedToggle extends StatelessWidget {
  const _AchievedToggle({required this.achieved, required this.onChanged});

  final bool achieved;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    return SegmentedButton<bool>(
      style: SegmentedButton.styleFrom(
        backgroundColor: colors.nightPanel,
        foregroundColor: colors.muted,
        selectedBackgroundColor: colors.gold,
        selectedForegroundColor: colors.onGold,
        side: BorderSide(color: colors.nightBorder),
      ),
      segments: [
        ButtonSegment(
          value: true,
          icon: const Icon(Icons.star, size: 16),
          label: Text(strings.achievedToggleOn),
        ),
        ButtonSegment(
          value: false,
          icon: const Icon(Icons.flag_outlined, size: 16),
          label: Text(strings.achievedToggleOff),
        ),
      ],
      selected: {achieved},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final String label;
  final String hint;
  final IconData icon;
  final String? text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: colors.muted)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
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
                Icon(icon, size: 16, color: colors.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text ?? hint,
                    style: TextStyle(
                      color: text == null ? colors.muted : colors.text,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
