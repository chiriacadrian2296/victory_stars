import 'package:flutter/material.dart';

import '../l10n/strings_scope.dart';
import '../models/project.dart';
import '../models/star.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';
import 'area_tag.dart';
import 'navigate_here_button.dart';
import 'project_tag.dart';
import 'star_created_at.dart';
import 'star_extra_badge.dart';
import 'star_kind_label.dart';

/// A tombstoned star in a flat star list — [star] is always expected to
/// satisfy `star.dead`. The title stays muted so it visibly reads as
/// "spent" next to lit victories and goals, and the kind icon uses the
/// app's light-blue accent instead of gold; everything else matches every
/// other card's look. Tapping it opens the reader's "resurrect" flow.
class DeadStarCard extends StatelessWidget {
  const DeadStarCard({
    super.key,
    required this.star,
    this.onTap,
    this.project,
    this.onNavigateTo,
  });

  final Star star;
  final VoidCallback? onTap;
  final Project? project;

  /// Shows a "take me there" corner button when non-null — only passed by
  /// the Galaxy tab's search popup, which can actually jump its sky camera
  /// to this star's constellation.
  final VoidCallback? onNavigateTo;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final borderRadius = BorderRadius.circular(12);

    final card = Material(
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StarKindLabel(
                  icon: Icons.star_outline,
                  label: strings.deadStarTitle,
                  iconColor: colors.crisisMuted,
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
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 19,
                    color: colors.muted,
                  ),
                ),
                const SizedBox(height: 12),
                StarExtraBadge(
                  icon: Icons.church,
                  label: star.deadDate == null
                      ? strings.noDeadDateLabel
                      : strings.deadDateBadgeLabel,
                  value: star.deadDate == null
                      ? null
                      : formatDisplayDate(star.deadDate!, strings),
                  dimmed: star.deadDate == null,
                ),
                const SizedBox(height: 18),
                StarCreatedAt(createdAt: star.createdAt),
              ],
            ),
          ),
        ),
      ),
    );

    if (onNavigateTo == null) return card;
    return Stack(
      children: [
        card,
        Positioned(
          top: 6,
          right: 6,
          child: NavigateHereButton(
            onTap: onNavigateTo!,
            tooltip: strings.takeMeThereAction,
          ),
        ),
      ],
    );
  }
}
