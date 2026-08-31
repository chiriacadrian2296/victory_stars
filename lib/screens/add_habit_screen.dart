import 'package:flutter/material.dart';

import '../data/project_repository.dart';
import '../l10n/strings_scope.dart';
import '../models/habit.dart';
import '../models/project.dart';
import '../theme/app_colors.dart';
import '../widgets/area_tag.dart';
import '../widgets/project_picker.dart';
import '../widgets/project_tag.dart';

/// What the user entered, handed back to whoever pushed this screen.
class AddHabitResult {
  const AddHabitResult({
    required this.title,
    this.description,
    required this.projectId,
    this.reminderHour,
    this.reminderMinute,
  });

  final String title;
  final String? description;
  final int projectId;

  /// Both null = inherits the app's single global reminder time.
  final int? reminderHour;
  final int? reminderMinute;
}

/// Popped instead of [AddHabitResult] when editing and the user deleted the
/// habit instead of saving changes to it.
class AddHabitDeleteRequested {
  const AddHabitDeleteRequested();
}

/// Also doubles as the edit screen: pass [existingHabit] to pre-fill the
/// fields. Frequency is fixed to "every day" in v1 — shown as a read-only
/// label rather than a picker, since [HabitFrequency] has no other value
/// yet.
class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({
    super.key,
    this.existingHabit,
    this.lockedProject,
    this.projectRepository,
    this.contextProject,
  }) : assert(
         lockedProject != null || projectRepository != null,
         'Provide lockedProject (pre-scoped, no picker) or projectRepository (picker, for add or edit).',
       );

  final Habit? existingHabit;
  final Project? lockedProject;
  final ProjectRepository? projectRepository;
  final Project? contextProject;

  bool get isEditing => existingHabit != null;

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  late final _titleController = TextEditingController(
    text: widget.existingHabit?.title ?? '',
  );
  late final _descriptionController = TextEditingController(
    text: widget.existingHabit?.description ?? '',
  );
  late Project? _selectedProject =
      widget.lockedProject ?? widget.contextProject;
  late bool _customReminder = widget.existingHabit?.reminderHour != null;
  late int _reminderHour = widget.existingHabit?.reminderHour ?? 9;
  late int _reminderMinute = widget.existingHabit?.reminderMinute ?? 0;

  late final String _initialTitle = widget.existingHabit?.title ?? '';
  late final String _initialDescription =
      widget.existingHabit?.description ?? '';
  late final int? _initialProjectId =
      (widget.lockedProject ?? widget.contextProject)?.id;
  late final bool _initialCustomReminder = _customReminder;
  late final int _initialReminderHour = _reminderHour;
  late final int _initialReminderMinute = _reminderMinute;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

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
        _customReminder != _initialCustomReminder ||
        (_customReminder &&
            (_reminderHour != _initialReminderHour ||
                _reminderMinute != _initialReminderMinute));
  }

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
      title: context.strings.deleteHabitConfirmTitle,
      body: context.strings.deleteHabitConfirmBody,
      confirmLabel: context.strings.deleteHabitAction,
    );
    if (confirmed && mounted)
      Navigator.of(context).pop(const AddHabitDeleteRequested());
  }

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
      AddHabitResult(
        title: title,
        description: _descriptionController.text,
        projectId: project.id,
        reminderHour: _customReminder ? _reminderHour : null,
        reminderMinute: _customReminder ? _reminderMinute : null,
      ),
    );
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
    if (repository == null) return;
    final picked = await pickProject(context, repository);
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
                        ? strings.editHabitEyebrow
                        : strings.newHabitEyebrow,
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
              Text(
                strings.addHabitQuestion,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: colors.text,
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
                minLines: 3,
                maxLines: 5,
                style: TextStyle(color: colors.text, fontSize: 15),
                decoration: InputDecoration(hintText: strings.detailsHint),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              Text(
                strings.habitFrequencyLabel,
                style: TextStyle(fontSize: 13, color: colors.muted),
              ),
              const SizedBox(height: 6),
              Container(
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
                    Icon(Icons.repeat, size: 16, color: colors.gold),
                    const SizedBox(width: 10),
                    Text(
                      strings.habitFrequencyDaily,
                      style: TextStyle(color: colors.text, fontSize: 15),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Material(
                color: colors.nightPanel,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.nightBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _customReminder,
                        onChanged: (value) =>
                            setState(() => _customReminder = value),
                        activeThumbColor: colors.gold,
                        title: Text(
                          strings.customReminderToggleLabel,
                          style: TextStyle(color: colors.text, fontSize: 14),
                        ),
                      ),
                      if (_customReminder)
                        ListTile(
                          onTap: _pickReminderTime,
                          title: Text(
                            strings.reminderTimeLabel,
                            style: TextStyle(color: colors.muted, fontSize: 13),
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
              const SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isEditing) ...[
                      FloatingActionButton(
                        heroTag: 'deleteHabitFab',
                        onPressed: _confirmAndDelete,
                        backgroundColor: colors.danger,
                        elevation: 0,
                        shape: const CircleBorder(),
                        tooltip: strings.deleteHabitAction,
                        child: Icon(Icons.delete_outline, color: colors.night),
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
                            heroTag: 'saveHabitFab',
                            onPressed: canSave ? _save : null,
                            backgroundColor: canSave
                                ? colors.gold
                                : colors.muted,
                            elevation: 0,
                            shape: const CircleBorder(),
                            tooltip: strings.saveChanges,
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
