import 'package:flutter/material.dart';

import '../l10n/strings_scope.dart';
import '../models/project.dart';
import '../models/star.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';
import 'area_tag.dart';
import 'project_tag.dart';

/// A still-unlit goal in a flat star list — [star] is always expected to
/// satisfy [Star.isGoal]. Dim-gold accents (instead of the solid gold a
/// [StarCard] uses) mark it as "not yet a victory", and its own tag plus
/// optional target date make that legible even out of context.
class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.star, this.onTap, this.project});

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
            color: colors.nightPanel,
            border: Border.all(color: colors.goldDim.withValues(alpha: 0.35)),
            borderRadius: borderRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 13, color: colors.goldDim),
                    const SizedBox(width: 6),
                    Text(
                      strings.achievedToggleOff,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.goldDim,
                      ),
                    ),
                    if (star.targetDate != null) ...[
                      const Spacer(),
                      Icon(Icons.event_outlined, size: 13, color: colors.muted),
                      const SizedBox(width: 5),
                      Text(
                        formatDisplayDate(star.targetDate!, strings),
                        style: TextStyle(fontSize: 12, color: colors.muted),
                      ),
                    ],
                  ],
                ),
                if (project != null) ...[
                  const SizedBox(height: 8),
                  AreaTag(area: project!.area),
                  const SizedBox(height: 4),
                  ProjectTag(project: project!),
                ],
                const SizedBox(height: 8),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
