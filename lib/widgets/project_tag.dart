import 'package:flutter/material.dart';

import '../models/project.dart';
import '../theme/app_colors.dart';
import '../utils/icon_for_slug.dart';

/// The standard way a [Project] is shown wherever it appears as a small
/// piece of context: icon + name, deliberately quieter than [AreaTag] —
/// the area is the headline fact, the project is supporting detail.
/// [textColor] defaults to [AppColors.muted] for the night background;
/// pass [AppColors.crisisMuted] on the reflection-screen gradient instead.
class ProjectTag extends StatelessWidget {
  const ProjectTag({
    super.key,
    required this.project,
    this.iconSize = 13,
    this.fontSize = 13,
    this.textColor = AppColors.muted,
  });

  final Project project;
  final double iconSize;
  final double fontSize;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(iconForSlug(project.iconSlug), size: iconSize, color: AppColors.gold),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            project.name,
            style: TextStyle(fontSize: fontSize, color: textColor, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
