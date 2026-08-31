import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/habit_completion_repository.dart';
import 'data/habit_repository.dart';
import 'data/project_repository.dart';
import 'data/star_repository.dart';
import 'l10n/strings_scope.dart';
import 'notifications/reminder_service.dart';
import 'screens/add_star_screen.dart';
import 'screens/root_screen.dart';
import 'settings/settings_controller.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const VictoryStarsApp());
}

class VictoryStarsApp extends StatefulWidget {
  const VictoryStarsApp({super.key});

  @override
  State<VictoryStarsApp> createState() => _VictoryStarsAppState();
}

class _VictoryStarsAppState extends State<VictoryStarsApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  SettingsController? _settings;
  StarRepository? _starRepository;
  ProjectRepository? _projectRepository;
  HabitRepository? _habitRepository;
  HabitCompletionRepository? _habitCompletionRepository;
  ReminderService? _reminderService;

  /// Set only if [_load] throws. A blank splash that silently never
  /// finishes loading (see [build]) is indistinguishable from a hang — this
  /// at least surfaces what broke, directly on screen, without needing a
  /// debugger or logcat attached.
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await SettingsController.create();
      settings.addListener(() => setState(() {}));
      final starRepository = await StarRepository.create();
      final projectRepository = await ProjectRepository.create();
      final habitRepository = await HabitRepository.create();
      final habitCompletionRepository =
          await HabitCompletionRepository.create();
      // Wired here (not per-screen) since a second `initialize()` call from
      // another ReminderService instance would silently steal this tap
      // callback out from under the app-level navigation handler.
      final reminderService = await ReminderService.create(
        onNotificationTap: (_) => _openAddStarFromNotification(),
      );

      // scheduleUpcoming only ever arms the next few days (see its own doc
      // comment) — without topping it up again here on every launch, a
      // reminder that was enabled once would silently stop firing for
      // anyone who doesn't happen to revisit the Settings screen.
      if (settings.reminderEnabled) {
        final strings = stringsForLocale(settings.locale);
        await reminderService.scheduleUpcoming(
          hour: settings.reminderHour,
          minute: settings.reminderMinute,
          title: strings.reminderNotificationTitle,
          bodies: strings.reminderNotificationBodies,
        );
      }

      setState(() {
        _settings = settings;
        _starRepository = starRepository;
        _projectRepository = projectRepository;
        _habitRepository = habitRepository;
        _habitCompletionRepository = habitCompletionRepository;
        _reminderService = reminderService;
      });

      if (await reminderService.launchedFromNotification()) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _openAddStarFromNotification(),
        );
      }
    } catch (error) {
      setState(() => _loadError = error);
    }
  }

  Future<void> _openAddStarFromNotification() async {
    final starRepository = _starRepository;
    final projectRepository = _projectRepository;
    final navigator = _navigatorKey.currentState;
    if (starRepository == null ||
        projectRepository == null ||
        navigator == null)
      return;

    final result = await navigator.push<AddStarResult>(
      MaterialPageRoute(
        builder: (_) => AddStarScreen(projectRepository: projectRepository),
      ),
    );
    if (result == null) return;

    await starRepository.add(
      title: result.title,
      description: result.description,
      projectId: result.projectId,
      targetDate: result.targetDate,
      achievedDate: result.achievedDate,
      intensity: result.intensity,
      photoPath: result.photoPath,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    final starRepository = _starRepository;
    final projectRepository = _projectRepository;
    final habitRepository = _habitRepository;
    final habitCompletionRepository = _habitCompletionRepository;
    final reminderService = _reminderService;
    final loadError = _loadError;
    if (loadError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ColoredBox(
          color: const Color(0xFF0D1220),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  '$loadError',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (settings == null ||
        starRepository == null ||
        projectRepository == null ||
        habitRepository == null ||
        habitCompletionRepository == null ||
        reminderService == null) {
      // Nothing is known yet — a neutral, static splash rather than
      // guessing defaults that might flash-swap once everything loads.
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ColoredBox(color: Color(0xFF0D1220)),
      );
    }

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Victory Stars',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: settings.themeMode,
      locale: Locale(settings.locale),
      supportedLocales: const [Locale('en'), Locale('it'), Locale('ro')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => StringsScope(
        strings: stringsForLocale(settings.locale),
        child: child!,
      ),
      home: RootScreen(
        settings: settings,
        starRepository: starRepository,
        projectRepository: projectRepository,
        habitRepository: habitRepository,
        habitCompletionRepository: habitCompletionRepository,
        reminderService: reminderService,
      ),
    );
  }
}
