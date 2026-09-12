import 'package:flutter/material.dart';

import '../l10n/strings_scope.dart';
import '../models/life_area.dart';
import '../theme/app_colors.dart';
import '../theme/app_style.dart';
import '../utils/icon_for_slug.dart';
import 'sky_tooltip_header.dart';

/// The content shown inside the `tooltip_card` popup after tapping a
/// supernova — new, same as [SkyConstellationTooltip]: tapping a supernova
/// used to only fly the camera there with nothing else shown.
///
/// Purely presentational, same shape as its sibling tooltips — [onView] is
/// the only action, opening the area's own full `AreaDetailScreen`.
class SkyAreaTooltip extends StatelessWidget {
  const SkyAreaTooltip({
    super.key,
    required this.area,
    required this.starCount,
    required this.onClose,
    required this.onView,
  });

  final LifeArea area;

  /// Every achieved victory across every project in [area] — see
  /// `starsInArea`, the same count the Supernova detail screen's own stat
  /// row uses.
  final int starCount;

  final VoidCallback onClose;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return Column(
      mainAxisSize: MainAxisSize.min,
      // See [SkyStarTooltip]'s own doc comment on its Column for why
      // `stretch` — same reasoning, so the star-count line below
      // actually gets the full width it needs to center itself within.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SkyTooltipHeader(
          icon: iconForSlug(area.iconSlug),
          iconColor: colors.gold,
          title: area.displayName(strings),
          titleColor: colors.text,
          onClose: onClose,
        ),
        const SizedBox(height: 8),
        Text(
          strings.areaTooltipStarCount(starCount),
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Material(
          color: colors.night,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusField),
            side: BorderSide(color: colors.nightBorder),
          ),
          child: InkWell(
            onTap: onView,
            borderRadius: BorderRadius.circular(kRadiusField),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.visibility_outlined, color: colors.gold, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    strings.starQuickLookViewAction,
                    style: TextStyle(
                      color: colors.gold,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
