import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/constellation_shapes.dart';
import '../data/project_repository.dart';
import '../data/win_repository.dart';
import '../l10n/strings_scope.dart';
import '../models/project.dart';
import '../models/win.dart';
import '../theme/app_colors.dart';
import '../widgets/constellation_painter.dart';
import 'add_win_screen.dart';
import 'win_reader_screen.dart';

/// A single project's constellation: a pannable/zoomable star field shaped
/// like [Project.iconSlug]'s precomputed silhouette, one star per win,
/// oldest first. Tapping a lit star opens [WinReaderScreen] (with editing
/// enabled — including reassigning the win to a different project, which
/// requires [projectRepository] here too); the header's add icon adds a
/// win pre-scoped to this project (the FAB is reserved for Home's own
/// "add a win" action).
class ConstellationScreen extends StatefulWidget {
  const ConstellationScreen({
    super.key,
    required this.project,
    required this.winRepository,
    required this.projectRepository,
  });

  final Project project;
  final WinRepository winRepository;
  final ProjectRepository projectRepository;

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
      projectId: result.projectId,
      intensity: result.intensity,
      date: result.date,
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
          projectsById: {widget.project.id: widget.project},
          projectRepository: widget.projectRepository,
          refreshWins: () => widget.winRepository.getAllForProject(widget.project.id),
        ),
      ),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final shape = _shape;
    final colors = context.colors;
    final strings = context.strings;

    return Scaffold(
      backgroundColor: colors.night,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.arrow_back, color: colors.muted),
                ),
                Expanded(
                  child: Text(
                    widget.project.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: colors.text,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: shape == null ? null : _addWin,
                  icon: Icon(Icons.add, color: colors.gold),
                  tooltip: strings.addWinTooltip,
                ),
              ],
            ),
            Expanded(
              child: shape == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          strings.constellationShapeMissing,
                          style: TextStyle(color: colors.muted),
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
                                  starColor: colors.gold,
                                  coreColor: colors.text,
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
