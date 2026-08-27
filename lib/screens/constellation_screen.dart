import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/constellation_shapes.dart';
import '../data/win_repository.dart';
import '../models/project.dart';
import '../models/win.dart';
import '../theme/app_colors.dart';
import '../widgets/constellation_painter.dart';
import 'add_win_screen.dart';
import 'win_reader_screen.dart';

/// A single project's constellation: a pannable/zoomable star field shaped
/// like [Project.iconSlug]'s precomputed silhouette, one star per win,
/// oldest first. Tapping a lit star opens [WinReaderScreen] (with editing
/// enabled); the header's add icon adds a win pre-scoped to this project
/// (the FAB is reserved for Home's own "add a win" action).
class ConstellationScreen extends StatefulWidget {
  const ConstellationScreen({super.key, required this.project, required this.winRepository});

  final Project project;
  final WinRepository winRepository;

  @override
  State<ConstellationScreen> createState() => _ConstellationScreenState();
}

class _ConstellationScreenState extends State<ConstellationScreen> {
  static const _canvasSize = Size(1000, 1000);

  late final ConstellationShape? _shape = constellationShapes[widget.project.iconSlug];
  late final Rect _shapeBounds = _shape == null ? Rect.zero : boundingBoxOf(_shape.primary);

  late List<Win> _wins;
  late List<ConstellationStar> _stars;
  int _revision = 0;
  ui.Image? _glowSprite;
  final _transformationController = TransformationController();
  bool _framed = false;

  @override
  void initState() {
    super.initState();
    _wins = widget.winRepository.getAllForProject(widget.project.id);
    _stars = _buildStars(_wins);
    _loadGlowSprite();
  }

  @override
  void dispose() {
    _glowSprite?.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadGlowSprite() async {
    final sprite = await buildGlowSprite();
    if (!mounted) return;
    setState(() {
      _glowSprite = sprite;
      _revision++;
    });
  }

  List<ConstellationStar> _buildStars(List<Win> winsOldestFirst) {
    final shape = _shape;
    if (shape == null) return const [];
    final stars = <ConstellationStar>[];
    for (var i = 0; i < winsOldestFirst.length; i++) {
      final win = winsOldestFirst[i];
      final Offset position;
      if (i < shape.primary.length) {
        position = shape.primary[i];
      } else if (i - shape.primary.length < shape.secondary.length) {
        position = shape.secondary[i - shape.primary.length];
      } else {
        position = seededOverflowPosition(win.id);
      }
      stars.add(ConstellationStar(winId: win.id, position: position));
    }
    return stars;
  }

  Rect _boundsPixels() {
    return Rect.fromLTRB(
      _shapeBounds.left * _canvasSize.width,
      _shapeBounds.top * _canvasSize.height,
      _shapeBounds.right * _canvasSize.width,
      _shapeBounds.bottom * _canvasSize.height,
    );
  }

  double _fitScaleFor(Size viewportSize) {
    if (viewportSize.isEmpty) return 0.1;
    final boundsPixels = _boundsPixels();
    final shapeWidth = boundsPixels.width == 0 ? 1.0 : boundsPixels.width;
    final shapeHeight = boundsPixels.height == 0 ? 1.0 : boundsPixels.height;
    final scale = math.min(viewportSize.width / shapeWidth, viewportSize.height / shapeHeight) * 0.8;
    return scale <= 0 ? 0.1 : scale;
  }

  void _frameShape(Size viewportSize) {
    if (_framed || viewportSize.isEmpty) return;
    _framed = true;
    final scale = _fitScaleFor(viewportSize);
    final center = _boundsPixels().center;
    final matrix = Matrix4.identity()
      ..translateByDouble(viewportSize.width / 2, viewportSize.height / 2, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1);
    setState(() => _transformationController.value = matrix);
  }

  void _refresh() {
    setState(() {
      _wins = widget.winRepository.getAllForProject(widget.project.id);
      _stars = _buildStars(_wins);
      _revision++;
    });
  }

  Future<void> _addWin() async {
    final result = await Navigator.of(context).push<AddWinResult>(
      MaterialPageRoute(builder: (_) => AddWinScreen(lockedProject: widget.project)),
    );
    if (result == null) return;
    await widget.winRepository.add(
      title: result.title,
      description: result.description,
      projectId: widget.project.id,
    );
    _refresh();
  }

  Future<void> _openStar(ConstellationStar star) async {
    final index = _wins.indexWhere((w) => w.id == star.winId);
    if (index == -1) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WinReaderScreen(
          repository: widget.winRepository,
          initialWins: _wins,
          startIndex: index,
          allowEdit: true,
        ),
      ),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final shape = _shape;

    return Scaffold(
      backgroundColor: AppColors.night,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: AppColors.muted),
                ),
                Expanded(
                  child: Text(
                    widget.project.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.text,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: shape == null ? null : _addWin,
                  icon: const Icon(Icons.add, color: AppColors.gold),
                  tooltip: 'Add a win',
                ),
              ],
            ),
            Expanded(
              child: shape == null
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          "This project's constellation shape couldn't be found.",
                          style: TextStyle(color: AppColors.muted),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final viewportSize = constraints.biggest;
                        WidgetsBinding.instance.addPostFrameCallback((_) => _frameShape(viewportSize));
                        final minScale = _fitScaleFor(viewportSize);

                        return InteractiveViewer(
                          transformationController: _transformationController,
                          constrained: false,
                          boundaryMargin: const EdgeInsets.all(200),
                          minScale: minScale,
                          maxScale: minScale * 6,
                          trackpadScrollCausesScale: true,
                          child: RepaintBoundary(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapUp: (details) {
                                final star = hitTestStar(details.localPosition, _canvasSize, _stars);
                                if (star != null) _openStar(star);
                              },
                              child: CustomPaint(
                                size: _canvasSize,
                                painter: ConstellationPainter(
                                  stars: _stars,
                                  glowSprite: _glowSprite,
                                  revision: _revision,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
