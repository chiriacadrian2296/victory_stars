import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../data/constellation_layout.dart';
import '../data/custom_constellation_repository.dart';
import '../data/habit_completion_repository.dart';
import '../data/habit_repository.dart';
import '../data/project_repository.dart';
import '../data/star_repository.dart';
import '../models/habit_completion.dart';
import '../models/project.dart';
import '../theme/app_colors.dart';
import '../widgets/constellation_field.dart';
import '../widgets/constellation_painter.dart';
import '../widgets/nebula_background.dart';
import 'habit_reader_screen.dart';
import 'star_reader_screen.dart';

/// The Nebula tab: every project's constellation, scattered across one
/// shared pannable/zoomable sky over the animated nebula background —
/// mixing two things that already worked separately (`NebulaBackground`,
/// and `ConstellationScreen`'s shape rendering/tap-to-open) rather than
/// building either from scratch. Tapping a star opens the same
/// `StarReaderScreen`/`HabitReaderScreen` a single project's own
/// constellation view does.
class NebulaScreen extends StatefulWidget {
  const NebulaScreen({
    super.key,
    required this.projectRepository,
    required this.starRepository,
    required this.habitRepository,
    required this.habitCompletionRepository,
    required this.customConstellationRepository,
  });

  final ProjectRepository projectRepository;
  final StarRepository starRepository;
  final HabitRepository habitRepository;
  final HabitCompletionRepository habitCompletionRepository;
  final CustomConstellationRepository customConstellationRepository;

  @override
  State<NebulaScreen> createState() => _NebulaScreenState();
}

class _NebulaScreenState extends State<NebulaScreen>
    with TickerProviderStateMixin {
  // High enough that at max zoom a constellation (kSkyConstellationAngularSpan
  // wide) renders at several times the screen's own height — so zooming
  // all the way in shows one small part of it up close, never the whole
  // shape. Picked freely, not tied to any hard geometric limit the way
  // minZoomWithoutRepeats is — this just gives a wide, satisfying range
  // above it. Halved along with minZoomWithoutRepeats and the starting
  // _zoom below so the *entire* range sits farther back — max zoom-in
  // isn't as close, max zoom-out isn't as close, and the default view
  // isn't as close either — rather than only widening one end of it.
  static const _maxZoom = 30.0;

  // Only used to seed the inertia glide's initial velocity now (see
  // _handleScaleEnd) — the live drag itself is an exact rotation (see
  // _handleScaleUpdate/SkyCamera.rotatedToAlign), not a scaled pixel
  // delta, so it has no sensitivity constant to tune at all.
  static const _panSensitivity = 0.15;

  /// The camera's own free orientation — see [SkyCamera]: no fixed "up"
  /// reference, so there's no pole to run into no matter which way (or
  /// how many times over) it's turned.
  SkyCamera _camera = SkyCamera.lookingAt(azimuthTurns: 0, elevationTurns: 0);
  // Halved from the original 1.0 default — see _maxZoom's own comment —
  // so the sky already reads as farther away the moment the tab opens,
  // not just once the user zooms out manually.
  double _zoom = 0.5;
  double _zoomAtGestureStart = 1;

  List<PlacedConstellation> _placed = [];
  ui.Image? _glowSprite;
  int _revision = 0;

  /// Momentum left over from a drag release, in pan-units (turns) per
  /// second — see [_handleScaleEnd]/[_onInertiaTick]. Google Earth's
  /// space view was the explicit reference for this: flick the sky and it
  /// keeps gliding, decelerating smoothly, rather than stopping dead the
  /// instant the finger lifts.
  Offset _panVelocity = Offset.zero;
  Ticker? _inertiaTicker;
  Duration _lastInertiaTick = Duration.zero;

  /// The camera exactly as it was when the current drag began, and the
  /// world direction under the cursor/finger at that same instant — see
  /// [_handleScaleUpdate], which re-derives the camera fresh from these
  /// two every frame (never by accumulating small steps) so that anchor
  /// point stays glued to the cursor for the entire gesture, regardless
  /// of zoom. Both null between gestures.
  SkyCamera? _dragStartCamera;
  (double, double, double)? _dragAnchorDirection;

  /// Debug aid, off by default — see [NebulaBackground.showGrid].
  bool _showGrid = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Opens centered on "Love" rather than the world origin — with a
    // dozen-plus constellations spiraling out from there, landing on empty
    // space by default made the tab feel empty on first open. Leaves
    // _camera at its default origin-facing orientation if no project by
    // that name exists.
    for (final constellation in _placed) {
      if (constellation.project.name == 'Love') {
        _camera = SkyCamera.lookingAt(
          azimuthTurns: constellation.worldPosition.dx,
          elevationTurns: constellation.worldPosition.dy,
        );
        break;
      }
    }
    _loadGlowSprite();
  }

  @override
  void dispose() {
    _inertiaTicker?.dispose();
    _glowSprite?.dispose();
    super.dispose();
  }

  void _stopInertia() {
    _inertiaTicker?.stop();
    _inertiaTicker?.dispose();
    _inertiaTicker = null;
  }

  /// Turns [_camera] by a raw cursor-derived [delta] — dragging left
  /// looks right, dragging down looks up (see [SkyCamera.rotated]'s own
  /// sign convention for why `delta.dx`/`delta.dy` map straight onto it
  /// with no extra negation). Since [SkyCamera] always rotates around its
  /// *own current* axes rather than fixed world ones, this needs no
  /// pole-crossing compensation the old azimuth/elevation camera did —
  /// there's no pole left to cross.
  void _rotateCamera(Offset delta) {
    _camera = _camera.rotated(
      horizontalTurns: delta.dx,
      verticalTurns: delta.dy,
    );
  }

  /// Starts (or restarts) the coast-to-a-stop glide after a drag release —
  /// see [_handleScaleEnd]. Runs its own ticker rather than reusing the
  /// scale gesture's setState pattern since it needs to keep animating
  /// well after the gesture itself has ended.
  void _startInertia() {
    _stopInertia();
    _lastInertiaTick = Duration.zero;
    _inertiaTicker = createTicker(_onInertiaTick)..start();
  }

  void _onInertiaTick(Duration elapsed) {
    final dt = _lastInertiaTick == Duration.zero
        ? 0.0
        : (elapsed - _lastInertiaTick).inMicroseconds / 1e6;
    _lastInertiaTick = elapsed;
    if (dt <= 0) return;

    setState(() {
      _rotateCamera(_panVelocity * dt);
      // Exponential decay ("friction") — velocityDecayPerSecond is what
      // fraction of the velocity survives after a full second, so this
      // stays frame-rate independent rather than shrinking by a fixed
      // amount per tick.
      const velocityDecayPerSecond = 0.04;
      final decay = math.pow(velocityDecayPerSecond, dt).toDouble();
      _panVelocity *= decay;
    });

    // Stop once velocity is imperceptibly small (turns/second) rather than
    // coasting forever at a value too tiny to ever visibly move anything.
    const minVelocity = 0.0001;
    if (_panVelocity.distanceSquared < minVelocity * minVelocity) {
      _stopInertia();
    }
  }

  Future<void> _loadGlowSprite() async {
    final sprite = await buildGlowSprite();
    if (!mounted) return;
    setState(() {
      _glowSprite = sprite;
      _revision++;
    });
  }

  /// Sorted ascending by id (== creation order, ids are timestamp-based) —
  /// never by `ProjectRepository.getAll()`'s own newest-first order, so a
  /// new project always lands at the end of the list and never shifts an
  /// existing constellation's [constellationWorldPosition] index.
  void _loadData() {
    final projects = widget.projectRepository.getAll().toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    final completionsByHabit = <int, List<HabitCompletion>>{};
    for (final completion in widget.habitCompletionRepository.getAll()) {
      completionsByHabit
          .putIfAbsent(completion.habitId, () => [])
          .add(completion);
    }

    _placed = [
      for (var i = 0; i < projects.length; i++)
        _buildPlaced(projects[i], i, completionsByHabit),
    ];
  }

  PlacedConstellation _buildPlaced(
    Project project,
    int index,
    Map<int, List<HabitCompletion>> completionsByHabit,
  ) {
    final shape = project.customConstellationId != null
        ? widget.customConstellationRepository
              .getById(project.customConstellationId!)
              ?.shape
        : null;
    final stars = widget.starRepository.getAllForProject(project.id);
    final habits = widget.habitRepository.getAllForProject(project.id);
    final built = buildConstellationRenderStars(
      stars: stars,
      habits: habits,
      shape: shape,
      completionsByHabit: completionsByHabit,
    );

    return PlacedConstellation(
      project: project,
      shape: shape,
      worldPosition: constellationWorldPosition(index),
      stars: stars,
      habits: habits,
      renderStars: built.stars,
      edges: built.edges,
      shapeStarCount: built.shapeStarCount,
    );
  }

  void _refresh() {
    setState(() {
      _loadData();
      _revision++;
    });
  }

  Future<void> _openStar(
    PlacedConstellation constellation,
    ConstellationStar star,
  ) async {
    if (star.kind == StarKind.habit) {
      final habit = constellation.habits.firstWhere(
        (h) => h.id == star.entityId,
      );
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HabitReaderScreen(
            habit: habit,
            project: constellation.project,
            habitRepository: widget.habitRepository,
            habitCompletionRepository: widget.habitCompletionRepository,
            projectRepository: widget.projectRepository,
            customConstellationRepository: widget.customConstellationRepository,
          ),
        ),
      );
      _refresh();
      return;
    }

    final index = constellation.stars.indexWhere((s) => s.id == star.entityId);
    if (index == -1) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StarReaderScreen(
          repository: widget.starRepository,
          initialStars: constellation.stars,
          startIndex: index,
          allowEdit: true,
          projectsById: {constellation.project.id: constellation.project},
          projectRepository: widget.projectRepository,
          customConstellationRepository: widget.customConstellationRepository,
          refreshStars: () =>
              widget.starRepository.getAllForProject(constellation.project.id),
        ),
      ),
    );
    _refresh();
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _zoomAtGestureStart = _zoom;
    _stopInertia();
    final size = context.size;
    if (size != null && size.height > 0) {
      _dragStartCamera = _camera;
      _dragAnchorDirection = screenToDirection(
        details.localFocalPoint,
        _camera,
        _zoom,
        size,
      );
    } else {
      _dragStartCamera = null;
      _dragAnchorDirection = null;
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final size = context.size;
    setState(() {
      _zoom = (_zoomAtGestureStart * details.scale).clamp(
        minZoomWithoutRepeats,
        _maxZoom,
      );
      final startCamera = _dragStartCamera;
      final anchor = _dragAnchorDirection;
      if (size != null && size.height > 0 && startCamera != null && anchor != null) {
        // Exact "grab and drag": re-derive the camera fresh, every frame,
        // as the single rotation of the *drag's starting* camera that
        // puts [anchor] back under wherever the cursor is *now* — never
        // by accumulating a small-angle delta step by step, so there's no
        // per-frame approximation error to build up over a long drag, and
        // the anchor point stays exactly under the cursor regardless of
        // zoom (recomputing its direction with the live zoom here is also
        // what makes a simultaneous pinch keep its focal point anchored
        // too, for the same reason).
        final current = screenToDirection(
          details.localFocalPoint,
          startCamera,
          _zoom,
          size,
        );
        // rotatedToAlign(from, to) rotates the *camera basis* so that a
        // FIXED WORLD direction at [from] renders at [to]'s screen
        // position. We want the opposite composition here: [anchor] is
        // fixed (the point grabbed at drag start) and needs to keep
        // rendering at the cursor's current screen position, which is
        // [current] only *as read against the unrotated startCamera* —
        // so the rotation actually needed is the one that carries
        // [current] to [anchor], not [anchor] to [current] (verified by
        // matching worldToScreen(anchor, camera') against
        // worldToScreen(current, startCamera) algebraically; passing
        // them the other way round was live-tested and turned every
        // drag/zoom backwards).
        _camera = startCamera.rotatedToAlign(current, anchor).rolled(
          details.rotation,
        );
      }
    });
  }

  /// Kicks off the coast-to-a-stop glide (see [_startInertia]) with
  /// whatever velocity the finger/pointer was moving at on release —
  /// [ScaleEndDetails.velocity] is already exactly that, in pixels/second.
  /// The glide itself has no cursor to track exactly (see
  /// [SkyCamera.rotated] vs. [SkyCamera.rotatedToAlign]), so this converts
  /// to pan-units/second with the same approximate pixels/height/zoom
  /// scaling [_rotateCamera] uses, rather than reusing the live drag's own
  /// exact tracking.
  void _handleScaleEnd(ScaleEndDetails details) {
    final size = context.size;
    if (size == null || size.height <= 0) return;
    _panVelocity =
        details.velocity.pixelsPerSecond / size.height / _zoom * _panSensitivity;
    if (_panVelocity == Offset.zero) return;
    _startInertia();
  }

  // Pinch/trackpad zoom arrives through the GestureDetector's scale
  // gesture above (and already keeps its focal point anchored, for free,
  // as a side effect of _handleScaleUpdate's own exact tracking) — a
  // plain mouse wheel never triggers that, so it needs its own
  // pointer-signal handler. Zooms toward wherever the cursor is, not the
  // screen center — matching a phone's pinch-to-zoom, which always
  // zooms wherever the fingers are, never forces the center.
  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final size = context.size;
    if (size == null) return;
    _stopInertia();
    final oldZoom = _zoom;
    final oldCamera = _camera;
    final anchor = screenToDirection(
      event.localPosition,
      oldCamera,
      oldZoom,
      size,
    );
    setState(() {
      _zoom = (oldZoom * math.exp(-event.scrollDelta.dy * 0.0015)).clamp(
        minZoomWithoutRepeats,
        _maxZoom,
      );
      final current = screenToDirection(
        event.localPosition,
        oldCamera,
        _zoom,
        size,
      );
      // See _handleScaleUpdate's comment — the rotation needed carries
      // [current] to [anchor], not the other way round.
      _camera = oldCamera.rotatedToAlign(current, anchor);
    });
  }

  void _handleTapUp(TapUpDetails details) {
    final size = context.size;
    if (size == null) return;
    final hit = hitTestField(
      details.localPosition,
      _placed,
      _camera,
      _zoom,
      size,
    );
    if (hit != null) _openStar(hit.$1, hit.$2);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: Listener(
        onPointerSignal: _handlePointerSignal,
        child: GestureDetector(
          onScaleStart: _handleScaleStart,
          onScaleUpdate: _handleScaleUpdate,
          onScaleEnd: _handleScaleEnd,
          onTapUp: _handleTapUp,
          child: Stack(
            fit: StackFit.expand,
            children: [
              NebulaBackground(
                camera: _camera,
                zoom: _zoom,
                showGrid: _showGrid,
              ),
              CustomPaint(
                painter: ConstellationFieldPainter(
                  placed: _placed,
                  camera: _camera,
                  zoom: _zoom,
                  glowSprite: _glowSprite,
                  // White rather than the theme's usual gold/text/crisis
                  // tints, for now — paired with the bolder line/icon/glow
                  // sizing in ConstellationFieldPainter, this is what
                  // actually makes a small, far-away constellation stand
                  // out against the sky.
                  starColor: Colors.white,
                  coreColor: Colors.white,
                  habitColor: Colors.white,
                  revision: _revision,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Material(
                      color: colors.nightPanel.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Grid',
                              style: TextStyle(color: colors.muted, fontSize: 13),
                            ),
                            Switch(
                              value: _showGrid,
                              onChanged: (value) =>
                                  setState(() => _showGrid = value),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _RollKnob(
                      angle: cameraRollAngle(_camera),
                      onRoll: (delta) {
                        _stopInertia();
                        setState(() => _camera = _camera.rolled(delta));
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A two-finger rotate gesture (see `_handleScaleUpdate`) is touch-only —
/// a mouse/trackpad has no equivalent, so desktop/web needs its own
/// control for the same [SkyCamera.rolled]. Drag anywhere around this
/// dial (not just directly on the icon) and the camera rolls by however
/// far the angle around the dial's own center changed since the last
/// frame — same feel as spinning a real dial or a ship's wheel, and
/// exactly the same underlying rotation a phone's pinch-rotate drives.
/// Gold rather than the app's usual muted night-panel chrome so it reads
/// as a live control at a glance instead of blending into the sky behind
/// it, and the small dot orbiting just outside its rim — see [angle] —
/// is what actually shows how far you've rolled, the way a map app's own
/// small compass badge shows its needle rather than just a plain icon.
class _RollKnob extends StatefulWidget {
  const _RollKnob({required this.angle, required this.onRoll});

  /// Current roll, in radians, relative to level (see
  /// `cameraRollAngle` in `constellation_field.dart`) — purely a readout,
  /// never written back by this widget; drag gestures only ever report a
  /// *delta* through [onRoll], same as before.
  final double angle;

  /// Called with a delta angle in radians (positive = clockwise, matching
  /// [SkyCamera.rolled]'s own convention) every time the drag angle around
  /// the dial's center changes.
  final ValueChanged<double> onRoll;

  @override
  State<_RollKnob> createState() => _RollKnobState();
}

class _RollKnobState extends State<_RollKnob> {
  static const _knobSize = 52.0;
  // Bigger than _knobSize so the indicator dot has room to orbit just
  // outside the knob's own rim without getting clipped.
  static const _boxSize = 76.0;
  static const _orbitRadius = _knobSize / 2 + 8;
  static const _dotSize = 10.0;

  double? _lastAngle;

  void _updateAngle(Offset localPosition) {
    final center = const Offset(_knobSize / 2, _knobSize / 2);
    final vector = localPosition - center;
    // Too close to the pivot for an angle to mean anything stable — just
    // wait for the drag to move further out instead of jittering.
    if (vector.distance < 6) return;

    final angle = math.atan2(vector.dy, vector.dx);
    final lastAngle = _lastAngle;
    if (lastAngle != null) {
      // Shortest signed distance around the circle, so crossing the
      // ±π seam (straight left of center) doesn't register as a
      // near-full rotation the wrong way.
      var delta = angle - lastAngle;
      if (delta > math.pi) delta -= 2 * math.pi;
      if (delta < -math.pi) delta += 2 * math.pi;
      widget.onRoll(delta);
    }
    _lastAngle = angle;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Same screen-space atan2(dy, dx) convention _updateAngle itself
    // measures drags in, so the dot visibly orbits the same way the
    // dial's been dragged.
    final dotCenter = Offset(
      _boxSize / 2 + _orbitRadius * math.cos(widget.angle),
      _boxSize / 2 + _orbitRadius * math.sin(widget.angle),
    );

    return SizedBox(
      width: _boxSize,
      height: _boxSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: (_boxSize - _knobSize) / 2,
            top: (_boxSize - _knobSize) / 2,
            child: GestureDetector(
              onPanStart: (details) => _updateAngle(details.localPosition),
              onPanUpdate: (details) => _updateAngle(details.localPosition),
              onPanEnd: (_) => _lastAngle = null,
              child: Container(
                width: _knobSize,
                height: _knobSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.gold,
                  border: Border.all(color: colors.nightBorder),
                ),
                child: Icon(Icons.threesixty, color: colors.onGold, size: 26),
              ),
            ),
          ),
          Positioned(
            left: dotCenter.dx - _dotSize / 2,
            top: dotCenter.dy - _dotSize / 2,
            child: Container(
              width: _dotSize,
              height: _dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.gold,
                boxShadow: [
                  BoxShadow(
                    color: colors.gold.withValues(alpha: 0.7),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
