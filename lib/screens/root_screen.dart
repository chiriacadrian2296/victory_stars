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
import '../utils/responsive.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'sky_screen.dart';
import 'stats_screen.dart';

/// The app's root scaffold: switches between the dashboard (Home), the
/// life-areas hub (Sky — constellations and the flat searchable star list
/// live together there now, switched per-area), and app Settings. Below
/// [kWideLayoutBreakpoint] that's a bottom nav bar (phone chrome); at or
/// above it, a custom side rail (desktop/web chrome, see [_RailHeader] and
/// [_RailButton]) — see [isWideLayout]. Repositories and the reminder
/// service are owned by the app root (see `main.dart`) and just threaded
/// through here.
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

  /// Whether the desktop/web nav rail shows full labels ("open") or just
  /// icons ("closed") — toggled from its own header button. Not persisted;
  /// like [_tabIndex], it's fine for this to reset on a fresh launch.
  bool _railExpanded = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    final destinations = [
      (
        icon: Icons.insights_outlined,
        selected: Icons.insights,
        label: strings.navHome,
      ),
      (
        icon: Icons.explore_outlined,
        selected: Icons.explore,
        label: strings.navSky,
      ),
      (
        icon: Icons.bar_chart_outlined,
        selected: Icons.bar_chart,
        label: strings.navStats,
      ),
      (
        icon: Icons.settings_outlined,
        selected: Icons.settings,
        label: strings.navSettings,
      ),
    ];

    final tabs = IndexedStack(
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
        StatsScreen(
          starRepository: widget.starRepository,
          projectRepository: widget.projectRepository,
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
    );

    if (isWideLayout(context)) {
      return Scaffold(
        body: Row(
          children: [
            // Hand-built rather than NavigationRail's own destinations:
            // NavigationRail always anchors each destination's icon to a
            // fixed-width leading column with the label following it, not
            // centered as a unit — no public option changes that, and a
            // centered icon+label pair is what this sidebar wants.
            Container(
              width: _railExpanded ? 240 : 84,
              color: colors.nightPanel,
              child: Column(
                children: [
                  _RailHeader(
                    expanded: _railExpanded,
                    onToggle: () =>
                        setState(() => _railExpanded = !_railExpanded),
                  ),
                  for (var i = 0; i < destinations.length; i++)
                    _RailButton(
                      icon: destinations[i].icon,
                      selectedIcon: destinations[i].selected,
                      label: destinations[i].label,
                      expanded: _railExpanded,
                      selected: _tabIndex == i,
                      onTap: () => setState(() => _tabIndex = i),
                    ),
                ],
              ),
            ),
            VerticalDivider(width: 1, color: colors.nightBorder),
            Expanded(child: tabs),
          ],
        ),
      );
    }

    return Scaffold(
      body: tabs,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        backgroundColor: colors.nightPanel,
        indicatorColor: colors.gold.withValues(alpha: 0.16),
        surfaceTintColor: Colors.transparent,
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon, color: colors.muted),
              selectedIcon: Icon(d.selected, color: colors.gold),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

/// One tab button in the custom desktop sidebar — icon and (when expanded)
/// label, centered together as a single unit, with a pill-shaped highlight
/// behind the selected item.
class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.expanded,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool expanded;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final iconColor = selected ? colors.gold : colors.muted;

    final content = expanded
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? selectedIcon : icon, color: iconColor, size: 26),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? colors.text : colors.muted,
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          )
        : Center(
            child: Icon(
              selected ? selectedIcon : icon,
              color: iconColor,
              size: 26,
            ),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: selected
            ? colors.gold.withValues(alpha: 0.16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// The custom sidebar's header — the app's identity (logo, name, tagline)
/// plus the button that toggles [_RootScreenState._railExpanded]. Collapses
/// to just the toggle and a small logo when the rail itself is collapsed,
/// since the name/tagline text has nowhere to go at icon-only width.
class _RailHeader extends StatelessWidget {
  const _RailHeader({required this.expanded, required this.onToggle});

  final bool expanded;
  final VoidCallback onToggle;

  // The same disc icon already used as the phone's app icon (the ring +
  // star mark, pre-composited over the app's night background) — not the
  // square app_icon.png used for platform icon generation.
  static const _logoAsset = 'assets/icon/app_icon_ring_centered.png';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    Widget logo(double size) => ClipOval(
      child: Image.asset(_logoAsset, width: size, height: size),
    );

    final toggle = IconButton(
      onPressed: onToggle,
      iconSize: 26,
      icon: Icon(expanded ? Icons.menu_open : Icons.menu, color: colors.muted),
      tooltip: expanded
          ? strings.collapseSidebarAction
          : strings.expandSidebarAction,
    );

    if (!expanded) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(children: [toggle, const SizedBox(height: 10), logo(40)]),
      );
    }

    // A fixed width (rather than letting the Column size to its own
    // content) keeps the tagline wrapping instead of forcing the whole
    // NavigationRail wider than minExtendedWidth to fit it on one line.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: SizedBox(
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Right-aligned rather than centered with the rest of the
            // header — set apart from the logo/name/tagline stack so it
            // reads as its own control, not just another header element.
            Align(alignment: Alignment.centerRight, child: toggle),
            const SizedBox(height: 12),
            logo(56),
            const SizedBox(height: 14),
            Text(
              'Victory Stars',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.text,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              strings.aboutTagline,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.muted, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
