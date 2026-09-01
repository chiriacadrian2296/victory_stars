import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The one fact unique to a star's kind — a photo, a target date, a death
/// date, or a streak — shown centered between the description and the
/// intensity/date block. Every card reserves the same fixed height for
/// this slot via [StarExtraBadgeSlot] even when there's nothing to show,
/// so a list of mixed kinds doesn't visually jump around.
class StarExtraBadge extends StatelessWidget {
  const StarExtraBadge({
    super.key,
    required this.icon,
    required this.label,
    this.value,
  });

  final IconData icon;
  final String label;

  /// Appended after [label] (e.g. a date or a streak count) — omitted for
  /// a badge that's just "this is true" (the photo badge has no value of
  /// its own beyond its presence).
  final String? value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.gold),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.gold,
          ),
        ),
        if (value != null) ...[
          const SizedBox(width: 5),
          Text(value!, style: TextStyle(fontSize: 12, color: colors.gold)),
        ],
      ],
    );
  }
}

/// Reserves [height] of vertical space, centered, for a [StarExtraBadge]
/// (or nothing — pass a null [badge] when this card's kind has no fact to
/// show) — see [StarExtraBadge]'s own doc comment for why every card uses
/// this instead of just conditionally including the badge.
class StarExtraBadgeSlot extends StatelessWidget {
  const StarExtraBadgeSlot({super.key, this.badge, this.height = 24});

  final Widget? badge;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: badge == null ? null : Center(child: badge),
    );
  }
}
