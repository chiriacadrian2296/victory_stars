import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'constellation_field.dart';

/// A second, purely additive sky layer — colored nebula blobs and a sparse
/// field of colored, flickering accent stars — painted between
/// [NebulaBackground] and the constellations in `NebulaScreen`. Deliberately
/// its own widget/shader rather than folded into `NebulaBackground`: if this
/// layer ever needs to be dialed back or dropped, that's just removing this
/// one widget from the Stack, with the proven base sky untouched.
class SkyDecorations extends StatefulWidget {
  const SkyDecorations({super.key, required this.camera, required this.zoom});

  final SkyCamera camera;
  final double zoom;

  @override
  State<SkyDecorations> createState() => _SkyDecorationsState();
}

class _SkyDecorationsState extends State<SkyDecorations>
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
      'shaders/sky_decorations.frag',
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
    // Nothing to draw yet — unlike NebulaBackground, there's no fallback
    // color needed: this layer is purely additive, so "not there yet"
    // and "fully transparent" look identical.
    if (shader == null) return const SizedBox.shrink();

    return CustomPaint(
      size: Size.infinite,
      painter: _SkyDecorationsPainter(
        shader: shader,
        time: _elapsed.inMicroseconds / Duration.microsecondsPerSecond,
        camera: widget.camera,
        zoom: widget.zoom,
      ),
    );
  }
}

class _SkyDecorationsPainter extends CustomPainter {
  const _SkyDecorationsPainter({
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
    // Additive: this layer only ever adds light to the base sky beneath
    // it, never occludes it — see sky_decorations.frag's own note on why
    // its fragColor.a is always 1.0 rather than a coverage value.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = shader
        ..blendMode = BlendMode.plus,
    );
  }

  @override
  bool shouldRepaint(covariant _SkyDecorationsPainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.camera != camera ||
      oldDelegate.zoom != zoom;
}
