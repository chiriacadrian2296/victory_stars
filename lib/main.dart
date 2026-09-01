import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/custom_constellation_repository.dart';
import 'data/habit_completion_repository.dart';
import 'data/habit_repository.dart';
import 'data/legacy_constellation_migration.dart';
import 'data/project_repository.dart';
import 'data/star_repository.dart';
import 'l10n/strings_scope.dart';
import 'notifications/reminder_service.dart';
import 'screens/add_star_screen.dart';
import 'screens/root_screen.dart';
import 'settings/settings_controller.dart';
import 'theme/app_theme.dart';

void main() {
  // Explicit opt-in to edge-to-edge (mandatory on Android 15+ regardless):
  // without it, the system nav/status bars are drawn as their own opaque
  // strip rather than transparent overlays on top of the app, so the
  // SystemUiOverlayStyle colors set below have nothing to actually show —
  // Android just paints its own default (white) behind them instead.
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
  CustomConstellationRepository? _customConstellationRepository;
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
      final customConstellationRepository =
          await CustomConstellationRepository.create();
      // Idempotent — safe (and cheap once everything's migrated) to run on
      // every launch. Must finish before setState reveals the app below, so
      // every Project any screen reads already has its customConstellationId.
      await backfillMissingConstellations(
        projectRepository: projectRepository,
        customConstellationRepository: customConstellationRepository,
      );
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
        _customConstellationRepository = customConstellationRepository;
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
    final customConstellationRepository = _customConstellationRepository;
    final navigator = _navigatorKey.currentState;
    if (starRepository == null ||
        projectRepository == null ||
        customConstellationRepository == null ||
        navigator == null) {
      return;
    }

    final result = await navigator.push<AddStarResult>(
      MaterialPageRoute(
        builder: (_) => AddStarScreen(
          projectRepository: projectRepository,
          customConstellationRepository: customConstellationRepository,
        ),
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
    final customConstellationRepository = _customConstellationRepository;
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
        customConstellationRepository == null ||
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
      home: Builder(
        // A Builder (not this method's own context) so Theme.of below
        // actually resolves — MaterialApp.home is built inside the Theme
        // it sets up, but the `context` MaterialApp.build itself runs in
        // is not.
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            // Android draws its own status/navigation bars over the app by
            // default with a plain white background regardless of the
            // app's theme — without this, the back/home/recents bar (and
            // the status bar) stay white in both light and dark mode.
            // Fully transparent (not colors.night) rather than an explicit
            // opaque color: Android 15+ ignores an app-requested
            // systemNavigationBarColor outright under mandatory
            // edge-to-edge, so the only reliable way to get a dark bar
            // there is to make it transparent and let the app's own
            // (already-dark) Scaffold background — which edge-to-edge
            // extends behind the bar automatically — show through.
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
              statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
              systemNavigationBarDividerColor: Colors.transparent,
              systemNavigationBarContrastEnforced: false,
            ),
            child: RootScreen(
              settings: settings,
              starRepository: starRepository,
              projectRepository: projectRepository,
              habitRepository: habitRepository,
              habitCompletionRepository: habitCompletionRepository,
              customConstellationRepository: customConstellationRepository,
              reminderService: reminderService,
            ),
          );
        },
      ),
    );
  }
}
