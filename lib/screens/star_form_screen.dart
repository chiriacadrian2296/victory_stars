import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/custom_constellation_repository.dart';
import '../data/photo_storage.dart';
import '../data/project_repository.dart';
import '../l10n/app_strings.dart';
import '../l10n/strings_scope.dart';
import '../models/habit.dart';
import '../models/project.dart';
import '../models/star.dart';
import '../models/star_kind.dart';
import '../theme/app_colors.dart';
import '../theme/app_style.dart';
import '../utils/date_format.dart';
import '../utils/icon_for_slug.dart';
import '../widgets/app_field.dart';
import '../widgets/area_tag.dart';
import '../widgets/intensity_bolts.dart';
import '../widgets/photo_picker.dart';
import '../widgets/pill_action_button.dart';
import '../widgets/project_picker.dart';
import '../widgets/responsive_content.dart';
import '../widgets/star_glyph.dart';
import 'photo_crop_screen.dart';

/// What the user entered, handed back to whoever pushed this screen.
/// Trimming and blank-to-null normalization for [description] happen in the
/// repositories, not here, so that logic lives in one place regardless of
/// whether this was an add or an edit.
class StarFormResult {
  const StarFormResult({
    required this.kind,
    required this.title,
    this.description,
    required this.projectId,
    this.slotSequence,
    this.targetDate,
    this.achievedDate,
    this.intensity,
    this.photoPath,
    this.reminderHour,
    this.reminderMinute,
  });

  /// Which kind of star was chosen — always one of [kCreatableStarKinds].
  /// A [StarKind.pulsar] result belongs to [HabitRepository]; the other two
  /// belong to [StarRepository]. Callers switch on this rather than
  /// inspecting which optional fields happen to be filled in.
  final StarKind kind;

  final String title;
  final String? description;
  final int projectId;

  /// Set only when this form was opened by tapping a *nascent* star — the
  /// exact slot on the constellation's shape the new star has to land on.
  /// Null everywhere else, meaning "append to the end".
  final int? slotSequence;

  /// [StarKind.unlit] only — the optional date it's aimed at.
  final DateTime? targetDate;

  /// [StarKind.lit] only — when the effort was actually made.
  final DateTime? achievedDate;

  /// The intensity of the effort, 1-5. Set for [StarKind.lit] and
  /// [StarKind.pulsar]; null for [StarKind.unlit], whose real cost isn't
  /// knowable until it's lit.
  final int? intensity;

  /// Already-saved app-private path (see [PhotoStorage]), or null for no
  /// photo — never a raw picker path. [StarKind.lit] only.
  final String? photoPath;

  /// [StarKind.pulsar] only. Both null = inherits the app's single global
  /// reminder time.
  final int? reminderHour;
  final int? reminderMinute;
}

/// Popped instead of [StarFormResult] when editing and the user deleted the
/// star instead of saving changes to it — see [StarRepository.delete] /
/// [HabitRepository.delete]: both tombstone rather than erase.
class StarFormDeleteRequested {
  const StarFormDeleteRequested();
}

/// The one place any star is created or edited, whichever kind it is — a
/// lit star (a past victory), a pulsar (a present habit), or an unlit star
/// (a future goal). They're all the same thing at heart, *one effort*, so
/// they share one form and one switch between them rather than a separate
/// page per kind.
///
/// Also doubles as the edit screen: pass [existingStar] or [existingHabit]
/// to pre-fill every field. Editing never lets the kind switch across the
/// star/pulsar line (that would mean converting one stored entity into
/// another) — a star can still move between lit and unlit, which is just
/// its own [Star.achievedDate] changing.
///
/// A project must be resolved one of two ways:
/// - [lockedProject]: the project is already known (e.g. opened from that
///   constellation's own screen) and isn't user-selectable here.
/// - [projectRepository]: no project is implied yet, so [pickProject] lets
///   the user choose an existing constellation or create a new one inline.
///   Required whenever [lockedProject] isn't given — including when
///   editing, since the picker is how a star gets moved to another
///   constellation.
class StarFormScreen extends StatefulWidget {
  const StarFormScreen({
    super.key,
    this.existingStar,
    this.existingHabit,
    this.lockedProject,
    this.projectRepository,
    this.starsShapeRepository,
    this.contextProject,
    this.initialDate,
    this.initialKind = StarKind.lit,
    this.slotSequence,
    this.allowPulsar = true,
    this.hideDelete = false,
  }) : assert(
         existingStar == null || existingHabit == null,
         'A form edits either a star or a pulsar, never both.',
       ),
       assert(
         lockedProject != null ||
             (projectRepository != null &&
                 starsShapeRepository != null),
         'Provide lockedProject (pre-scoped, no picker) or both projectRepository and starsShapeRepository (picker, for add or edit).',
       );

  final Star? existingStar;
  final Habit? existingHabit;
  final Project? lockedProject;
  final ProjectRepository? projectRepository;

  /// Required alongside [projectRepository] whenever [lockedProject] isn't
  /// given — the constellation picker offers an inline "create new" action
  /// that needs it (see [pickProject]).
  final StarsShapeRepository? starsShapeRepository;

  /// The existing star's current constellation, resolved by the caller —
  /// seeds the picker's initial selection when editing.
  final Project? contextProject;

  /// Pre-fills the date when lighting a star directly (e.g. opened from a
  /// specific day on the dashboard calendar) — ignored when editing or when
  /// the form doesn't start on [StarKind.lit].
  final DateTime? initialDate;

  /// Which kind a brand new star starts as — set by whichever entry point
  /// opened this form. Ignored when editing, since that always derives the
  /// kind from what's actually stored.
  final StarKind initialKind;

  /// Set when this form was opened by tapping a nascent star: the slot that
  /// star occupies on its constellation's shape, handed straight back in
  /// the result so the new star lands exactly there. Also switches the
  /// header over to "configure this star" wording, since that's what's
  /// really happening — the star already exists in the sky, it's being
  /// given a meaning.
  final int? slotSequence;

  /// Whether the pulsar option is offered. False when configuring a nascent
  /// star: that slot belongs to the constellation's own shape, and a pulsar
  /// doesn't sit on the shape at all — it scatters around it.
  final bool allowPulsar;

  /// Hides the delete button — used when this form is really a "reignite a
  /// dead star" flow, since a dead star has nothing further to delete.
  final bool hideDelete;

  bool get isEditing => existingStar != null || existingHabit != null;

  @override
  State<StarFormScreen> createState() => _StarFormScreenState();
}

class _StarFormScreenState extends State<StarFormScreen> {
  late final _titleController = TextEditingController(text: _initialTitle);
  late final _descriptionController = TextEditingController(
    text: _initialDescription,
  );

  late StarKind _kind = _resolveInitialKind();
  late Project? _selectedProject =
      widget.lockedProject ?? widget.contextProject;
  late int _intensity =
      widget.existingStar?.intensity ?? widget.existingHabit?.intensity ?? 3;

  /// Null until the user actually picks a date (or, when editing a lit
  /// star, seeded from the date it was lit on).
  late DateTime? _date =
      widget.existingStar?.achievedDate ??
      (_kind == StarKind.lit ? widget.initialDate : null);
  late DateTime? _targetDate = widget.existingStar?.targetDate;
  late String? _photoPath = widget.existingStar?.photoPath;
  late bool _customReminder = widget.existingHabit?.reminderHour != null;
  late int _reminderHour = widget.existingHabit?.reminderHour ?? 9;
  late int _reminderMinute = widget.existingHabit?.reminderMinute ?? 0;

  // What the form above started out as — captured once, alongside it, so
  // _hasUnsavedChanges has something to compare against regardless of
  // whether this is a blank new-star form or one seeded from something that
  // already exists. Deliberately mirrors each field's own initializer.
  late final int? _initialProjectId =
      (widget.lockedProject ?? widget.contextProject)?.id;
  late final StarKind _initialKind = _kind;
  late final int _initialIntensity = _intensity;
  late final DateTime? _initialDateValue = _date;
  late final DateTime? _initialTargetDate = widget.existingStar?.targetDate;
  late final String? _initialPhotoPath = widget.existingStar?.photoPath;
  late final bool _initialCustomReminder = _customReminder;
  late final int _initialReminderHour = _reminderHour;
  late final int _initialReminderMinute = _reminderMinute;

  String get _initialTitle =>
      widget.existingStar?.title ?? widget.existingHabit?.title ?? '';
  String get _initialDescription =>
      widget.existingStar?.description ??
      widget.existingHabit?.description ??
      '';

  /// Which kinds this particular form is allowed to switch between — see
  /// the class doc: editing never crosses the star/pulsar line, and a
  /// nascent slot can only become a star.
  List<StarKind> get _availableKinds {
    if (widget.existingHabit != null) return const [StarKind.pulsar];
    if (widget.existingStar != null) {
      return const [StarKind.lit, StarKind.unlit];
    }
    if (!widget.allowPulsar) return const [StarKind.lit, StarKind.unlit];
    return kCreatableStarKinds;
  }

  StarKind _resolveInitialKind() {
    if (widget.existingHabit != null) return StarKind.pulsar;
    if (widget.existingStar case final star?) {
      return star.isLit ? StarKind.lit : StarKind.unlit;
    }
    if (!widget.allowPulsar && widget.initialKind == StarKind.pulsar) {
      return StarKind.lit;
    }
    return widget.initialKind;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Whether the form has drifted from how it started — true for a new star
  /// as soon as the user's typed or picked anything, not just when editing
  /// one that already existed. Drives whether leaving the page needs a
  /// confirmation first.
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
        _kind != _initialKind ||
        (_kind != StarKind.unlit && _intensity != _initialIntensity) ||
        (_kind == StarKind.lit &&
            (_date != _initialDateValue ||
                _photoPath != _initialPhotoPath)) ||
        (_kind == StarKind.unlit && _targetDate != _initialTargetDate) ||
        (_kind == StarKind.pulsar &&
            (_customReminder != _initialCustomReminder ||
                (_customReminder &&
                    (_reminderHour != _initialReminderHour ||
                        _reminderMinute != _initialReminderMinute))));
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
    final strings = context.strings;
    final isPulsar = _kind == StarKind.pulsar;
    final confirmed = await _confirm(
      title: isPulsar
          ? strings.deletePulsarConfirmTitle
          : strings.deleteStarConfirmTitle,
      body: isPulsar
          ? strings.deletePulsarConfirmBody
          : strings.deleteStarConfirmBody,
      confirmLabel: strings.deleteStarAction,
    );
    if (confirmed && mounted) {
      Navigator.of(context).pop(const StarFormDeleteRequested());
    }
  }

  /// A yes/no dialog styled like the rest of the app's destructive
  /// confirmations — a muted cancel next to a [AppColors.danger]-colored
  /// confirm action.
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
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(foregroundColor: colors.muted),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: colors.danger),
            child: Text(confirmLabel),
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
      StarFormResult(
        kind: _kind,
        title: title,
        description: _descriptionController.text,
        projectId: project.id,
        slotSequence: widget.slotSequence,
        targetDate: _kind == StarKind.unlit ? _targetDate : null,
        achievedDate: _kind == StarKind.lit ? (_date ?? DateTime.now()) : null,
        intensity: _kind == StarKind.unlit ? null : _intensity,
        photoPath: _kind == StarKind.lit ? _photoPath : null,
        reminderHour: _kind == StarKind.pulsar && _customReminder
            ? _reminderHour
            : null,
        reminderMinute: _kind == StarKind.pulsar && _customReminder
            ? _reminderMinute
            : null,
      ),
    );
  }

  void _showCannotSaveMessage() {
    final strings = context.strings;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: Text(strings.cannotSaveMissingInfo),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.gotIt),
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
        MaterialPageRoute(builder: (_) => PhotoCropScreen(imageFile: picked)),
      );
      if (croppedBytes == null || !mounted) return;

      final savedPath = await PhotoStorage.saveBytes(croppedBytes);
      if (!mounted) return;
      setState(() => _photoPath = savedPath);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.photoPickError)));
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

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
    );
    if (picked == null) return;
    setState(() {
      _reminderHour = picked.hour;
      _reminderMinute = picked.minute;
    });
  }

  Future<void> _openProjectPicker() async {
    final repository = widget.projectRepository;
    final starsShapeRepository = widget.starsShapeRepository;
    if (repository == null || starsShapeRepository == null) return;
    final picked = await pickProject(
      context,
      repository,
      starsShapeRepository,
    );
    if (picked != null && mounted) {
      setState(() => _selectedProject = picked);
    }
  }

  String _question(AppStrings strings) => switch (_kind) {
    StarKind.lit => strings.litStarQuestion,
    StarKind.unlit => strings.unlitStarQuestion,
    StarKind.pulsar => strings.pulsarQuestion,
    // Neither is ever the form's own kind — see [_availableKinds].
    StarKind.nascent || StarKind.dead => strings.litStarQuestion,
  };

  String _eyebrow(AppStrings strings) {
    if (widget.slotSequence != null && !widget.isEditing) {
      return strings.configureStarEyebrow;
    }
    return widget.isEditing ? strings.editStarEyebrow : strings.newStarEyebrow;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final kinds = _availableKinds;

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
                      _eyebrow(strings),
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
                // The one control that decides which half of the form
                // below shows. Omitted entirely when there's nothing to
                // choose (editing a pulsar) — a one-option switch is just
                // a label pretending to be a control.
                if (kinds.length > 1)
                  _StarKindSwitch(
                    kinds: kinds,
                    selected: _kind,
                    onChanged: (kind) => setState(() => _kind = kind),
                  )
                else
                  Center(
                    child: _StarKindMeaning(kind: _kind, showGlyph: true),
                  ),
                const SizedBox(height: 18),
                // A fixed minimum height, not just a Text — the three
                // questions are different lengths and wrap differently, so
                // without this everything below them jumps as the kind
                // changes. minHeight (not a fixed height) so an
                // unexpectedly long translation still isn't clipped.
                Container(
                  constraints: const BoxConstraints(minHeight: 76),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _question(strings),
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
                  AppPickerField(
                    label: strings.projectLabel,
                    hint: strings.selectAProject,
                    icon: _selectedProject == null
                        ? Icons.auto_awesome_outlined
                        : iconForSlug(_selectedProject!.iconSlug),
                    text: _selectedProject?.name,
                    onTap: _openProjectPicker,
                    trailing: Icon(Icons.expand_more, color: colors.muted),
                  ),
                  const SizedBox(height: 20),
                ],
                if (_kind == StarKind.lit) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppPickerField(
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
                        child: AppPickerField(
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
                ] else if (_kind == StarKind.unlit) ...[
                  AppPickerField(
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
                AppFieldLabel(strings.titleFieldLabel),
                const SizedBox(height: 6),
                AppTextField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  hintText: _kind == StarKind.pulsar
                      ? strings.pulsarTitleHint
                      : strings.titleHint,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),
                AppFieldLabel(strings.detailsLabel),
                const SizedBox(height: 6),
                AppTextField(
                  controller: _descriptionController,
                  minLines: _kind == StarKind.pulsar ? 3 : 4,
                  maxLines: 6,
                  hintText: strings.detailsHint,
                  onChanged: (_) => setState(() {}),
                ),
                // Every kind that's already burning carries an intensity —
                // a lit star's is what the effort cost once, a pulsar's
                // what it costs each day. An unlit star has none yet: it
                // gets one the moment it's lit.
                if (_kind != StarKind.unlit) ...[
                  const SizedBox(height: 20),
                  AppFieldLabel(strings.intensityLabel),
                  const SizedBox(height: 4),
                  Text(
                    strings.intensityCaption,
                    style: TextStyle(fontSize: 12, color: colors.muted),
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
                ],
                if (_kind == StarKind.lit) ...[
                  const SizedBox(height: 20),
                  AppFieldLabel(strings.photoLabel),
                  const SizedBox(height: 6),
                  PhotoPicker(
                    photoPath: _photoPath,
                    onPick: _pickPhoto,
                    onRemove: _removePhoto,
                  ),
                ],
                if (_kind == StarKind.pulsar) ...[
                  const SizedBox(height: 20),
                  AppFieldLabel(strings.habitFrequencyLabel),
                  const SizedBox(height: 6),
                  // Fixed to daily in v1, so it's shown as a filled field
                  // rather than a picker — it already holds its answer.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: fieldDecoration(colors, FieldState.filled),
                    child: Row(
                      children: [
                        Icon(Icons.repeat, size: 20, color: colors.gold),
                        const SizedBox(width: 10),
                        Text(
                          strings.habitFrequencyDaily,
                          style: TextStyle(
                            color: colors.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(kRadiusCard),
                    child: Container(
                      decoration: panelDecoration(colors),
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: _customReminder,
                            onChanged: (value) =>
                                setState(() => _customReminder = value),
                            title: Text(
                              strings.customReminderToggleLabel,
                              style: TextStyle(
                                color: colors.text,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (_customReminder)
                            ListTile(
                              onTap: _pickReminderTime,
                              title: Text(
                                strings.reminderTimeLabel,
                                style: TextStyle(
                                  color: colors.muted,
                                  fontSize: 13,
                                ),
                              ),
                              trailing: Text(
                                TimeOfDay(
                                  hour: _reminderHour,
                                  minute: _reminderMinute,
                                ).format(context),
                                style: TextStyle(
                                  color: colors.gold,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      if (widget.isEditing && !widget.hideDelete)
                        PillActionButton(
                          icon: Icons.delete_outline,
                          label: strings.deleteStarAction,
                          onTap: _confirmAndDelete,
                          danger: true,
                        ),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _titleController,
                        builder: (context, value, child) {
                          final canSave =
                              value.text.trim().isNotEmpty &&
                              _selectedProject != null &&
                              (!widget.isEditing || _hasUnsavedChanges);
                          return SaveActionButton(
                            label: widget.isEditing
                                ? strings.saveChanges
                                : (_kind == StarKind.lit
                                      ? strings.lightThisStar
                                      : strings.placeThisStarAction),
                            lit: canSave,
                            onPressed: canSave
                                ? _save
                                : _showCannotSaveMessage,
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

/// The kind switch at the top of the form — one card per available kind,
/// each showing that kind the way the sky shows it ([StarGlyph]) above its
/// name and what it means. Deliberately not a `SegmentedButton`: the whole
/// point is that the three kinds are three *different things in time*
/// (past, present, future), which needs more than three words in a row to
/// land.
class _StarKindSwitch extends StatelessWidget {
  const _StarKindSwitch({
    required this.kinds,
    required this.selected,
    required this.onChanged,
  });

  final List<StarKind> kinds;
  final StarKind selected;
  final ValueChanged<StarKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return Row(
      children: [
        for (var i = 0; i < kinds.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () => onChanged(kinds[i]),
              borderRadius: BorderRadius.circular(kRadiusField),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: flatSelectableDecoration(
                  colors,
                  selected: kinds[i] == selected,
                ),
                child: Column(
                  children: [
                    StarGlyph(kind: kinds[i], size: 22),
                    const SizedBox(height: 4),
                    Text(
                      kinds[i].label(strings),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: kinds[i] == selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: kinds[i] == selected
                            ? colors.text
                            : colors.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kinds[i].meaning(strings),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: colors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The static stand-in for [_StarKindSwitch] when there's only one possible
/// kind — the same glyph, name and meaning, minus the pretense of a choice.
class _StarKindMeaning extends StatelessWidget {
  const _StarKindMeaning({required this.kind, this.showGlyph = false});

  final StarKind kind;
  final bool showGlyph;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showGlyph) ...[
          StarGlyph(kind: kind, size: 22),
          const SizedBox(width: 6),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              kind.label(strings),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            Text(
              kind.meaning(strings),
              style: TextStyle(fontSize: 12, color: colors.muted),
            ),
          ],
        ),
      ],
    );
  }
}
