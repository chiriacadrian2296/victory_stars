import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/custom_constellation_repository.dart';
import '../data/habit_completion_repository.dart';
import '../data/habit_repository.dart';
import '../data/legacy_constellation_migration.dart';
import '../data/project_repository.dart';
import '../data/star_repository.dart';
import '../debug/seed_data.dart';
import '../l10n/strings_scope.dart';
import '../notifications/reminder_service.dart';
import '../settings/settings_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/responsive_content.dart';

/// The Settings tab: appearance (light/dark), language, the daily reminder
/// notification, a "Data" section (seed/reset — dev tooling that lives here
/// rather than cluttering the dashboard), and a short "about" block. Reads/
/// writes through [SettingsController], which persists each change
/// immediately.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.starRepository,
    required this.projectRepository,
    required this.habitRepository,
    required this.habitCompletionRepository,
    required this.customConstellationRepository,
    required this.reminderService,
  });

  final SettingsController settings;
  final StarRepository starRepository;
  final ProjectRepository projectRepository;
  final HabitRepository habitRepository;
  final HabitCompletionRepository habitCompletionRepository;
  final CustomConstellationRepository customConstellationRepository;
  final ReminderService reminderService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _setReminderEnabled(bool enabled) async {
    final strings = context.strings;

    if (enabled) {
      final granted = await widget.reminderService.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.notificationPermissionDenied)),
          );
        }
        return;
      }
      // Best-effort: sends the user to the system settings screen for the
      // "Alarms & reminders" permission so the reminder can fire at the
      // exact minute instead of an OS-batched approximation. There's no
      // callback for whether they actually granted it — scheduleUpcoming
      // below re-checks and adapts either way.
      await widget.reminderService.requestExactAlarmPermission();
      await widget.settings.setReminder(
        enabled: true,
        hour: widget.settings.reminderHour,
        minute: widget.settings.reminderMinute,
      );
      await widget.reminderService.scheduleUpcoming(
        hour: widget.settings.reminderHour,
        minute: widget.settings.reminderMinute,
        title: strings.reminderNotificationTitle,
        bodies: strings.reminderNotificationBodies,
      );
    } else {
      await widget.settings.setReminder(
        enabled: false,
        hour: widget.settings.reminderHour,
        minute: widget.settings.reminderMinute,
      );
      await widget.reminderService.cancel();
    }
    if (mounted) setState(() {});
  }

  Future<void> _pickReminderTime() async {
    final strings = context.strings;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: widget.settings.reminderHour,
        minute: widget.settings.reminderMinute,
      ),
    );
    if (picked == null) return;

    await widget.settings.setReminder(
      enabled: true,
      hour: picked.hour,
      minute: picked.minute,
    );
    await widget.reminderService.scheduleUpcoming(
      hour: picked.hour,
      minute: picked.minute,
      title: strings.reminderNotificationTitle,
      bodies: strings.reminderNotificationBodies,
    );
    if (mounted) setState(() {});
  }

  Future<void> _sendTestNotification() async {
    final strings = context.strings;
    final bodies = strings.reminderNotificationBodies;
    final body = bodies[DateTime.now().millisecondsSinceEpoch % bodies.length];

    // No in-app confirmation on top of the notification itself — the
    // notification appearing already is the confirmation.
    await widget.reminderService.showNow(
      title: strings.reminderNotificationTitle,
      body: body,
    );
  }

  Future<void> _seedSampleData() async {
    final strings = context.strings;
    await seedSampleData(
      starRepository: widget.starRepository,
      projectRepository: widget.projectRepository,
      habitRepository: widget.habitRepository,
      habitCompletionRepository: widget.habitCompletionRepository,
    );
    // seedSampleData still creates projects the old way (iconSlug only) —
    // this backfills them with a real constellation immediately, instead of
    // leaving them shapeless until the next app launch.
    await backfillMissingConstellations(
      projectRepository: widget.projectRepository,
      customConstellationRepository: widget.customConstellationRepository,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.seedSampleDataResult(winsPerSeedTap))),
      );
    }
  }

  Future<void> _resetAllData() async {
    final colors = context.colors;
    final strings = context.strings;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.nightPanel,
        title: Text(
          strings.resetAllDataConfirmTitle,
          style: TextStyle(color: colors.text),
        ),
        content: Text(
          strings.resetAllDataConfirmBody,
          style: TextStyle(color: colors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel, style: TextStyle(color: colors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              strings.deleteEverything,
              style: TextStyle(color: colors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await widget.starRepository.clear();
    await widget.projectRepository.clear();
    await widget.habitRepository.clear();
    await widget.habitCompletionRepository.clear();
    await widget.customConstellationRepository.clear();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.allDataCleared)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
          // The scrollable itself spans the full window width (so its
          // auto-attached Scrollbar sits at the true page edge on wide
          // viewports); only its content is capped/centered.
          children: [
            ResponsiveContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.settingsEyebrow,
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                      color: colors.goldDim,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.settingsTitle,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 28),

                  _SectionLabel(strings.appearanceSection),
                  const SizedBox(height: 10),
                  SegmentedButton<ThemeMode>(
                    style: _segmentedButtonStyle(colors),
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: const Icon(Icons.light_mode),
                        label: Text(strings.themeLight),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: const Icon(Icons.dark_mode),
                        label: Text(strings.themeDark),
                      ),
                    ],
                    selected: {widget.settings.themeMode},
                    onSelectionChanged: (selection) => setState(() {
                      widget.settings.setThemeMode(selection.first);
                    }),
                  ),
                  const SizedBox(height: 28),

                  _SectionLabel(strings.languageSection),
                  const SizedBox(height: 10),
                  SegmentedButton<String>(
                    style: _segmentedButtonStyle(colors),
                    segments: [
                      ButtonSegment(
                        value: 'en',
                        label: Text(strings.languageEnglish),
                      ),
                      ButtonSegment(
                        value: 'it',
                        label: Text(strings.languageItalian),
                      ),
                      ButtonSegment(
                        value: 'ro',
                        label: Text(strings.languageRomanian),
                      ),
                    ],
                    selected: {widget.settings.locale},
                    onSelectionChanged: (selection) => setState(() {
                      widget.settings.setLocale(selection.first);
                    }),
                  ),
                  const SizedBox(height: 28),

                  _SectionLabel(strings.reminderSection),
                  const SizedBox(height: 4),
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
                            value: widget.settings.reminderEnabled,
                            onChanged: _setReminderEnabled,
                            activeThumbColor: colors.gold,
                            title: Text(
                              strings.reminderToggleLabel,
                              style: TextStyle(
                                color: colors.text,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (widget.settings.reminderEnabled) ...[
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
                                  hour: widget.settings.reminderHour,
                                  minute: widget.settings.reminderMinute,
                                ).format(context),
                                style: TextStyle(
                                  color: colors.gold,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            ListTile(
                              onTap: _sendTestNotification,
                              title: Text(
                                strings.testNotificationButton,
                                style: TextStyle(
                                  color: colors.gold,
                                  fontSize: 13,
                                ),
                              ),
                              leading: Icon(
                                Icons.notifications_active_outlined,
                                color: colors.gold,
                                size: 20,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  _SectionLabel(strings.dataSection),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 4,
                    children: [
                      TextButton.icon(
                        onPressed: _seedSampleData,
                        icon: Icon(
                          Icons.science_outlined,
                          size: 16,
                          color: colors.muted,
                        ),
                        label: Text(
                          strings.seedSampleData,
                          style: TextStyle(color: colors.muted, fontSize: 12),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _resetAllData,
                        icon: Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: colors.danger,
                        ),
                        label: Text(
                          strings.resetAllData,
                          style: TextStyle(color: colors.danger, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  _SectionLabel(strings.aboutSection),
                  const SizedBox(height: 10),
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final version = snapshot.data?.version;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.nightPanel,
                          border: Border.all(color: colors.nightBorder),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Victory Stars',
                              style: TextStyle(
                                color: colors.text,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            if (version != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                strings.aboutVersion(version),
                                style: TextStyle(
                                  color: colors.muted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              strings.aboutTagline,
                              style: TextStyle(
                                color: colors.muted,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
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
    );
  }
}

/// Overrides Material 3's default seed-color (teal) selection styling so
/// the segmented controls stay on-brand with the app's gold accent.
ButtonStyle _segmentedButtonStyle(AppColors colors) {
  return SegmentedButton.styleFrom(
    backgroundColor: colors.nightPanel,
    foregroundColor: colors.muted,
    selectedBackgroundColor: colors.gold,
    selectedForegroundColor: colors.onGold,
    side: BorderSide(color: colors.nightBorder),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.colors.muted,
      ),
    );
  }
}
