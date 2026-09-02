import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/app_colors.dart';

/// A fullscreen animated nebula/starfield, rendered entirely on the GPU by
/// `shaders/nebula_particles.frag` — no image assets, no 3D engine, just a
/// procedural fragment shader repainted every frame. See
/// `ShaderPlaygroundScreen`, the only current place this is used: a
/// debug-only preview, not wired into any real screen yet.
class NebulaBackground extends StatefulWidget {
  const NebulaBackground({super.key, this.interactive = false});

  /// Whether drag-to-pan and pinch-to-zoom are enabled. Off by default —
  /// only the playground preview wants hands-on exploration; a decorative
  /// background elsewhere wouldn't.
  final bool interactive;

  @override
  State<NebulaBackground> createState() => _NebulaBackgroundState();
}

class _NebulaBackgroundState extends State<NebulaBackground>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;

  Offset _pan = Offset.zero;
  double _zoom = 1;
  double _zoomAtGestureStart = 1;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) => setState(() => _elapsed = elapsed))
      ..start();
    _loadShader();
  }

  Future<void> _loadShader() async {
    final program = await ui.FragmentProgram.fromAsset(
      'shaders/nebula_particles.frag',
    );
    if (!mounted) return;
    setState(() => _shader = program.fragmentShader());
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _zoomAtGestureStart = _zoom;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final size = context.size;
    setState(() {
      _zoom = (_zoomAtGestureStart * details.scale).clamp(0.3, 6.0);
      // Dividing by size.height (not width) keeps pan speed consistent with
      // the shader's own aspect-correction, which normalizes against
      // height too (see nebula_particles.frag's aspectUv). Subtracting
      // (not adding) the delta is what makes the content follow the
      // finger — dragging right should reveal what was off-screen to the
      // left, which means the sampled world position moves left.
      if (size != null && size.height > 0) {
        _pan -= details.focalPointDelta / size.height / _zoom;
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shader = _shader;
    if (shader == null) {
      // Plain fallback while the shader compiles/loads — a flash of the
      // wrong color would be more jarring than a beat of solid night.
      return ColoredBox(color: colors.night);
    }

    final painter = CustomPaint(
      size: Size.infinite,
      painter: _NebulaPainter(
        shader: shader,
        time: _elapsed.inMicroseconds / Duration.microsecondsPerSecond,
        pan: _pan,
        zoom: _zoom,
      ),
    );

    if (!widget.interactive) return painter;

    return GestureDetector(
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      child: painter,
    );
  }
}

class _NebulaPainter extends CustomPainter {
  const _NebulaPainter({
    required this.shader,
    required this.time,
    required this.pan,
    required this.zoom,
  });

  final ui.FragmentShader shader;
  final double time;
  final Offset pan;
  final double zoom;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time)
      ..setFloat(3, pan.dx)
      ..setFloat(4, pan.dy)
      ..setFloat(5, zoom);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _NebulaPainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.pan != pan ||
      oldDelegate.zoom != zoom;
}
