import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The standard way a win's 1-5 intensity is shown: five bolts, filled up to
/// [intensity]. A bolt rather than a star — a star is what's *created* by a
/// win, so representing its own intensity with more (smaller) stars didn't
/// make much conceptual sense.
class IntensityBolts extends StatelessWidget {
  const IntensityBolts({
    super.key,
    required this.intensity,
    this.size = 14,
    this.spacing = 2,
    this.color,
    this.emphasizeLast = false,
  });

  final int intensity;
  final double size;
  final double spacing;
  final Color? color;

  /// When true, the last lit bolt (at index [intensity]) renders a bit
  /// bigger and with a soft glow instead of looking identical to the other
  /// lit bolts — used on the add/edit star form, where that bolt is the one
  /// the slider is currently pointing at.
  final bool emphasizeLast;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? context.colors.gold;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 1; i <= 5; i++) ...[
          if (i > 1) SizedBox(width: spacing),
          _bolt(i, resolvedColor),
        ],
      ],
    );
  }

  Widget _bolt(int i, Color resolvedColor) {
    final lit = i <= intensity;
    final isEmphasized = emphasizeLast && lit && i == intensity;
    final icon = Icon(
      lit ? Icons.bolt : Icons.bolt_outlined,
      size: isEmphasized ? size * 1.35 : size,
      color: lit ? resolvedColor : resolvedColor.withValues(alpha: 0.35),
    );
    if (!isEmphasized) return icon;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: resolvedColor.withValues(alpha: 0.6), blurRadius: 12)],
      ),
      child: icon,
    );
  }
}
