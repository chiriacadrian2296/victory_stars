import 'package:flutter/material.dart';

import '../l10n/strings_scope.dart';
import '../models/project.dart';
import '../models/star.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';
import 'area_kind_badge.dart';
import 'project_tag.dart';

/// A tombstoned star in a flat star list — [star] is always expected to
/// satisfy `star.dead`. Rendered in muted tones (title included) so it
/// visibly reads as "spent" next to lit victories and dim-gold goals — the
/// one exception is its death date, deliberately gold like every other
/// card's top-right indicator, since that's the one fact about a dead star
/// still worth drawing the eye to. Tapping it opens the reader's
/// "resurrect" flow.
class DeadStarCard extends StatelessWidget {
  const DeadStarCard({super.key, required this.star, this.onTap, this.project});

  final Star star;
  final VoidCallback? onTap;
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
            color: colors.nightPanel.withValues(alpha: 0.6),
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
                    AreaKindBadge(
                      area: project?.area,
                      kindIcon: Icons.star_outline,
                      kindLabel: strings.deadStarTitle,
                      kindColor: colors.muted,
                    ),
                    if (project != null) ...[
                      const SizedBox(height: 8),
                      ProjectTag(
                        project: project!,
                        textColor: colors.muted,
                        iconColor: colors.muted,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      star.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 19,
                        color: colors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (star.deadDate != null)
                Positioned(
                  top: 14,
                  right: 14,
                  child: Row(
                    children: [
                      Icon(Icons.church, size: 13, color: colors.gold),
                      const SizedBox(width: 5),
                      Text(
                        formatDisplayDate(star.deadDate!, strings),
                        style: TextStyle(fontSize: 12, color: colors.gold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
