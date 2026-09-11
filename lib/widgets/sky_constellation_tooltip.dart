import 'package:flutter/material.dart';

import '../l10n/strings_scope.dart';
import '../models/project.dart';
import '../models/star.dart';
import '../theme/app_colors.dart';
import '../theme/app_style.dart';
import '../utils/icon_for_slug.dart';
import 'area_tag.dart';

/// The content shown inside the `tooltip_card` popup after tapping a
/// constellation's shape (but not one of its stars specifically, which
/// opens [SkyStarTooltip] instead) — new: tapping a constellation used to
/// only fly the camera there with nothing else shown.
///
/// Purely presentational, same as [SkyStarTooltip] — [onView] is the only
/// action, opening the project's own full `ConstellationScreen`.
class SkyConstellationTooltip extends StatelessWidget {
  const SkyConstellationTooltip({
    super.key,
    required this.project,
    required this.stars,
    required this.onClose,
    required this.onView,
  });

  final Project project;

  /// This project's own logged stars (goals/victories, not the shape's
  /// nascent slots or its pulsars) — just enough to say how many have
  /// been lit so far.
  final List<Star> stars;

  final VoidCallback onClose;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final litCount = stars.where((s) => s.isLit).length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(iconForSlug(project.iconSlug), color: colors.gold, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                project.name,
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
          child: Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AreaTag(area: project.area, iconSize: 13, fontSize: 12),
              Text(
                strings.constellationTooltipLitCount(litCount, stars.length),
                style: TextStyle(color: colors.muted, fontSize: 12),
              ),
            ],
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
    );
  }
}
