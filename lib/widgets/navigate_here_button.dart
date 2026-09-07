import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A small "take me there" trigger shown on a card only when the caller can
/// jump the Galaxy tab's sky camera to it (the search popup opened from
/// [NebulaScreen]) — omitted everywhere else, such as the plain Sky tab,
/// where there's no 3D camera to move.
class NavigateHereButton extends StatelessWidget {
  const NavigateHereButton({super.key, required this.onTap, this.tooltip});

  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final button = Material(
      color: colors.gold.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(Icons.near_me, size: 16, color: colors.gold),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
