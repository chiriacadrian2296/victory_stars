import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The star-list cards' first row: the kind alone (e.g. "Goal"), centered
/// and large — the one thing a glance at the card should answer first,
/// before area, project, or title. [iconColor] defaults to gold; [textColor]
/// defaults to the theme's text color (used by every kind except
/// [StarCard], which passes gold so a victory reads as fully "lit" rather
/// than just accented, and [DeadStarCard], whose icon is the app's other
/// light-blue accent instead of gold).
class StarKindLabel extends StatelessWidget {
  const StarKindLabel({
    super.key,
    required this.icon,
    required this.label,
    this.iconColor,
    this.textColor,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: iconColor ?? colors.gold),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textColor ?? colors.text,
            ),
          ),
        ],
      ),
    );
  }
}
