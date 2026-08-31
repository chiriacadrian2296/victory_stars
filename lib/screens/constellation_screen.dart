import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/constellation_layout.dart';
import '../data/constellation_shapes_v2.dart';
import '../data/habit_completion_repository.dart';
import '../data/habit_repository.dart';
import '../data/project_repository.dart';
import '../data/star_repository.dart';
import '../l10n/strings_scope.dart';
import '../models/habit.dart';
import '../models/habit_completion.dart';
import '../models/project.dart';
import '../models/star.dart';
import '../theme/app_colors.dart';
import '../utils/habit_stats.dart';
import '../widgets/constellation_painter.dart';
import 'habit_reader_screen.dart';
import 'star_reader_screen.dart';

/// A single project's constellation: a pannable/zoomable star field shaped
/// like [Project.iconSlug]'s precomputed silhouette. Victories, goals, and
/// dead (tombstoned) stars share the shape's own point/edge graph, ordered
/// by [Star.slotSequence]; habits are separate, smaller stars scattered
/// around/inside/outside the shape (see [seededHabitPosition]), never part
/// of that graph. Tapping a star opens [StarReaderScreen]/[HabitReaderScreen]
/// (with editing enabled). Adding a new star/habit to this project happens
/// through Home's own FAB chooser (via the project picker) — this screen is
/// read/browse only.
class ConstellationScreen extends StatefulWidget {
  const ConstellationScreen({
    super.key,
    required this.project,
    required this.starRepository,
    required this.projectRepository,
    required this.habitRepository,
    required this.habitCompletionRepository,
  });

  final Project project;
  final StarRepository starRepository;
  final ProjectRepository projectRepository;
  final HabitRepository habitRepository;
  final HabitCompletionRepository habitCompletionRepository;

  @override
  State<ConstellationScreen> createState() => _ConstellationScreenState();
}

class _ConstellationScreenState extends State<ConstellationScreen> {
  static const _canvasSize = Size(1000, 1000);

  late final ConstellationShape? _shape =
      constellationShapes[widget.project.iconSlug];
  late final Rect _shapeBounds = _shape == null
      ? Rect.zero
      : boundingBoxOf(_shape.points);

  late List<Star> _stars;
  late List<Habit> _habits;
  late List<ConstellationStar> _renderStars;
  late List<(int, int)> _edges;
  late int _shapeStarCount;
  int _revision = 0;
  ui.Image? _glowSprite;
  final _transformationController = TransformationController();
  bool _framed = false;

  @override
  void initState() {
    super.initState();
    _loadData();
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

  void _loadData() {
    _stars = widget.starRepository.getAllForProject(widget.project.id);
    _habits = widget.habitRepository.getAllForProject(widget.project.id);
    _renderStars = _buildRenderStars();
  }

  List<ConstellationStar> _buildRenderStars() {
    final shape = _shape;
    if (shape == null) {
      _edges = const [];
      _shapeStarCount = 0;
      return const [];
    }

    _shapeStarCount = _stars.length;
    final layout = buildConstellationLayout(shape, _stars.length);
    _edges = layout.edges;

    final result = <ConstellationStar>[];
    for (var i = 0; i < _stars.length; i++) {
      final star = _stars[i];
      final position = i < layout.points.length
          ? layout.points[i]
          : seededOverflowPosition(star.id);
      final kind = star.dead
          ? StarKind.dead
          : (star.isAchieved ? StarKind.victory : StarKind.goal);
      result.add(
        ConstellationStar(
          entityId: star.id,
          position: position,
          kind: kind,
          lit: star.isAchieved,
        ),
      );
    }

    final completionsByHabit = <int, List<HabitCompletion>>{};
    for (final completion in widget.habitCompletionRepository.getAll()) {
      completionsByHabit
          .putIfAbsent(completion.habitId, () => [])
          .add(completion);
    }
    for (final habit in _habits) {
      final completedDays =
          (completionsByHabit[habit.id] ?? const <HabitCompletion>[])
              .map((c) => DateTime(c.date.year, c.date.month, c.date.day))
              .toSet();
      result.add(
        ConstellationStar(
          entityId: habit.id,
          position: seededHabitPosition(habit.id),
          kind: StarKind.habit,
          lit: isHabitLit(completedDays),
        ),
      );
    }

    return result;
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
    final scale =
        math.min(
          viewportSize.width / shapeWidth,
          viewportSize.height / shapeHeight,
        ) *
        0.8;
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
      _loadData();
      _revision++;
    });
  }

  Future<void> _openStar(ConstellationStar star) async {
    if (star.kind == StarKind.habit) {
      final habit = _habits.firstWhere((h) => h.id == star.entityId);
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HabitReaderScreen(
            habit: habit,
            project: widget.project,
            habitRepository: widget.habitRepository,
            habitCompletionRepository: widget.habitCompletionRepository,
            projectRepository: widget.projectRepository,
          ),
        ),
      );
      _refresh();
      return;
    }

    final index = _stars.indexWhere((s) => s.id == star.entityId);
    if (index == -1) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StarReaderScreen(
          repository: widget.starRepository,
          initialStars: _stars,
          startIndex: index,
          allowEdit: true,
          projectsById: {widget.project.id: widget.project},
          projectRepository: widget.projectRepository,
          refreshStars: () =>
              widget.starRepository.getAllForProject(widget.project.id),
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
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _frameShape(viewportSize),
                        );
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
                                final star = hitTestStar(
                                  details.localPosition,
                                  _canvasSize,
                                  _renderStars,
                                );
                                if (star != null) _openStar(star);
                              },
                              child: CustomPaint(
                                size: _canvasSize,
                                painter: ConstellationPainter(
                                  stars: _renderStars,
                                  glowSprite: _glowSprite,
                                  revision: _revision,
                                  starColor: colors.gold,
                                  coreColor: colors.text,
                                  habitColor: colors.crisisMuted,
                                  edges: _edges,
                                  linkThreshold: shape.points.length,
                                  shapeStarCount: _shapeStarCount,
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
