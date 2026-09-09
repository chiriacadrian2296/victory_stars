import 'package:flutter/material.dart';

import '../l10n/strings_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../theme/app_style.dart';

/// The Sky's side menu — the app's only navigation. There's exactly one
/// screen now (the Sky itself); everything else opens from here as a page
/// on top of it, so the sky is never something you have to come *back* to.
///
/// A thin [Drawer] wrapper around [SkyMenuContent] in its default, compact
/// mode — split apart so the exact same content can also open as a modal
/// sheet (see `SkyScreen`'s own star-FAB, an alternative entry point being
/// tried alongside this one) in its bigger, more detailed mode, without
/// duplicating a single entry.
class SkyMenuDrawer extends StatelessWidget {
  const SkyMenuDrawer({
    super.key,
    required this.onLightAStar,
    required this.onNewConstellation,
    required this.onVisions,
    required this.onShootingStars,
    required this.onAdmire,
    required this.onSearch,
    required this.onStatistics,
    required this.onFriends,
    required this.onMetaphor,
    required this.onSettings,
  });

  final VoidCallback onLightAStar;
  final VoidCallback onNewConstellation;
  final VoidCallback onVisions;
  final VoidCallback onShootingStars;
  final VoidCallback onAdmire;
  final VoidCallback onSearch;
  final VoidCallback onStatistics;
  final VoidCallback onFriends;
  final VoidCallback onMetaphor;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: SkyMenuContent(
          onLightAStar: onLightAStar,
          onNewConstellation: onNewConstellation,
          onVisions: onVisions,
          onShootingStars: onShootingStars,
          onAdmire: onAdmire,
          onSearch: onSearch,
          onStatistics: onStatistics,
          onFriends: onFriends,
          onMetaphor: onMetaphor,
          onSettings: onSettings,
        ),
      ),
    );
  }
}

/// The menu's actual content: the logo/tagline header, then every entry,
/// grouped into sections. Used two ways — inside [SkyMenuDrawer]'s
/// [Drawer] (unbounded height, scrolls the whole thing if it ever needs
/// to) and inside a [showModalBottomSheet] (bounded height, passed in by
/// the caller) — so this widget itself makes no assumption about which;
/// it just fills whatever height it's given, scrollable list on top,
/// Settings pinned below.
///
/// [detailed] (off by default, so the drawer stays exactly as tuned) is
/// the modal's own look: a bigger header, section titles brought back
/// (centered, under the now-bigger header — [detailed] centers this
/// whole thing more deliberately than the compact mode ever tried to),
/// and a one-line caption under every entry. The compact mode (the
/// drawer) skips all of that — with 6 sections and up to 3 entries each,
/// section labels alone cost it its "everything visible without
/// scrolling" fit on a typical phone, which mattered there and doesn't
/// in a scrollable modal.
///
/// Every entry reads the same way — a gold icon beside white text. There's
/// no second, dimmer tier any more: a muted vs. bright split within
/// entries. (Emoji leads were tried for the two "make something" entries,
/// but an emoji glyph carries its own baked-in color that can't be
/// retinted to the app's exact gold — next to a true gold [Icon] it read
/// as a mismatched, slightly-off yellow rather than the same color, so
/// every entry uses a plain [Icon] now.)
///
/// What each group is:
/// - **Activity** — the things you *make*: [onLightAStar]/[onNewConstellation]
///   sit behind one entry ("Light Your Sky") that opens a small chooser
///   rather than claiming two rows, [onVisions] ("Imagine Your Dreams"),
///   and [onShootingStars] — sketched in ahead of the feature existing.
/// - **Crisis** — [onAdmire] ("Find Your Light"), right under Activity: what
///   it's *for* (a place to go when things are hard, reached in as few taps
///   as making something) matters more here than it being its own category.
/// - **Data** — ways of *looking back*: search and the statistics page.
/// - **Social** — [onFriends], sketched in the same way as Shooting Stars.
/// - **Info** — just the metaphor guide. Onboarding replay moved back to
///   Settings' debug tools (a dev aid, not something worth its own
///   first-class entry); the app's own about card lives there too — it's
///   a fact about the app, not a place to go.
/// - **Settings** — its own section like every other, last: the page
///   behind it has its own sections in turn.
class SkyMenuContent extends StatelessWidget {
  const SkyMenuContent({
    super.key,
    required this.onLightAStar,
    required this.onNewConstellation,
    required this.onVisions,
    required this.onShootingStars,
    required this.onAdmire,
    required this.onSearch,
    required this.onStatistics,
    required this.onFriends,
    required this.onMetaphor,
    required this.onSettings,
    this.detailed = false,
  });

  final VoidCallback onLightAStar;
  final VoidCallback onNewConstellation;
  final VoidCallback onVisions;
  final VoidCallback onShootingStars;
  final VoidCallback onAdmire;
  final VoidCallback onSearch;
  final VoidCallback onStatistics;
  final VoidCallback onFriends;
  final VoidCallback onMetaphor;
  final VoidCallback onSettings;

  /// See the class doc comment — off for the drawer, on for the modal.
  final bool detailed;

  // The same disc icon already used as the phone's app icon (the ring +
  // star mark, pre-composited over the app's night background).
  static const _logoAsset = 'assets/icon/app_icon_ring_centered.png';

  /// "Light Your Sky" covers both of the app's two creation flows, so
  /// tapping it offers the choice rather than picking one — a small sheet
  /// in the same [colors.nightPanel]/gold language as every other sheet in
  /// the app, not a full screen of its own.
  void _openLightYourSkyChooser(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        Widget choice({
          required IconData icon,
          required String label,
          required VoidCallback onTap,
        }) {
          return ListTile(
            leading: Icon(icon, color: colors.gold),
            title: Text(
              label,
              style: TextStyle(
                color: colors.text,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              Navigator.of(dialogContext).pop();
              onTap();
            },
          );
        }

        // A popup rather than a sheet, per request — [Dialog] alone (not
        // [AlertDialog]) since the content here is a pair of ListTiles,
        // not a title/actions layout; it still picks up the app's own
        // dialog theme (background, shape) automatically.
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      strings.lightYourSkyChooserTitle,
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                choice(
                  icon: Icons.star,
                  label: strings.menuLightAStar,
                  onTap: onLightAStar,
                ),
                choice(
                  icon: Icons.auto_awesome,
                  label: strings.menuNewConstellation,
                  onTap: onNewConstellation,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    // A section title, centered under the header the same way the header
    // itself is — only rendered in [detailed] mode.
    Widget sectionHeader(String label) {
      if (!detailed) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.left,
          style: TextStyle(
            color: colors.text,
            fontSize: 12,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    // Every entry is a gold icon beside plain white text. No muted/bright
    // split any more, and no glow beyond what [Icon]/[Text] draw on their
    // own — a divider is what separates one group from the next. In
    // [detailed] mode, [description] adds a one-line caption underneath.
    Widget entry({
      required IconData icon,
      required String label,
      String? description,
      required VoidCallback onTap,
    }) {
      final tile = ListTile(
        leading: Icon(icon, color: colors.gold),
        title: Text(
          label,
          style: TextStyle(
            color: colors.text,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: detailed && description != null
            ? Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  description,
                  style: TextStyle(color: colors.muted, fontSize: 12.5),
                ),
              )
            : null,
        onTap: () {
          // Closed here rather than by each caller, so no action can leave
          // the menu open behind the page it just pushed — works whether
          // this content is inside the Drawer or a modal bottom sheet,
          // since both dismiss via the same Navigator.pop.
          Navigator.of(context).pop();
          onTap();
        },
      );
      // [detailed] mode only: the same panel language every field/tile in
      // the app uses (see `panelDecoration`), so each row reads as its
      // own pressable button rather than a plain line in a list — the
      // compact drawer skips this on purpose, it was never ambiguous
      // there.
      if (!detailed) return tile;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Container(
          decoration: panelDecoration(colors),
          clipBehavior: Clip.antiAlias,
          child: tile,
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  children: [
                    ClipOval(
                      child: Image.asset(_logoAsset, width: 72, height: 72),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Victory Stars',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.text,
                        fontFamily: kFontBranding,
                        fontSize: detailed ? 46 : 34,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.aboutTagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: detailed ? 18 : 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (!detailed) Divider(color: colors.nightBorder, height: 1),
              sectionHeader(strings.menuActivitySection),
              if (!detailed) const SizedBox(height: 8),
              entry(
                icon: Icons.auto_awesome,
                label: strings.menuLightYourSky,
                description: strings.menuLightYourSkyDescription,
                onTap: () {
                  // Reopening on the next frame: the menu's own
                  // Navigator.pop (in entry()'s onTap) has to finish
                  // closing it first, or the sheet opens behind the
                  // closing menu instead of on top of the Sky.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _openLightYourSkyChooser(context);
                  });
                },
              ),
              entry(
                icon: Icons.flare,
                label: strings.menuImagineYourDreams,
                description: strings.menuImagineYourDreamsDescription,
                onTap: onVisions,
              ),
              entry(
                icon: Icons.auto_fix_high,
                label: strings.menuShootingStars,
                description: strings.menuShootingStarsDescription,
                onTap: onShootingStars,
              ),

              if (!detailed) Divider(color: colors.nightBorder, height: 1),
              sectionHeader(strings.menuCrisisSection),
              if (!detailed) const SizedBox(height: 8),
              entry(
                icon: Icons.tips_and_updates,
                label: strings.menuFindYourLight,
                description: strings.menuFindYourLightDescription,
                onTap: onAdmire,
              ),

              if (!detailed) Divider(color: colors.nightBorder, height: 1),
              sectionHeader(strings.menuDataSection),
              if (!detailed) const SizedBox(height: 8),
              entry(
                icon: Icons.saved_search,
                label: strings.menuSearch,
                description: strings.menuSearchDescription,
                onTap: onSearch,
              ),
              entry(
                icon: Icons.bar_chart_outlined,
                label: strings.menuStatistics,
                description: strings.menuStatisticsDescription,
                onTap: onStatistics,
              ),

              if (!detailed) Divider(color: colors.nightBorder, height: 1),
              sectionHeader(strings.socialSection),
              if (!detailed) const SizedBox(height: 8),
              entry(
                icon: Icons.people,
                label: strings.menuFriends,
                description: strings.menuFriendsDescription,
                onTap: onFriends,
              ),

              if (!detailed) Divider(color: colors.nightBorder, height: 1),
              sectionHeader(strings.menuInfoSection),
              if (!detailed) const SizedBox(height: 8),
              entry(
                icon: Icons.auto_stories_outlined,
                label: strings.menuMetaphor,
                description: strings.menuMetaphorDescription,
                onTap: onMetaphor,
              ),

              // In [detailed] mode (the modal), Settings is just one more
              // section in the same scrollable list as everything else —
              // it only gets pulled out and pinned below in compact mode
              // (the drawer); see the non-detailed branch further down.
              if (detailed) ...[
                sectionHeader(strings.menuSettings),
                entry(
                  icon: Icons.settings_outlined,
                  label: strings.menuSettings,
                  description: strings.menuSettingsDescription,
                  onTap: onSettings,
                ),
              ],
            ],
          ),
        ),
        // Compact mode only: Settings sits outside the scrollable list
        // entirely, not just last within it — its own divider plus the
        // gap above and below reads as "a different kind of thing" (the
        // page that has its *own* sections) rather than one more row in
        // the same list. Skipped in [detailed] mode, where it's already
        // inside the list above like every other section.
        if (!detailed) ...[
          Divider(color: colors.nightBorder, height: 1),
          entry(
            icon: Icons.settings_outlined,
            label: strings.menuSettings,
            description: strings.menuSettingsDescription,
            onTap: onSettings,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
