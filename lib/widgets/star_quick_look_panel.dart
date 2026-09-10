import 'package:flutter/material.dart';

import '../l10n/strings_scope.dart';
import '../models/project.dart';
import '../models/star.dart';
import '../theme/app_colors.dart';
import '../theme/app_style.dart';
import '../utils/date_format.dart';
import 'area_tag.dart';
import 'intensity_bolts.dart';
import 'project_tag.dart';

/// The bottom half of the Sky, shown after tapping a star, while the
/// camera flies to center it in the top half (see `SkyScreen._flyTo`'s
/// own `anchorFraction` and `_openStar`) — a quick glance at what the
/// star is, without leaving the sky the way pushing `StarReaderScreen`
/// straight away used to. [onView] is the way into that full page from
/// here; [onShare]/[onEdit]/[onDelete] only ever appear when the action
/// they trigger already has a real destination in the app (see
/// `SkyScreen`'s own doc comment on why: no button here does something
/// this app can't already do elsewhere, just from closer at hand).
///
/// Purely presentational — every button just calls back up to
/// `SkyScreen`, which owns the actual repository calls, navigation, and
/// camera state this panel doesn't know about.
class StarQuickLookPanel extends StatelessWidget {
  const StarQuickLookPanel({
    super.key,
    required this.star,
    required this.project,
    required this.onClose,
    required this.onView,
    required this.onEdit,
    this.onShare,
    this.onDelete,
  });

  final Star star;
  final Project? project;
  final VoidCallback onClose;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    final dateLabel = star.achievedDate != null
        ? formatDisplayDateTime(star.achievedDate!, strings)
        : star.targetDate != null
        ? formatDisplayDateTime(star.targetDate!, strings)
        : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.nightPanel,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(kRadiusCard),
        ),
        border: Border(top: BorderSide(color: colors.nightBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: colors.gold, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      star.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: Icon(Icons.close, color: colors.muted, size: 20),
                    tooltip: strings.closeAction,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (project != null || dateLabel != null)
                Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (project != null)
                        ProjectTag(
                          project: project!,
                          textColor: colors.muted,
                          iconSize: 14,
                          fontSize: 13,
                        ),
                      if (project != null)
                        AreaTag(
                          area: project!.area,
                          iconSize: 14,
                          fontSize: 13,
                        ),
                      if (dateLabel != null)
                        Text(
                          dateLabel,
                          style: TextStyle(color: colors.muted, fontSize: 13),
                        ),
                    ],
                  ),
                ),
              if (star.intensity != null) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: IntensityBolts(intensity: star.intensity!, size: 16),
                ),
              ],
              if (star.description != null) ...[
                const SizedBox(height: 12),
                Text(
                  star.description!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: _QuickLookAction(
                      icon: Icons.visibility_outlined,
                      label: strings.starQuickLookViewAction,
                      color: colors.gold,
                      onTap: onView,
                    ),
                  ),
                  if (onShare != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuickLookAction(
                        icon: Icons.share_outlined,
                        label: strings.shareStarLabel,
                        color: colors.muted,
                        onTap: onShare!,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickLookAction(
                      icon: Icons.edit_outlined,
                      label: strings.starQuickLookEditAction,
                      color: colors.muted,
                      onTap: onEdit,
                    ),
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuickLookAction(
                        icon: Icons.delete_outline,
                        label: strings.deleteStarAction,
                        color: colors.danger,
                        onTap: onDelete!,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One action button in the panel's own bottom row — same panel language
/// (`nightPanel`/`nightBorder`) `settings_screen.dart`'s own debug-tools
/// buttons use, sized to stack an icon above a label rather than sit
/// side by side, so up to four of these still fit a phone width without
/// truncating.
class _QuickLookAction extends StatelessWidget {
  const _QuickLookAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.nightPanel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusField),
        side: BorderSide(color: colors.nightBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadiusField),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
