import 'package:flutter/material.dart';

import '../l10n/strings_scope.dart';
import '../models/habit.dart';
import '../models/project.dart';
import '../theme/app_colors.dart';
import 'area_tag.dart';
import 'navigate_here_button.dart';
import 'project_tag.dart';
import 'star_created_at.dart';
import 'star_extra_badge.dart';
import 'star_kind_label.dart';

/// A pulsar (habit) in a flat star list — a repeat icon and a streak badge
/// instead of a date/intensity block. [isLit] dims only the title; every
/// other card kind's border/background look the same regardless of state,
/// and the kind label and streak badge stay the same gold look every other
/// card's does too.
class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.currentStreak,
    required this.isLit,
    this.onTap,
    this.project,
    this.onNavigateTo,
  });

  final Habit habit;
  final int currentStreak;
  final bool isLit;
  final VoidCallback? onTap;
  final Project? project;

  /// Shows a "take me there" corner button when non-null — only passed by
  /// the Galaxy tab's search popup, which can actually jump its sky camera
  /// to this habit's constellation.
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
                  textAlign: TextAlign.center,
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
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.muted,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                StarExtraBadge(
                  icon: Icons.local_fire_department,
                  label: strings.streakBadgeLabel,
                  value: '$currentStreak',
                ),
                const SizedBox(height: 18),
                StarCreatedAt(createdAt: habit.createdAt),
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
