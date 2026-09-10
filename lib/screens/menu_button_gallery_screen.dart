import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../theme/app_colors.dart';

/// A dev-only comparison page for the Sky's menu FAB (see
/// `SkyScreen._MenuStarButton`) — nine variants of "how should the white
/// logo sit on top of the button's own blue glow" side by side, 3 per row,
/// so a look can be picked by eye in one build instead of one build per
/// variant (a debug apk build + install + relaunch is ~20-40s all in,
/// each round trip). None of these buttons go anywhere; tapping one just
/// plays the same brief "charge" flash the real button's hold gesture
/// drives, so the glow itself can be seen reacting.
///
/// Reached from Settings' own debug tools — see `settings_screen.dart` —
/// same place every other dev/QA-only screen in the app lives, not
/// somewhere a regular user would stumble into.
class MenuButtonGalleryScreen extends StatefulWidget {
  const MenuButtonGalleryScreen({super.key});

  @override
  State<MenuButtonGalleryScreen> createState() =>
      _MenuButtonGalleryScreenState();
}

class _MenuButtonGalleryScreenState extends State<MenuButtonGalleryScreen>
    with SingleTickerProviderStateMixin {
  // Same white recolor of the app's logo the real button now uses (see
  // assets/icon/app_icon_ring_centered_white.png) — loaded once here and
  // handed down to every card, rather than once per card.
  static const _logoAsset = 'assets/icon/app_icon_ring_centered_white.png';

  ui.FragmentShader? _shader;
  ui.Image? _logoImage;
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) => setState(() => _elapsed = elapsed))
      ..start();
    _load();
  }

  Future<void> _load() async {
    final program = await ui.FragmentProgram.fromAsset(
      'shaders/menu_star_button.frag',
    );
    final bytes = await rootBundle.load(_logoAsset);
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() {
      _shader = program.fragmentShader();
      _logoImage = frame.image;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _shader?.dispose();
    _logoImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shader = _shader;
    final logoImage = _logoImage;

    return Scaffold(
      backgroundColor: colors.night,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Menu Button Gallery'),
      ),
      body: shader == null || logoImage == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.85,
                ),
                itemCount: _variants.length,
                itemBuilder: (context, index) {
                  final variant = _variants[index];
                  return _GalleryButtonCard(
                    variant: variant,
                    shader: shader,
                    logoImage: logoImage,
                    time:
                        _elapsed.inMicroseconds /
                        Duration.microsecondsPerSecond,
                  );
                },
              ),
            ),
    );
  }
}

class _Variant {
  const _Variant(this.label, this.blendMode, this.opacity);

  final String label;
  final BlendMode blendMode;
  final double opacity;
}

// Nine combinations for the current logo — a dark (nightPanel) disc with a
// white star cut out, no ring, background transparent outside the disc
// (see assets/icon/app_icon_ring_centered_white.png) — a different
// question from the ring+disc pass this replaced: that one asked "how
// solid should the white parts be against the glow", this one asks "how
// should a *dark* disc sit against the glow behind it". Plain alpha at
// three opacities, plus blend modes that actually do something to a
// mostly-dark source (screen/lighten/color-dodge barely touch near-black,
// so they're dropped in favor of ones that visibly interact with darks:
// multiply/darken deepen it further, overlay/soft/hard-light let the glow's
// own brightness modulate it, color-burn is the sharpest of that family).
const _variants = [
  _Variant('Normal 100%', BlendMode.srcOver, 1.0),
  _Variant('Normal 85%', BlendMode.srcOver, 0.85),
  _Variant('Normal 70%', BlendMode.srcOver, 0.70),
  _Variant('Multiply 100%', BlendMode.multiply, 1.0),
  _Variant('Darken 100%', BlendMode.darken, 1.0),
  _Variant('Overlay 100%', BlendMode.overlay, 1.0),
  _Variant('Soft Light 100%', BlendMode.softLight, 1.0),
  _Variant('Hard Light 90%', BlendMode.hardLight, 0.90),
  _Variant('Color Burn 80%', BlendMode.colorBurn, 0.80),
];

class _GalleryButtonCard extends StatefulWidget {
  const _GalleryButtonCard({
    required this.variant,
    required this.shader,
    required this.logoImage,
    required this.time,
  });

  final _Variant variant;
  final ui.FragmentShader shader;
  final ui.Image logoImage;
  final double time;

  @override
  State<_GalleryButtonCard> createState() => _GalleryButtonCardState();
}

class _GalleryButtonCardState extends State<_GalleryButtonCard>
    with SingleTickerProviderStateMixin {
  static const _iconSize = 58.0;
  static const _scale = _iconSize / (2 * 0.09) * 0.85;
  static const _logoSize = 72.0;
  // Smaller than the real button's own 6x — this canvas is shared with
  // eight siblings in a tight grid, so its overflow is clipped per-card
  // (see the [ClipRect] in build()) rather than left free to spill into
  // the next cell the way the lone real button lets it spill into open
  // sky.
  static const _glowCanvasSize = _iconSize * 3.2;
  static const _cardClipSize = 140.0;

  late final AnimationController _charge;

  @override
  void initState() {
    super.initState();
    _charge = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _charge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) => _charge.forward(),
          onTapUp: (_) => _charge.reverse(),
          onTapCancel: () => _charge.reverse(),
          child: SizedBox(
            width: _cardClipSize,
            height: _cardClipSize,
            child: ClipRect(
              child: OverflowBox(
                minWidth: _glowCanvasSize,
                maxWidth: _glowCanvasSize,
                minHeight: _glowCanvasSize,
                maxHeight: _glowCanvasSize,
                child: AnimatedBuilder(
                  animation: _charge,
                  builder: (context, _) => CustomPaint(
                    painter: _GalleryStarPainter(
                      shader: widget.shader,
                      time: widget.time,
                      scale: _scale,
                      charge: _charge.value,
                      logoImage: widget.logoImage,
                      logoSize: _logoSize,
                      blendMode: widget.variant.blendMode,
                      opacity: widget.variant.opacity,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.variant.label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}

class _GalleryStarPainter extends CustomPainter {
  const _GalleryStarPainter({
    required this.shader,
    required this.time,
    required this.scale,
    required this.charge,
    required this.logoImage,
    required this.logoSize,
    required this.blendMode,
    required this.opacity,
  });

  final ui.FragmentShader shader;
  final double time;
  final double scale;
  final double charge;
  final ui.Image logoImage;
  final double logoSize;
  final BlendMode blendMode;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time)
      ..setFloat(3, scale)
      ..setFloat(4, charge);

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = shader
        ..blendMode = BlendMode.plus,
    );

    final center = Offset(size.width, size.height) / 2;
    final rect = Rect.fromCenter(
      center: center,
      width: logoSize,
      height: logoSize,
    );
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    canvas.drawImageRect(
      logoImage,
      Rect.fromLTWH(
        0,
        0,
        logoImage.width.toDouble(),
        logoImage.height.toDouble(),
      ),
      rect,
      Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..blendMode = blendMode
        ..filterQuality = FilterQuality.high,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GalleryStarPainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.charge != charge ||
      oldDelegate.blendMode != blendMode ||
      oldDelegate.opacity != opacity;
}
