import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../l10n/strings_scope.dart';
import '../models/project.dart';
import '../models/star.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../theme/app_style.dart';
import '../utils/date_format.dart';
import 'area_tag.dart';
import 'intensity_bolts.dart';
import 'project_tag.dart';
import 'sky_tooltip_header.dart';
import 'star_created_at.dart';
import 'star_extra_badge.dart';

/// The content shown inside the `tooltip_card` popup after tapping a star —
/// replaces the old `StarQuickLookPanel` bottom sheet (never actually
/// shipped: see `SkyScreen`'s history). Just the inner content now, not its
/// own panel — the tooltip package already draws the surrounding
/// background/border/beak (see `SkyScreen._buildSkyTooltip`), styled to
/// match it rather than nesting a second one inside.
///
/// Purely presentational — every button just calls back up to `SkyScreen`,
/// which owns the actual repository calls, navigation, and camera state
/// this widget doesn't know about. [onShare]/[onDelete] only ever appear
/// when the action they trigger already has a real destination in the app.
class SkyStarTooltip extends StatelessWidget {
  const SkyStarTooltip({
    super.key,
    required this.star,
    required this.project,
    required this.onClose,
    required this.onView,
    required this.onEdit,
    this.onShare,
    this.onDelete,
  });

  final Star star;
  final Project? project;
  final VoidCallback onClose;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  /// The one fact unique to this star's own kind — same three-way split
  /// [LitStarCard]/[UnlitStarCard]/[DeadStarCard] each show in their own
  /// "extra badge" slot, reused here verbatim so this tooltip tells the
  /// same story in the same order the search section's own cards do: a
  /// lit star's photo (there's no separate "achieved date" badge on that
  /// card either — [StarCreatedAt] below is as close as it gets), an
  /// unlit star's target date, a dead star's own death date.
  Widget _extraBadge(AppStrings strings) {
    if (star.dead) {
      return StarExtraBadge(
        icon: Icons.church,
        label: star.deadDate == null
            ? strings.noDeadDateLabel
            : strings.deadDateBadgeLabel,
        value: star.deadDate == null
            ? null
            : formatDisplayDate(star.deadDate!, strings),
        dimmed: star.deadDate == null,
      );
    }
    if (star.isLit) {
      return StarExtraBadge(
        icon: Icons.photo_camera,
        label: star.photoPath == null
            ? strings.noPhotoLabel
            : strings.photoBadgeLabel,
        dimmed: star.photoPath == null,
      );
    }
    return StarExtraBadge(
      icon: Icons.event_outlined,
      label: star.targetDate == null
          ? strings.noTargetDateLabel
          : strings.targetDateBadgeLabel,
      value: star.targetDate == null
          ? null
          : formatDisplayDate(star.targetDate!, strings),
      dimmed: star.targetDate == null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return Column(
      mainAxisSize: MainAxisSize.min,
      // Stretch, not the Column default start/center — every row below
      // centers *itself* (a [Center], or a widget that already centers
      // its own content, like [StarExtraBadge]/[StarCreatedAt]), which
      // only actually reads as centered if it's handed the tooltip's
      // full width to center within, the same reasoning the cards'
      // own `CrossAxisAlignment.stretch` already relies on. Two tags on
      // the same row still land as one centered *group*, not each tag
      // centered on its own — the [Center] wraps the whole [Wrap], not
      // each child of it.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SkyTooltipHeader(
          icon: Icons.star,
          iconColor: colors.gold,
          iconSize: 20,
          title: star.title,
          // Dimmed to match [DeadStarCard]'s own title treatment — every
          // other kind keeps the full-brightness [colors.text] the card
          // itself uses.
          titleColor: star.dead ? colors.muted : colors.text,
          titleFontSize: 18,
          // Same [kFontStarTitle] (Newsreader) italic every star's own
          // title uses on its card — the one font choice worth carrying
          // over here, so a star reads as the same star whether it's
          // met on a card or in this tooltip.
          titleFontFamily: kFontStarTitle,
          titleItalic: true,
          onClose: onClose,
        ),
        if (project != null) ...[
          const SizedBox(height: 8),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ProjectTag(
                  project: project!,
                  textColor: colors.muted,
                  iconSize: 14,
                  fontSize: 13,
                ),
                AreaTag(area: project!.area, iconSize: 14, fontSize: 13),
              ],
            ),
          ),
        ],
        if (star.description != null) ...[
          const SizedBox(height: 10),
          Text(
            star.description!,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.muted, fontSize: 14, height: 1.4),
          ),
        ],
        const SizedBox(height: 12),
        _extraBadge(strings),
        if (star.intensity != null) ...[
          const SizedBox(height: 12),
          Center(child: IntensityBolts(intensity: star.intensity!, size: 16)),
        ],
        const SizedBox(height: 12),
        StarCreatedAt(createdAt: star.createdAt),
        const SizedBox(height: 14),
        // One row, always — up to four [_TooltipAction]s sharing it
        // evenly via [Expanded] rather than each reporting a fixed width
        // and wrapping to a second line once they stop fitting. The
        // [SizedBox.width]`: double.infinity` is what makes that
        // [Expanded] split actually mean something: on its own, this
        // [Column] (and so the tooltip card wrapping it) would only ever
        // size itself to its content's own natural width, leaving
        // [Expanded] nothing to divide — this instead stretches the row
        // out to the card's own `constraints` max width (set by
        // `SkyScreen`), so each action narrows to fit rather than the row
        // dropping extras to a second line.
        SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              Expanded(
                child: _TooltipAction(
                  icon: Icons.visibility_outlined,
                  label: strings.starQuickLookViewAction,
                  color: colors.gold,
                  onTap: onView,
                ),
              ),
              if (onShare != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _TooltipAction(
                    icon: Icons.share_outlined,
                    label: strings.starQuickLookShareAction,
                    color: colors.muted,
                    onTap: onShare!,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: _TooltipAction(
                  icon: Icons.edit_outlined,
                  label: strings.starQuickLookEditAction,
                  color: colors.muted,
                  onTap: onEdit,
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _TooltipAction(
                    icon: Icons.delete_outline,
                    label: strings.deleteStarAction,
                    color: colors.danger,
                    onTap: onDelete!,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One action button in the tooltip's own bottom row — same compact
/// "icon above a short label" shape `_EditorActionButton`-adjacent tiles
/// use elsewhere, fixed-width (see [SkyStarTooltip._actionWidth]) so up
/// to four sit comfortably in a [Wrap], dropping to a second line rather
/// than squeezing/truncating if the card isn't wide enough for all of
/// them at once. No panel of its own (unlike the old quick-look panel's
/// version of this) — the tooltip card behind it already is one.
class _TooltipAction extends StatelessWidget {
  const _TooltipAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.night,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusField),
        side: BorderSide(color: colors.nightBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadiusField),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
