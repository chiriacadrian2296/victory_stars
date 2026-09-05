import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'constellation_field.dart';

/// Another alternative take on the same slot [SkyDecorations]/[SkyWisps]
/// filled before it (see `NebulaScreen.build` — only one of the three is
/// ever wired in at a time): a single Gargantua-style black hole. Unlike
/// those two, this one paints with plain alpha blending (the default
/// `Paint()`, no `blendMode` override) rather than `BlendMode.plus` — a
/// black hole has to occlude the sky behind it with genuine opaque black,
/// which an additive blend could never do.
class SkyBlackHole extends StatefulWidget {
  const SkyBlackHole({super.key, required this.camera, required this.zoom});

  final SkyCamera camera;
  final double zoom;

  @override
  State<SkyBlackHole> createState() => _SkyBlackHoleState();
}

class _SkyBlackHoleState extends State<SkyBlackHole>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) => setState(() => _elapsed = elapsed))
      ..start();
    _loadShader();
  }

  Future<void> _loadShader() async {
    final program = await ui.FragmentProgram.fromAsset(
      'shaders/sky_black_hole.frag',
    );
    if (!mounted) return;
    setState(() => _shader = program.fragmentShader());
  }

  @override
  void dispose() {
    _ticker.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shader = _shader;
    if (shader == null) return const SizedBox.shrink();

    return CustomPaint(
      size: Size.infinite,
      painter: _SkyBlackHolePainter(
        shader: shader,
        time: _elapsed.inMicroseconds / Duration.microsecondsPerSecond,
        camera: widget.camera,
        zoom: widget.zoom,
      ),
    );
  }
}

class _SkyBlackHolePainter extends CustomPainter {
  const _SkyBlackHolePainter({
    required this.shader,
    required this.time,
    required this.camera,
    required this.zoom,
  });

  final ui.FragmentShader shader;
  final double time;
  final SkyCamera camera;
  final double zoom;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time)
      ..setFloat(3, camera.forward.$1)
      ..setFloat(4, camera.forward.$2)
      ..setFloat(5, camera.forward.$3)
      ..setFloat(6, camera.right.$1)
      ..setFloat(7, camera.right.$2)
      ..setFloat(8, camera.right.$3)
      ..setFloat(9, camera.up.$1)
      ..setFloat(10, camera.up.$2)
      ..setFloat(11, camera.up.$3)
      ..setFloat(12, zoom);
    // Plain alpha blend (no blendMode override) — see this widget's own
    // doc comment for why: the event horizon needs to occlude with real
    // opaque black, which BlendMode.plus (used by SkyDecorations/SkyWisps)
    // can never do.
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _SkyBlackHolePainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.camera != camera ||
      oldDelegate.zoom != zoom;
}
