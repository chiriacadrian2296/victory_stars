import 'package:flutter/material.dart';

import '../l10n/strings_scope.dart';
import '../theme/app_colors.dart';

/// The Sky's side menu — the app's only navigation. There's exactly one
/// screen now (the Sky itself); everything else opens from here as a page
/// on top of it, so the sky is never something you have to come *back* to.
///
/// Three things you can do, in the order the metaphor runs from small to
/// large: light a star (one effort), draw a constellation (one project),
/// and revisit your visions (one life area each). Search and Admire sit
/// below as ways of *looking* rather than making, and Settings closes it
/// out.
class SkyMenuDrawer extends StatelessWidget {
  const SkyMenuDrawer({
    super.key,
    required this.onLightAStar,
    required this.onNewConstellation,
    required this.onVisions,
    required this.onSearch,
    required this.onAdmire,
    required this.onSettings,
  });

  final VoidCallback onLightAStar;
  final VoidCallback onNewConstellation;
  final VoidCallback onVisions;
  final VoidCallback onSearch;
  final VoidCallback onAdmire;
  final VoidCallback onSettings;

  // The same disc icon already used as the phone's app icon (the ring +
  // star mark, pre-composited over the app's night background).
  static const _logoAsset = 'assets/icon/app_icon_ring_centered.png';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    Widget entry({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      bool primary = false,
    }) {
      return ListTile(
        leading: Icon(icon, color: primary ? colors.gold : colors.muted),
        title: Text(
          label,
          style: TextStyle(
            color: primary ? colors.text : colors.muted,
            fontSize: 15,
            fontWeight: primary ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onTap: () {
          // Closed here rather than by each caller, so no action can leave
          // the drawer open behind the page it just pushed.
          Navigator.of(context).pop();
          onTap();
        },
      );
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                children: [
                  ClipOval(
                    child: Image.asset(_logoAsset, width: 56, height: 56),
                  ),
                  const SizedBox(height: 12),
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
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: colors.nightBorder, height: 1),
            const SizedBox(height: 6),
            // The three things you can actually *make*, highlighted in gold
            // so they read as the menu's purpose rather than as items in a
            // list of six.
            entry(
              icon: Icons.star,
              label: strings.menuLightAStar,
              onTap: onLightAStar,
              primary: true,
            ),
            entry(
              icon: Icons.auto_awesome,
              label: strings.menuNewConstellation,
              onTap: onNewConstellation,
              primary: true,
            ),
            entry(
              icon: Icons.flare,
              label: strings.menuVisions,
              onTap: onVisions,
              primary: true,
            ),
            const SizedBox(height: 6),
            Divider(color: colors.nightBorder, height: 1),
            const SizedBox(height: 6),
            entry(
              icon: Icons.search,
              label: strings.menuSearch,
              onTap: onSearch,
            ),
            entry(
              icon: Icons.auto_stories_outlined,
              label: strings.menuAdmire,
              onTap: onAdmire,
            ),
            entry(
              icon: Icons.settings_outlined,
              label: strings.menuSettings,
              onTap: onSettings,
            ),
          ],
        ),
      ),
    );
  }
}
