import 'package:flutter/material.dart';

import '../data/project_repository.dart';
import '../data/win_repository.dart';
import '../l10n/strings_scope.dart';
import '../notifications/reminder_service.dart';
import '../settings/settings_controller.dart';
import '../theme/app_colors.dart';
import 'admire_stars_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'sky_screen.dart';
import 'stars_screen.dart';

/// The app's root scaffold: a bottom nav bar switching between the
/// dashboard (Home), the life-areas hub (Sky), the searchable win browser
/// (Stars), and app Settings. Repositories and the reminder service are
/// owned by the app root (see `main.dart`) and just threaded through here.
class RootScreen extends StatefulWidget {
  const RootScreen({
    super.key,
    required this.settings,
    required this.winRepository,
    required this.projectRepository,
    required this.reminderService,
  });

  final SettingsController settings;
  final WinRepository winRepository;
  final ProjectRepository projectRepository;
  final ReminderService reminderService;

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _tabIndex = 0;

  void _openAdmireStars() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdmireStarsScreen(
          winRepository: widget.winRepository,
          projectRepository: widget.projectRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: [
          HomeScreen(winRepository: widget.winRepository, projectRepository: widget.projectRepository),
          SkyScreen(projectRepository: widget.projectRepository, winRepository: widget.winRepository),
          StarsScreen(projectRepository: widget.projectRepository, winRepository: widget.winRepository),
          SettingsScreen(
            settings: widget.settings,
            winRepository: widget.winRepository,
            projectRepository: widget.projectRepository,
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
            icon: Icon(Icons.star_border, color: colors.muted),
            selectedIcon: Icon(Icons.star, color: colors.gold),
            label: strings.navStars,
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: colors.muted),
            selectedIcon: Icon(Icons.settings, color: colors.gold),
            label: strings.navSettings,
          ),
        ],
      ),
      // Persistent across every tab — not just Home — since this is meant
      // to be reachable whenever it's needed, not something you have to
      // navigate to a specific screen first to find. Parked right above
      // Home's own add-win FAB so both sit within thumb's reach on the
      // same side, instead of opposite corners.
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'admireStarsFab',
        onPressed: _openAdmireStars,
        backgroundColor: colors.nightPanel,
        foregroundColor: colors.gold,
        elevation: 2,
        shape: CircleBorder(side: BorderSide(color: colors.goldDim)),
        tooltip: strings.admireYourStars,
        child: const Icon(Icons.auto_awesome),
      ),
      floatingActionButtonLocation: const _AboveMainFabLocation(),
    );
  }
}

/// [FloatingActionButtonLocation.endFloat], shifted up to leave room for
/// Home's own add-win FAB directly below it.
class _AboveMainFabLocation extends FloatingActionButtonLocation {
  const _AboveMainFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final standard = FloatingActionButtonLocation.endFloat.getOffset(scaffoldGeometry);
    return Offset(standard.dx, standard.dy - 64);
  }
}
