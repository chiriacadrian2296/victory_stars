import 'package:flutter/material.dart';

import '../l10n/strings_scope.dart';
import '../models/project.dart';
import '../models/win.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';
import 'area_tag.dart';
import 'intensity_bolts.dart';
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
    final colors = context.colors;
    final borderRadius = BorderRadius.circular(12);

    return Material(
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
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, size: 13, color: colors.gold),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            formatDisplayDateTime(win.date, context.strings),
                            style: TextStyle(fontSize: 12, color: colors.muted),
                          ),
                        ),
                        IntensityBolts(intensity: win.intensity, size: 13, spacing: 2, emphasizeLast: true),
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
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 19, color: colors.text),
                    ),
                    if (win.description != null) ...[
                      const SizedBox(height: 6),
                      Text(win.description!, style: TextStyle(fontSize: 14, color: colors.muted, height: 1.4)),
                    ],
                  ],
                ),
              ),
              // A corner badge rather than inline with the other (small,
              // muted) meta icons — a photo is a bigger deal than a date or
              // intensity rating, so it gets the same gold-accent treatment
              // as the info glyphs on the dashboard's own cards.
              if (win.photoPath != null)
                Positioned(bottom: 10, right: 10, child: Icon(Icons.photo_camera, size: 22, color: colors.gold)),
            ],
          ),
        ),
      ),
    );
  }
}
