import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The standard way a win's 1-5 intensity is shown: five stars, filled up
/// to [intensity], matching the app's own "lit star" language rather than
/// a generic numeric rating.
class IntensityStars extends StatelessWidget {
  const IntensityStars({
    super.key,
    required this.intensity,
    this.size = 14,
    this.spacing = 2,
    this.color,
  });

  final int intensity;
  final double size;
  final double spacing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? context.colors.gold;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++) ...[
          if (i > 1) SizedBox(width: spacing),
          Icon(
            i <= intensity ? Icons.star : Icons.star_border,
            size: size,
            color: i <= intensity ? resolvedColor : resolvedColor.withValues(alpha: 0.35),
          ),
        ],
      ],
    );
  }
}
