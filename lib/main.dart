import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/project_repository.dart';
import 'data/win_repository.dart';
import 'l10n/strings_scope.dart';
import 'notifications/reminder_service.dart';
import 'screens/add_win_screen.dart';
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
  WinRepository? _winRepository;
  ProjectRepository? _projectRepository;
  ReminderService? _reminderService;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await SettingsController.create();
    settings.addListener(() => setState(() {}));
    final winRepository = await WinRepository.create();
    final projectRepository = await ProjectRepository.create();
    // Wired here (not per-screen) since a second `initialize()` call from
    // another ReminderService instance would silently steal this tap
    // callback out from under the app-level navigation handler.
    final reminderService = await ReminderService.create(
      onNotificationTap: (_) => _openAddWinFromNotification(),
    );

    setState(() {
      _settings = settings;
      _winRepository = winRepository;
      _projectRepository = projectRepository;
      _reminderService = reminderService;
    });

    if (await reminderService.launchedFromNotification()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openAddWinFromNotification());
    }
  }

  Future<void> _openAddWinFromNotification() async {
    final winRepository = _winRepository;
    final projectRepository = _projectRepository;
    final navigator = _navigatorKey.currentState;
    if (winRepository == null || projectRepository == null || navigator == null) return;

    final result = await navigator.push<AddWinResult>(
      MaterialPageRoute(builder: (_) => AddWinScreen(projectRepository: projectRepository)),
    );
    if (result == null) return;

    await winRepository.add(
      title: result.title,
      description: result.description,
      projectId: result.projectId,
      intensity: result.intensity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    final winRepository = _winRepository;
    final projectRepository = _projectRepository;
    final reminderService = _reminderService;
    if (settings == null || winRepository == null || projectRepository == null || reminderService == null) {
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
        winRepository: winRepository,
        projectRepository: projectRepository,
        reminderService: reminderService,
      ),
    );
  }
}
