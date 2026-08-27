import 'package:flutter/material.dart';

import '../data/project_repository.dart';
import '../data/win_repository.dart';
import '../l10n/strings_scope.dart';
import '../settings/settings_controller.dart';
import '../theme/app_colors.dart';
import 'admire_stars_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'sky_screen.dart';
import 'stars_screen.dart';

/// The app's root scaffold: a bottom nav bar switching between the
/// dashboard (Home), the life-areas hub (Sky), the searchable win browser
/// (Stars), and app Settings. Owns both data repositories so they're
/// loaded once and shared between tabs, rather than each tab loading its
/// own copy.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key, required this.settings});

  final SettingsController settings;

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  WinRepository? _winRepository;
  ProjectRepository? _projectRepository;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final winRepository = await WinRepository.create();
    final projectRepository = await ProjectRepository.create();
    setState(() {
      _winRepository = winRepository;
      _projectRepository = projectRepository;
    });
  }

  void _openAdmireStars() {
    final winRepository = _winRepository;
    final projectRepository = _projectRepository;
    if (winRepository == null || projectRepository == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdmireStarsScreen(winRepository: winRepository, projectRepository: projectRepository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final winRepository = _winRepository;
    final projectRepository = _projectRepository;
    final ready = winRepository != null && projectRepository != null;
    final colors = context.colors;
    final strings = context.strings;

    return Scaffold(
      body: !ready
          ? Center(child: CircularProgressIndicator(color: colors.gold))
          : IndexedStack(
              index: _tabIndex,
              children: [
                HomeScreen(winRepository: winRepository, projectRepository: projectRepository),
                SkyScreen(projectRepository: projectRepository, winRepository: winRepository),
                StarsScreen(projectRepository: projectRepository, winRepository: winRepository),
                SettingsScreen(
                  settings: widget.settings,
                  winRepository: winRepository,
                  projectRepository: projectRepository,
                ),
              ],
            ),
      bottomNavigationBar: !ready
          ? null
          : NavigationBar(
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
      // navigate to a specific screen first to find.
      floatingActionButton: !ready
          ? null
          : FloatingActionButton.small(
              heroTag: 'admireStarsFab',
              onPressed: _openAdmireStars,
              backgroundColor: colors.nightPanel,
              foregroundColor: colors.gold,
              elevation: 2,
              shape: CircleBorder(side: BorderSide(color: colors.goldDim)),
              tooltip: strings.admireYourStars,
              child: const Icon(Icons.auto_awesome),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
