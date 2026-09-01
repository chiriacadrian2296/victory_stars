import 'package:flutter/material.dart';

import '../l10n/strings_scope.dart';
import '../models/habit.dart';
import '../models/project.dart';
import '../theme/app_colors.dart';
import 'area_tag.dart';
import 'project_tag.dart';
import 'star_kind_label.dart';

/// A pulsar (habit) in a flat star list — a repeat icon and a streak badge
/// instead of a date/intensity block. [isLit] dims the title, border, and
/// streak the same way [DeadStarCard] dims a tombstoned star; the kind
/// label itself stays the same gold-icon/white-text look regardless, like
/// every other card's.
class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.currentStreak,
    required this.isLit,
    this.onTap,
    this.project,
  });

  final Habit habit;
  final int currentStreak;
  final bool isLit;
  final VoidCallback? onTap;
  final Project? project;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final borderRadius = BorderRadius.circular(12);
    final accent = isLit ? colors.crisisMuted : colors.muted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            color: colors.nightPanel,
            border: Border.all(
              color: accent.withValues(alpha: isLit ? 0.5 : 0.3),
            ),
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
                      icon: Icons.repeat,
                      label: strings.starKindPulsarTagLabel,
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
                      habit.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 19,
                        color: isLit ? colors.text : colors.muted,
                      ),
                    ),
                    if (habit.description != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        habit.description!,
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
              Positioned(
                top: 14,
                right: 14,
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 14,
                      color: isLit ? colors.gold : colors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$currentStreak',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isLit ? colors.gold : colors.muted,
                      ),
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
