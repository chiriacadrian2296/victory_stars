import 'package:flutter/material.dart';

import '../l10n/strings_scope.dart';
import '../models/life_area.dart';
import '../theme/app_colors.dart';
import '../theme/app_style.dart';
import '../utils/icon_for_slug.dart';

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

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconForSlug(area.iconSlug), color: colors.gold, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  area.displayName(strings),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close, color: colors.muted, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              strings.areaTooltipStarCount(starCount),
              style: TextStyle(color: colors.muted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Material(
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
                      Icon(
                        Icons.visibility_outlined,
                        color: colors.gold,
                        size: 16,
                      ),
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
          ),
        ],
      ),
    );
  }
}
