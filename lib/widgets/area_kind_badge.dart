import 'package:flutter/material.dart';

import '../l10n/strings_scope.dart';
import '../models/life_area.dart';
import '../theme/app_colors.dart';

/// The first row on every star-list card: the project's [area] (icon +
/// name, gold icon, same treatment as [AreaTag]) followed immediately by
/// the star's kind (icon + [kindLabel], in [kindColor]) — reading together
/// as one phrase, e.g. "Social · Goal". [area] is null when the card's
/// project couldn't be resolved, in which case only the kind half shows.
class AreaKindBadge extends StatelessWidget {
  const AreaKindBadge({
    super.key,
    required this.area,
    required this.kindIcon,
    required this.kindLabel,
    required this.kindColor,
  });

  final LifeArea? area;
  final IconData kindIcon;
  final String kindLabel;
  final Color kindColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final area = this.area;
    return Row(
      children: [
        if (area != null) ...[
          Icon(area.icon, size: 14, color: colors.gold),
          const SizedBox(width: 5),
          Text(
            area.displayName(context.strings),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.text,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Icon(kindIcon, size: 13, color: kindColor),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            kindLabel,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: kindColor,
            ),
          ),
        ),
      ],
    );
  }
}
