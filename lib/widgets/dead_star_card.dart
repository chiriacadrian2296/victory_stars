import 'package:flutter/material.dart';

import '../l10n/strings_scope.dart';
import '../models/project.dart';
import '../models/star.dart';
import '../theme/app_colors.dart';

/// A tombstoned star in a flat star list — [star] is always expected to
/// satisfy `star.dead`. Rendered entirely in muted tones (no gold anywhere,
/// title included) so it visibly reads as "spent" next to lit victories and
/// dim-gold goals. Tapping it opens the reader's "resurrect" flow — the
/// trailing wand icon hints that without needing extra copy.
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star_outline, size: 13, color: colors.muted),
                    const SizedBox(width: 6),
                    Text(
                      strings.deadStarTitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.muted,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.auto_fix_high, size: 15, color: colors.muted),
                  ],
                ),
                if (project != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    project!.name,
                    style: TextStyle(fontSize: 12.5, color: colors.muted),
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
        ),
      ),
    );
  }
}
