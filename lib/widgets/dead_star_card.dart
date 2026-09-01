import 'package:flutter/material.dart';

import '../l10n/strings_scope.dart';
import '../models/project.dart';
import '../models/star.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';
import 'area_tag.dart';
import 'project_tag.dart';
import 'star_kind_label.dart';

/// A tombstoned star in a flat star list — [star] is always expected to
/// satisfy `star.dead`. The title stays muted so it visibly reads as
/// "spent" next to lit victories and goals; everything else (kind label,
/// area/project, death date) uses the same gold-accented look every other
/// card does. Tapping it opens the reader's "resurrect" flow.
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
                    StarKindLabel(
                      icon: Icons.star_outline,
                      label: strings.deadStarTitle,
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
