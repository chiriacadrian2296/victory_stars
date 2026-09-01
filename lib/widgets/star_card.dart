import 'package:flutter/material.dart';

import '../l10n/strings_scope.dart';
import '../models/project.dart';
import '../models/star.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';
import 'area_tag.dart';
import 'intensity_bolts.dart';
import 'project_tag.dart';
import 'star_kind_label.dart';

/// A single achieved star (victory) in a flat list — [star] is always
/// expected to satisfy [Star.isAchieved]; every list this card appears in
/// (Home's day detail, an area's flat Stars list) already filters to
/// achieved-only before building these.
class StarCard extends StatelessWidget {
  const StarCard({super.key, required this.star, this.onTap, this.project});

  final Star star;
  final VoidCallback? onTap;

  /// The star's project, resolved by the caller. Null when it can't be
  /// resolved (e.g. stale data) — the card still renders fine without the
  /// project/area rows.
  final Project? project;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final borderRadius = BorderRadius.circular(12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            color: colors.nightPanel,
            border: Border.all(color: colors.nightBorder),
            borderRadius: borderRadius,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A victory reads as fully "lit" (gold icon and text),
                    // unlike the other kinds' gold-icon/white-text look.
                    StarKindLabel(
                      icon: Icons.star,
                      label: strings.starKindVictoryTagLabel,
                      textColor: colors.gold,
                    ),
                    if (project != null) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AreaTag(
                              area: project!.area,
                              iconSize: 18,
                              fontSize: 15,
                            ),
                            const SizedBox(width: 14),
                            ProjectTag(
                              project: project!,
                              iconSize: 15,
                              fontSize: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      star.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 19,
                        color: colors.text,
                      ),
                    ),
                    if (star.description != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        star.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Center(
                      child: IntensityBolts(
                        intensity: star.intensity!,
                        size: 20,
                        spacing: 4,
                        emphasizeLast: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: colors.muted,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            formatDisplayDate(star.achievedDate!, strings),
                            style: TextStyle(fontSize: 12, color: colors.muted),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: colors.muted,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            formatDisplayTime(star.achievedDate!),
                            style: TextStyle(fontSize: 12, color: colors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (star.photoPath != null)
                Positioned(
                  top: 14,
                  right: 14,
                  child: Icon(Icons.photo_camera, size: 20, color: colors.gold),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
