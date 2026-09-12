import 'package:flutter/material.dart';

import '../l10n/strings_scope.dart';
import '../models/habit.dart';
import '../models/project.dart';
import '../models/star_kind.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../theme/app_style.dart';
import 'area_tag.dart';
import 'intensity_bolts.dart';
import 'project_tag.dart';
import 'sky_tooltip_header.dart';
import 'star_created_at.dart';
import 'star_extra_badge.dart';
import 'star_glyph.dart';

/// The content shown inside the `tooltip_card` popup after holding a
/// pulsar (a habit) in the sky — the same "just enough to glance at, View
/// for the rest" shape [SkyConstellationTooltip]/[SkyAreaTooltip] already
/// use, rather than [SkyStarTooltip]'s fuller inline edit/share/delete
/// row: a pulsar's own actions (edit, delete, resurrect) already live on
/// `PulsarReaderScreen`, reached through [onView].
class SkyPulsarTooltip extends StatelessWidget {
  const SkyPulsarTooltip({
    super.key,
    required this.habit,
    required this.project,
    required this.currentStreak,
    required this.isLit,
    required this.onClose,
    required this.onView,
  });

  final Habit habit;
  final Project? project;
  final int currentStreak;

  /// Whether this pulsar is currently giving light — see
  /// [ConstellationStar.lit]'s own doc comment: the live "kept the
  /// rhythm?" answer, not a fixed fact the way it is for every other
  /// kind.
  final bool isLit;

  final VoidCallback onClose;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final glyphColor = starKindColor(StarKind.pulsar, colors, lit: isLit);

    return Column(
      mainAxisSize: MainAxisSize.min,
      // See [SkyStarTooltip]'s own doc comment on its Column for why
      // `stretch` — every row here centers itself the same way, and a
      // pulsar is a star kind too, so it shares that reasoning exactly.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SkyTooltipHeader(
          icon: StarKind.pulsar.icon,
          iconColor: glyphColor,
          iconSize: 20,
          title: habit.title,
          titleColor: isLit ? colors.text : colors.muted,
          titleFontSize: 18,
          // Same [kFontStarTitle] italic every other star kind's own
          // title uses on its card — see [SkyStarTooltip]'s own use of
          // this for why.
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
        if (habit.description != null) ...[
          const SizedBox(height: 10),
          Text(
            habit.description!,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.muted, fontSize: 14, height: 1.4),
          ),
        ],
        const SizedBox(height: 12),
        // Same [StarExtraBadge] treatment [PulsarCard]'s own streak slot
        // uses, rather than a hand-rolled row — matching it exactly also
        // means it's centered for free, the same way every other kind's
        // own extra badge already is here.
        StarExtraBadge(
          icon: Icons.local_fire_department,
          label: strings.streakBadgeLabel,
          value: '$currentStreak',
        ),
        const SizedBox(height: 12),
        Center(child: IntensityBolts(intensity: habit.intensity, size: 16)),
        const SizedBox(height: 12),
        StarCreatedAt(createdAt: habit.createdAt),
        const SizedBox(height: 14),
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
