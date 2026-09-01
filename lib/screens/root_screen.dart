import 'package:flutter/material.dart';

import '../data/custom_constellation_repository.dart';
import '../data/habit_completion_repository.dart';
import '../data/habit_repository.dart';
import '../data/project_repository.dart';
import '../data/star_repository.dart';
import '../l10n/strings_scope.dart';
import '../notifications/reminder_service.dart';
import '../settings/settings_controller.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'sky_screen.dart';

/// The app's root scaffold: a bottom nav bar switching between the
/// dashboard (Home), the life-areas hub (Sky — constellations and the flat
/// searchable star list live together there now, switched per-area), and
/// app Settings. Repositories and the reminder service are owned by the
/// app root (see `main.dart`) and just threaded through here.
class RootScreen extends StatefulWidget {
  const RootScreen({
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
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: [
          HomeScreen(
            starRepository: widget.starRepository,
            projectRepository: widget.projectRepository,
            habitRepository: widget.habitRepository,
            habitCompletionRepository: widget.habitCompletionRepository,
            customConstellationRepository: widget.customConstellationRepository,
          ),
          SkyScreen(
            projectRepository: widget.projectRepository,
            starRepository: widget.starRepository,
            habitRepository: widget.habitRepository,
            habitCompletionRepository: widget.habitCompletionRepository,
            customConstellationRepository: widget.customConstellationRepository,
          ),
          SettingsScreen(
            settings: widget.settings,
            starRepository: widget.starRepository,
            projectRepository: widget.projectRepository,
            habitRepository: widget.habitRepository,
            habitCompletionRepository: widget.habitCompletionRepository,
            customConstellationRepository: widget.customConstellationRepository,
            reminderService: widget.reminderService,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        backgroundColor: colors.nightPanel,
        indicatorColor: colors.gold.withValues(alpha: 0.16),
        surfaceTintColor: Colors.transparent,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.insights_outlined, color: colors.muted),
            selectedIcon: Icon(Icons.insights, color: colors.gold),
            label: strings.navHome,
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined, color: colors.muted),
            selectedIcon: Icon(Icons.explore, color: colors.gold),
            label: strings.navSky,
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: colors.muted),
            selectedIcon: Icon(Icons.settings, color: colors.gold),
            label: strings.navSettings,
          ),
        ],
      ),
    );
  }
}
