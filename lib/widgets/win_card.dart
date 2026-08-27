import 'package:flutter/material.dart';

import '../models/project.dart';
import '../models/win.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';
import 'area_tag.dart';
import 'intensity_stars.dart';
import 'project_tag.dart';

class WinCard extends StatelessWidget {
  const WinCard({super.key, required this.win, this.onTap, this.project});

  final Win win;
  final VoidCallback? onTap;

  /// The win's project, resolved by the caller. Null when it can't be
  /// resolved (e.g. stale data) — the card still renders fine without the
  /// project/area rows.
  final Project? project;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.nightPanel,
            border: Border.all(color: AppColors.nightBorder),
            borderRadius: borderRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, size: 13, color: AppColors.gold),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        formatDisplayDateTime(win.date),
                        style: const TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ),
                    IntensityStars(intensity: win.intensity, size: 10, spacing: 1),
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
                  win.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 19,
                    color: AppColors.text,
                  ),
                ),
                if (win.description != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    win.description!,
                    style: const TextStyle(fontSize: 14, color: AppColors.muted, height: 1.4),
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
