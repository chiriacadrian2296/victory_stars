import 'package:flutter/material.dart';

import '../models/star_kind.dart';
import '../theme/app_colors.dart';

/// The one color a [StarKind] is drawn in outside the sky — on cards, in
/// the form's kind switch, in the metaphor guide. Mirrors
/// [ConstellationPainter]'s own families exactly, so a kind looks the same
/// whether you meet it as a point of light in the sky or as a label on a
/// list: gold for anything burning, blue for anything without light,
/// neutral white for a slot with no meaning yet.
///
/// [lit] only matters for [StarKind.pulsar] — the one kind that changes
/// family day by day.
Color starKindColor(StarKind kind, AppColors colors, {bool lit = true}) {
  return switch (kind) {
    StarKind.nascent => colors.starNascent,
    StarKind.lit => colors.gold,
    StarKind.unlit => colors.starUnlit,
    StarKind.pulsar => lit ? colors.gold : colors.starUnlit,
    StarKind.dead => colors.starDead,
  };
}

/// Whether this kind is currently giving light — i.e. whether it belongs to
/// the gold family rather than the blue/neutral ones.
bool starKindIsBurning(StarKind kind, {bool lit = true}) {
  return kind == StarKind.lit || (kind == StarKind.pulsar && lit);
}

/// A star of one [kind], drawn the way the sky draws it: its own icon in
/// its own family's color, wrapped in the glow that only a burning star
/// gets. The single graphical representation reused everywhere a kind needs
/// showing rather than just naming — the metaphor guide, the star form's
/// kind switch, and every card's kind label.
///
/// A burning pulsar also breathes, slowly, since pulsing is the whole point
/// of a pulsar; nothing else here animates.
class StarGlyph extends StatefulWidget {
  const StarGlyph({
    super.key,
    required this.kind,
    this.lit = true,
    this.size = 28,
  });

  final StarKind kind;

  /// Only meaningful for [StarKind.pulsar] — whether today's rhythm has
  /// been kept. Ignored by every other kind, whose family is fixed.
  final bool lit;

  /// The icon's own size; the glow around it scales with this.
  final double size;

  @override
  State<StarGlyph> createState() => _StarGlyphState();
}

class _StarGlyphState extends State<StarGlyph>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  bool get _shouldPulse => widget.kind == StarKind.pulsar && widget.lit;

  @override
  void initState() {
    super.initState();
    _syncPulse();
  }

  @override
  void didUpdateWidget(StarGlyph oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  /// Only a burning pulsar carries a controller at all — every other kind
  /// is static, and a stopped-but-alive ticker per glyph would be pure
  /// overhead on a list of dozens of cards.
  void _syncPulse() {
    if (_shouldPulse) {
      _pulse ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      )..repeat(reverse: true);
    } else {
      _pulse?.dispose();
      _pulse = null;
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = starKindColor(widget.kind, colors, lit: widget.lit);
    final burning = starKindIsBurning(widget.kind, lit: widget.lit);

    Widget glyph(double glowStrength) => Container(
      width: widget.size * 1.6,
      height: widget.size * 1.6,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: burning
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.22 + 0.26 * glowStrength),
                  blurRadius: widget.size * (0.5 + 0.35 * glowStrength),
                  spreadRadius: widget.size * 0.06 * glowStrength,
                ),
              ]
            : null,
      ),
      child: Icon(widget.kind.icon, size: widget.size, color: color),
    );

    final pulse = _pulse;
    if (pulse == null) return glyph(0.35);
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) => glyph(pulse.value),
    );
  }
}
