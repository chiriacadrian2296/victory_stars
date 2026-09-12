import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The shared top row of every sky tooltip (star/pulsar/constellation/
/// area) — icon, title, close button, all in one line, same shape every
/// one of them originally had by hand before this was factored out.
/// [iconSize]/[titleFontSize] default to the constellation/area tooltips'
/// own original values; the star/pulsar tooltips pass their own
/// (slightly larger) originals explicitly.
class SkyTooltipHeader extends StatelessWidget {
  const SkyTooltipHeader({
    super.key,
    required this.icon,
    required this.iconColor,
    this.iconSize = 18,
    required this.title,
    required this.titleColor,
    this.titleFontSize = 16,
    // Null on every tooltip except star/pulsar — those two are the only
    // ones with a direct card equivalent (`LitStarCard`/`PulsarCard`'s
    // own title) that sets this; a constellation/area's title has no
    // such precedent to match.
    this.titleFontFamily,
    this.titleItalic = false,
    required this.onClose,
  });

  final IconData icon;
  final Color iconColor;
  final double iconSize;
  final String title;
  final Color titleColor;
  final double titleFontSize;
  final String? titleFontFamily;
  final bool titleItalic;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(icon, color: iconColor, size: iconSize),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: titleColor,
              fontSize: titleFontSize,
              fontFamily: titleFontFamily,
              fontStyle: titleItalic ? FontStyle.italic : FontStyle.normal,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        InkWell(
          onTap: onClose,
          borderRadius: BorderRadius.circular(999),
          // Bigger than the rest of this row's own icon — the one button
          // this tooltip closes with, worth an easy target rather than a
          // small glyph squeezed in beside the title.
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(Icons.close, color: colors.muted, size: 26),
          ),
        ),
      ],
    );
  }
}
