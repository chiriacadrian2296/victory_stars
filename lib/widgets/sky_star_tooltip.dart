import 'package:flutter/material.dart';

import '../l10n/strings_scope.dart';
import '../models/project.dart';
import '../models/star.dart';
import '../theme/app_colors.dart';
import '../theme/app_style.dart';
import '../utils/date_format.dart';
import 'area_tag.dart';
import 'intensity_bolts.dart';
import 'project_tag.dart';

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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    final dateLabel = star.achievedDate != null
        ? formatDisplayDateTime(star.achievedDate!, strings)
        : star.targetDate != null
        ? formatDisplayDateTime(star.targetDate!, strings)
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star, color: colors.gold, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                star.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, color: colors.muted, size: 18),
              ),
            ),
          ],
        ),
        if (project != null || dateLabel != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Wrap(
              spacing: 14,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (project != null)
                  ProjectTag(
                    project: project!,
                    textColor: colors.muted,
                    iconSize: 14,
                    fontSize: 13,
                  ),
                if (project != null)
                  AreaTag(area: project!.area, iconSize: 14, fontSize: 13),
                if (dateLabel != null)
                  Text(
                    dateLabel,
                    style: TextStyle(color: colors.muted, fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
        if (star.intensity != null) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: IntensityBolts(intensity: star.intensity!, size: 16),
          ),
        ],
        if (star.description != null) ...[
          const SizedBox(height: 12),
          Text(
            star.description!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.muted, fontSize: 14, height: 1.4),
          ),
        ],
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
