import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../data/area_vision_repository.dart';
import '../data/constellation_layout.dart';
import '../data/custom_constellation_repository.dart';
import '../data/habit_completion_repository.dart';
import '../data/habit_repository.dart';
import '../data/project_repository.dart';
import '../data/star_repository.dart';
import '../l10n/strings_scope.dart';
import '../models/habit_completion.dart';
import '../models/life_area.dart';
import '../models/project.dart';
import '../models/star_kind.dart';
import '../notifications/reminder_service.dart';
import '../settings/settings_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_style.dart';
import '../utils/responsive.dart';
import '../widgets/constellation_field.dart';
import '../widgets/constellation_painter.dart';
import '../widgets/nebula_background.dart';
// import '../widgets/sky_decorations.dart'; — the spiral-galaxy take on this
// slot, disabled first in favor of SkyWisps, then SkyBlackHole, then
// SkySupernova below; see the Stack in build().
// import '../widgets/sky_wisps.dart'; — the wispy-nebula take, disabled too.
// import '../widgets/sky_black_hole.dart'; — the lensed-black-hole take,
// disabled too.
import '../widgets/sky_area_sigils.dart';
import '../widgets/sky_menu_drawer.dart';
import '../widgets/sky_navigation_target.dart';
import '../widgets/sky_supernova.dart';
import 'admire_stars_screen.dart';
import 'area_detail_screen.dart';
import 'constellation_screen.dart';
import 'friends_screen.dart';
import 'sky_search_screen.dart';
import 'metaphor_screen.dart';
import 'pulsar_reader_screen.dart';
import 'new_project_screen.dart';
import 'settings_screen.dart';
import 'shooting_stars_screen.dart';
import 'star_form_screen.dart';
import 'star_reader_screen.dart';
import 'stats_screen.dart';
import 'visions_screen.dart';

/// Shared by the Grid switch pill and [_ZoomSlider] at the bottom of the
/// sky overlay, so the two read as matching controls rather than each
/// sizing to its own content — `Switch`'s own default (bigger) touch
/// target would otherwise make the Grid pill taller than the slider.
/// [_bottomPillRadius] is exactly half [_bottomPillHeight] — a full
/// stadium/pill shape, the fully-rounded end of the range rather than a
/// squared-off rectangle.
const double _bottomPillHeight = 44.0;
const double _bottomPillRadius = 22.0;

/// The Sky: the app's one and only screen. Every constellation, scattered
/// across a single pannable/zoomable sky over the animated nebula
/// background, with each supernova burning where its own area sits.
/// Everything else in the app opens as a page on top of this one — from
/// the side menu ([SkyMenuDrawer]), from the search popup, or by tapping
/// the sky itself.
///
/// Tapping resolves to whatever was aimed at: a star (opening its reader,
/// or the form that configures it if it's still nascent), a constellation,
/// or a supernova.
class SkyScreen extends StatefulWidget {
  const SkyScreen({
    super.key,
    required this.settings,
    required this.projectRepository,
    required this.starRepository,
    required this.habitRepository,
    required this.habitCompletionRepository,
    required this.customConstellationRepository,
    required this.areaVisionRepository,
    required this.reminderService,
  });

  final SettingsController settings;
  final ProjectRepository projectRepository;
  final StarRepository starRepository;
  final HabitRepository habitRepository;
  final HabitCompletionRepository habitCompletionRepository;
  final CustomConstellationRepository customConstellationRepository;
  final AreaVisionRepository areaVisionRepository;
  final ReminderService reminderService;

  @override
  State<SkyScreen> createState() => _SkyScreenState();
}

class _SkyScreenState extends State<SkyScreen> with TickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  // See kSkyMaxZoom's own doc comment (constellation_field.dart) for why
  // this value, and why it's shared rather than private to this class.
  // Halved along with minZoomWithoutRepeats and the starting _zoom below
  // so the *entire* range sits farther back — max zoom-in isn't as close,
  // max zoom-out isn't as close, and the default view isn't as close
  // either — rather than only widening one end of it.
  static const _maxZoom = kSkyMaxZoom;

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
  int _revision = 0;
  ui.FragmentProgram? _flareProgram;

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

  /// Whether each sky-overlay control is currently shown at all — not to
  /// be confused with [SettingsController.showGrid] (that one toggles the
  /// grid *content* drawn on the sky itself, and is a real persisted
  /// setting now, editable from Settings; these toggle the little UI
  /// controls sitting on top of it). Defaulted off for now — a request to
  /// preview the sky with none of its navigation-helper chrome showing —
  /// not a removal: flip these back to `true` to restore them, and
  /// [_showUiControlsMenu] (still fully intact) still flips them at
  /// runtime once its own button is showing again.
  bool _showGridControl = false;
  bool _showZoomControl = false;
  bool _showRotationControl = false;

  /// Same "preview it clean" request as the three above, for the overlay
  /// buttons that never had a toggle of their own: the search pill, the
  /// tune/settings button that opens [_showUiControlsMenu], and — once
  /// the star FAB (see [_MenuStarButton]) gave the menu a second way in —
  /// the drawer button itself too. `static const` rather than instance
  /// state — these aren't meant to be flipped at runtime, only reverted
  /// here in code.
  static const bool _showSearchButton = false;
  static const bool _showUiControlsButton = false;
  static const bool _showDrawerButton = false;

  /// Drives the "take me there" fly-to animation — a single controller
  /// reused across flights rather than rebuilt per tap, so a second tap
  /// mid-flight can redirect it smoothly instead of leaving an orphaned
  /// listener behind. [_flyStartCamera]/[_flyTargetForward] are read by
  /// [_onFlyTick] on every frame; null between flights.
  late final AnimationController _flyController;
  SkyCamera? _flyStartCamera;
  (double, double, double)? _flyTargetForward;
  double _flyStartZoom = 0;
  double _flyTargetZoom = 0;

  @override
  void initState() {
    super.initState();
    _flyController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 900),
        )..addListener(_onFlyTick);
    _loadData();
    _loadFlareProgram();
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
  }

  @override
  void dispose() {
    _flyController.dispose();
    _inertiaTicker?.dispose();
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

  Future<void> _loadFlareProgram() async {
    final program = await buildConstellationFlareProgram();
    if (!mounted) return;
    setState(() {
      _flareProgram = program;
      _revision++;
    });
  }

  /// Sorted ascending by id (== creation order, ids are timestamp-based) —
  /// never by `ProjectRepository.getAll()`'s own newest-first order, so a
  /// new project always lands at the end of its own [Project.area]'s
  /// sequence and never shifts an existing constellation's
  /// [constellationWorldPosition] index within that area.
  void _loadData() {
    final projects = widget.projectRepository.getAll().toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    final completionsByHabit = <int, List<HabitCompletion>>{};
    for (final completion in widget.habitCompletionRepository.getAll()) {
      completionsByHabit
          .putIfAbsent(completion.habitId, () => [])
          .add(completion);
    }

    // Counts each project's position within its own area's sequence
    // (rather than a single global index) — see [constellationWorldPosition],
    // which clusters a project's constellation around its own area's
    // supernova instead of scattering it across the whole sky.
    final indexByArea = <LifeArea, int>{};
    _placed = [
      for (final project in projects)
        _buildPlaced(
          project,
          indexByArea.update(
            project.area,
            (value) => value + 1,
            ifAbsent: () => 0,
          ),
          completionsByHabit,
        ),
    ];
  }

  PlacedConstellation _buildPlaced(
    Project project,
    int indexInArea,
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
      worldPosition: constellationWorldPosition(project.area, indexInArea),
      stars: stars,
      habits: habits,
      renderStars: built.stars,
      edges: built.edges,
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
    // A nascent star isn't something to read — it's an empty slot on the
    // shape, and tapping it is how you give it a meaning.
    if (star.kind == StarKind.nascent) {
      await _configureNascentStar(constellation, star);
      return;
    }
    // Sitting on a slot is what makes a star part of the shape; a pulsar
    // (alive or dead) scatters around it instead and has none. That's the
    // reliable test for which repository this star came from — its kind
    // isn't, since a dead star can be either.
    if (star.slotSequence == null) {
      final habit = constellation.habits.firstWhere(
        (h) => h.id == star.entityId,
      );
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PulsarReaderScreen(
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

  /// Opens the star form on one specific empty slot of [constellation]'s
  /// shape — the slot the tapped nascent star occupies — and creates the
  /// star exactly there, so the point of light the user aimed at is the one
  /// that lights up. The pulsar option is off: this slot belongs to the
  /// shape, and a pulsar never sits on the shape.
  Future<void> _configureNascentStar(
    PlacedConstellation constellation,
    ConstellationStar star,
  ) async {
    final result = await Navigator.of(context).push<Object>(
      MaterialPageRoute(
        builder: (_) => StarFormScreen(
          lockedProject: constellation.project,
          slotSequence: star.slotSequence,
          allowPulsar: false,
        ),
      ),
    );
    if (result is! StarFormResult) return;
    await widget.starRepository.add(
      title: result.title,
      description: result.description,
      projectId: result.projectId,
      slotSequence: result.slotSequence,
      targetDate: result.targetDate,
      achievedDate: result.achievedDate,
      intensity: result.intensity,
      photoPath: result.photoPath,
    );
    _refresh();
  }

  /// The menu's own "light a star" entry: the same form, with every kind
  /// on offer and no constellation implied yet, so it can create a lit
  /// star, a pulsar or an unlit star anywhere.
  Future<void> _openStarForm() async {
    final result = await Navigator.of(context).push<Object>(
      MaterialPageRoute(
        builder: (_) => StarFormScreen(
          projectRepository: widget.projectRepository,
          customConstellationRepository: widget.customConstellationRepository,
        ),
      ),
    );
    if (result is! StarFormResult) return;
    if (result.kind == StarKind.pulsar) {
      await widget.habitRepository.add(
        title: result.title,
        description: result.description,
        projectId: result.projectId,
        intensity: result.intensity ?? 3,
        reminderHour: result.reminderHour,
        reminderMinute: result.reminderMinute,
      );
    } else {
      await widget.starRepository.add(
        title: result.title,
        description: result.description,
        projectId: result.projectId,
        targetDate: result.targetDate,
        achievedDate: result.achievedDate,
        intensity: result.intensity,
        photoPath: result.photoPath,
      );
    }
    _refresh();
  }

  Future<void> _openNewConstellation() async {
    await Navigator.of(context).push<Project>(
      MaterialPageRoute(
        builder: (_) => NewProjectScreen(
          projectRepository: widget.projectRepository,
          customConstellationRepository: widget.customConstellationRepository,
        ),
      ),
    );
    _refresh();
  }

  Future<void> _openVisions() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VisionsScreen(
          areaVisionRepository: widget.areaVisionRepository,
          projectRepository: widget.projectRepository,
          starRepository: widget.starRepository,
        ),
      ),
    );
    _refresh();
  }

  void _openAdmire() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdmireStarsScreen(
          starRepository: widget.starRepository,
          projectRepository: widget.projectRepository,
          customConstellationRepository: widget.customConstellationRepository,
        ),
      ),
    );
  }

  void _openStatistics() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StatsScreen(
          starRepository: widget.starRepository,
          projectRepository: widget.projectRepository,
          habitRepository: widget.habitRepository,
          habitCompletionRepository: widget.habitCompletionRepository,
          customConstellationRepository: widget.customConstellationRepository,
        ),
      ),
    );
  }

  void _openShootingStars() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ShootingStarsScreen()),
    );
  }

  void _openFriends() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FriendsScreen()),
    );
  }

  void _openMetaphor() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MetaphorScreen()),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          settings: widget.settings,
          starRepository: widget.starRepository,
          projectRepository: widget.projectRepository,
          habitRepository: widget.habitRepository,
          habitCompletionRepository: widget.habitCompletionRepository,
          customConstellationRepository: widget.customConstellationRepository,
          areaVisionRepository: widget.areaVisionRepository,
          reminderService: widget.reminderService,
        ),
      ),
    );
    _refresh();
  }

  /// The FAB's own way into the same menu the drawer opens — same content
  /// ([SkyMenuContent], same callbacks), just as a modal sheet from the
  /// bottom instead of a panel from the side. An alternative entry point
  /// being tried alongside the drawer, not a replacement for it — both
  /// stay live so the two can be compared.
  void _openMenuModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // Explicit, not just relying on the default: with a scrollable
      // ListView as the sheet's own content, a swipe-down starting over
      // it can otherwise get claimed by the list's own scroll gesture
      // before the sheet's drag-to-dismiss ever sees it. The drag handle
      // gives a small always-available strip that's never part of the
      // list, so a downward swipe from there closes the sheet reliably
      // regardless of the list's own scroll position.
      enableDrag: true,
      showDragHandle: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      builder: (_) => SafeArea(
        child: SkyMenuContent(
          onLightAStar: _openStarForm,
          onNewConstellation: _openNewConstellation,
          onVisions: _openVisions,
          onShootingStars: _openShootingStars,
          onSearch: _openSearch,
          onStatistics: _openStatistics,
          onAdmire: _openAdmire,
          onFriends: _openFriends,
          onSettings: _openSettings,
          onMetaphor: _openMetaphor,
          detailed: true,
        ),
      ),
    );
  }

  /// Opens the search/filter popup (three levels of the same sky, minus a
  /// header — see [SkySearchScreen]) and, if a card's "take me there"
  /// button closed it with a target, snaps the camera to it.
  Future<void> _openSearch() async {
    final target = await Navigator.of(context).push<SkyNavigationTarget>(
      MaterialPageRoute(
        builder: (_) => SkySearchScreen(
          projectRepository: widget.projectRepository,
          starRepository: widget.starRepository,
          habitRepository: widget.habitRepository,
          habitCompletionRepository: widget.habitCompletionRepository,
          customConstellationRepository: widget.customConstellationRepository,
          areaVisionRepository: widget.areaVisionRepository,
        ),
      ),
    );
    _refresh();
    if (target != null) _flyTo(target);
  }

  PlacedConstellation? _placedFor(Project project) {
    for (final placed in _placed) {
      if (placed.project.id == project.id) return placed;
    }
    return null;
  }

  Offset? _worldFor(SkyNavigationTarget target) => switch (target) {
    SkyAreaTarget(:final area) => areaWorldPosition(area),
    SkyProjectTarget(:final project) => _placedFor(project)?.worldPosition,
    SkyStarTarget(:final project) => _placedFor(project)?.worldPosition,
  };

  /// How far (radians) a supernova's farthest constellation sits from its
  /// own center, plus one constellation's own angular footprint so that
  /// farthest one doesn't itself get cut off at the screen edge — what
  /// [_zoomFor] fits a [SkyAreaTarget] to. Falls back to a fixed,
  /// comfortable radius for an area with no constellations yet, rather
  /// than zooming in absurdly close on a single bare point of light.
  double _areaAngularRadius(LifeArea area) {
    final center = areaWorldPosition(area);
    var maxDistance = 0.0;
    for (final placed in _placed) {
      if (placed.project.area != area) continue;
      final distance = angularDistanceBetween(center, placed.worldPosition);
      if (distance > maxDistance) maxDistance = distance;
    }
    if (maxDistance == 0) return kSkyConstellationAngularSpan * 3;
    return maxDistance + kSkyConstellationAngularSpan;
  }

  /// The zoom [_flyTo] should land [target] at — see the Galaxy search
  /// plan's own note on why each level gets a different one: a supernova
  /// or constellation zoom-to-fit ([zoomToFit], via [_areaAngularRadius]
  /// for the former and one constellation's own fixed angular footprint
  /// for the latter — see [kSkyConstellationAngularSpan]'s own doc comment
  /// on why that's already a reasonable "don't cut off its stars" radius
  /// without inspecting each one's exact layout); a single star, for now,
  /// simply zooms all the way in.
  double _zoomFor(SkyNavigationTarget target, Size screenSize) {
    return switch (target) {
      SkyStarTarget() => _maxZoom,
      SkyAreaTarget(:final area) => zoomToFit(
        angularRadius: _areaAngularRadius(area),
        screenSize: screenSize,
      ).clamp(minZoomWithoutRepeats, _maxZoom),
      SkyProjectTarget() => zoomToFit(
        angularRadius: kSkyConstellationAngularSpan,
        screenSize: screenSize,
      ).clamp(minZoomWithoutRepeats, _maxZoom),
    };
  }

  /// Flies the camera to [target]'s spot on the sky sphere — always dead
  /// center (see [SkyCamera.lookingAt]), zoomed per [_zoomFor]. Animated as
  /// one smooth sweep along the great circle from wherever the camera
  /// currently looks (see [SkyCamera.rotatedToAlignFraction]), Maps-style,
  /// rather than an instant cut — [_onFlyTick] drives it every frame.
  void _flyTo(SkyNavigationTarget target) {
    final size = context.size;
    if (size == null) return;
    final world = _worldFor(target);
    if (world == null) return;

    final targetForward = SkyCamera.lookingAt(
      azimuthTurns: world.dx,
      elevationTurns: world.dy,
    ).forward;

    _stopInertia();
    _flyStartCamera = _camera;
    _flyTargetForward = targetForward;
    _flyStartZoom = _zoom;
    _flyTargetZoom = _zoomFor(target, size);
    _flyController
      ..stop()
      ..reset()
      ..forward();
  }

  void _onFlyTick() {
    final startCamera = _flyStartCamera;
    final targetForward = _flyTargetForward;
    if (startCamera == null || targetForward == null) return;
    final t = Curves.easeInOutCubic.transform(_flyController.value);
    setState(() {
      _camera = startCamera.rotatedToAlignFraction(
        startCamera.forward,
        targetForward,
        t,
      );
      _zoom = _flyStartZoom + (_flyTargetZoom - _flyStartZoom) * t;
    });
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _zoomAtGestureStart = _zoom;
    _stopInertia();
    _flyController.stop();
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
    _flyController.stop();
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

  /// Below this [zoomPercent] reading, a tap never resolves to an
  /// individual star — only to the constellation it's in (or a supernova).
  /// Zoomed out, a constellation's stars sit close enough together on
  /// screen that a tap aimed at the constellation as a whole kept
  /// resolving to whichever star happened to be nearest instead, which
  /// read as wrong (tapping a constellation shouldn't open a specific
  /// star at random). Zoomed in this far, stars are spread out enough on
  /// screen that a tap is unambiguously aimed at one of them specifically.
  static const _starTapMinZoomPercent = 90.0;

  void _handleTapUp(TapUpDetails details) {
    final size = context.size;
    if (size == null) return;
    final hit = zoomPercent(_zoom) >= _starTapMinZoomPercent
        ? hitTestField(details.localPosition, _placed, _camera, _zoom, size)
        : null;
    if (hit != null) {
      _openStar(hit.$1, hit.$2);
      return;
    }
    // An invisible zone over each supernova's own icon — no visible change
    // to `SkySupernova`'s artwork, just the same tap-to-open-detail
    // behavior the Galaxy search popup's own Supernovas cards already have
    // (see [hitTestSupernovas]).
    final area = hitTestSupernovas(details.localPosition, _camera, _zoom, size);
    if (area != null) {
      _openArea(area);
      return;
    }
    // Same idea one level down: a tap that lands within a constellation's
    // own shape but not precisely on one of its stars (already handled
    // above) opens that constellation's own screen instead of doing
    // nothing — see [hitTestConstellations].
    final constellation = hitTestConstellations(
      details.localPosition,
      _placed,
      _camera,
      _zoom,
      size,
    );
    if (constellation != null) _openConstellation(constellation.project);
  }

  Future<void> _openArea(LifeArea area) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AreaDetailScreen(
          area: area,
          areaVisionRepository: widget.areaVisionRepository,
          projectRepository: widget.projectRepository,
          starRepository: widget.starRepository,
        ),
      ),
    );
    _refresh();
  }

  Future<void> _openConstellation(Project project) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConstellationScreen(
          project: project,
          starRepository: widget.starRepository,
          projectRepository: widget.projectRepository,
          habitRepository: widget.habitRepository,
          habitCompletionRepository: widget.habitCompletionRepository,
          customConstellationRepository: widget.customConstellationRepository,
        ),
      ),
    );
    _refresh();
  }

  /// Opens the small centered dialog that flips [_showGridControl]/
  /// [_showZoomControl]/[_showRotationControl] — a `StatefulBuilder` wraps
  /// its own content so each switch's own animation plays immediately
  /// inside the dialog itself, rather than waiting on `SkyScreen`'s own
  /// next rebuild; [setState] is still called alongside it on every change
  /// so the sky behind the (translucent) dialog barrier actually shows/
  /// hides each control as you go, not just once the dialog is dismissed.
  Future<void> _showUiControlsMenu(BuildContext context) async {
    final colors = context.colors;
    final strings = context.strings;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setSheetState) {
            Widget row(String label, bool value, ValueChanged<bool> onChanged) {
              return SwitchListTile(
                title: Text(label, style: TextStyle(color: colors.text)),
                value: value,
                onChanged: (newValue) {
                  onChanged(newValue);
                  setSheetState(() {});
                },
              );
            }

            return AlertDialog(
              title: Text(
                'Display',
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  row(
                    'Grid',
                    _showGridControl,
                    (value) => setState(() => _showGridControl = value),
                  ),
                  row(
                    'Zoom',
                    _showZoomControl,
                    (value) => setState(() => _showZoomControl = value),
                  ),
                  // Omitted on mobile — see [isTouchOnlyMobile]: there's
                  // nothing to toggle when the roll knob itself never shows.
                  if (!isTouchOnlyMobile)
                    row(
                      'Rotation',
                      _showRotationControl,
                      (value) => setState(() => _showRotationControl = value),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(strings.closeAction),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    // See [isTouchOnlyMobile]'s own doc comment for why mobile drops this
    // regardless of the (still user-toggleable, for every other platform)
    // [_showRotationControl] preference.
    final showRotation = _showRotationControl && !isTouchOnlyMobile;

    return Scaffold(
      key: _scaffoldKey,
      // The sky is dragged edge to edge to look around, so the drawer must
      // never claim an edge-swipe of its own — it opens from its button and
      // nowhere else.
      drawerEdgeDragWidth: 0,
      drawer: SkyMenuDrawer(
        onLightAStar: _openStarForm,
        onNewConstellation: _openNewConstellation,
        onVisions: _openVisions,
        onShootingStars: _openShootingStars,
        onSearch: _openSearch,
        onStatistics: _openStatistics,
        onAdmire: _openAdmire,
        onFriends: _openFriends,
        onSettings: _openSettings,
        onMetaphor: _openMetaphor,
      ),
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
                showGrid: widget.settings.showGrid,
              ),
              // A decorative sigil behind each supernova — see
              // sky_area_sigils.dart. Painted before SkySupernova so that
              // widget's own glow/icon sit on top of it, not the other
              // way round.
              SkyAreaSigils(camera: _camera, zoom: _zoom),
              // Alternative takes on this slot, tried in order —
              // SkyDecorations (spiral nebula + supernova per area),
              // SkyWisps (wispy Hubble-style filaments), SkyBlackHole (a
              // lensed black hole) — all disabled in favor of SkySupernova
              // (one simple lens-flare-style star) while the visual style
              // is explored; swap which one's active here to compare, none
              // of the files are deleted.
              SkySupernova(camera: _camera, zoom: _zoom),
              AnimatedConstellationField(
                placed: _placed,
                camera: _camera,
                zoom: _zoom,
                flareProgram: _flareProgram,
                // See [kSkyStarPalette]: a white core with a gold glow
                // around it for anything burning, matching `SkySupernova`'s
                // own icons (a plain white glyph over a gold gradient
                // border/glow), and the blue/white families for everything
                // that isn't.
                palette: kSkyStarPalette,
                revision: _revision,
              ),
              // The way into everything that isn't the sky itself — same
              // disc/navy/gold styling as every other overlay control.
              // There's no nav bar left for it to duplicate: this button
              // *is* the app's navigation (or was, before the star FAB —
              // see [_showDrawerButton]).
              if (_showDrawerButton)
              Positioned(
                top: 0,
                left: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Material(
                      color: colors.nightPanel.withValues(alpha: 0.75),
                      shape: CircleBorder(
                        side: BorderSide(
                          color: colors.gold,
                          width: kBorderWidthActive,
                        ),
                      ),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: Tooltip(
                            message: strings.openMenuAction,
                            child: Icon(
                              Icons.menu,
                              color: colors.gold,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // The one overlay control with its colors inverted (solid
              // gold, dark text/icon) rather than the translucent navy disc
              // every other control uses — top-center and the most
              // prominent thing here on purpose, since it's the fastest way
              // off "wander and hope" navigation into the search popup.
              if (_showSearchButton)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(kRadiusField),
                          boxShadow: goldGlow(colors, strength: 1.1, size: 56),
                        ),
                        child: Material(
                        color: colors.gold,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kRadiusField),
                          // Dark navy rather than the gold every other
                          // control's border uses — this button's own fill
                          // is already gold, so a gold border would
                          // disappear into it.
                          side: BorderSide(
                            color: colors.night,
                            width: kBorderWidthActive,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(kRadiusField),
                          onTap: _openSearch,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search,
                                  color: colors.onGold,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  strings.searchButtonLabel,
                                  style: TextStyle(
                                    color: colors.onGold,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Always visible regardless of the three toggles below — it's
              // the only way back to turning them on again, so it can't be
              // one of the things it itself hides.
              if (_showUiControlsButton)
              Positioned(
                top: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Material(
                      color: colors.nightPanel.withValues(alpha: 0.75),
                      shape: CircleBorder(
                        side: BorderSide(
                          color: colors.gold,
                          width: kBorderWidthActive,
                        ),
                      ),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _showUiControlsMenu(context),
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: Icon(Icons.tune, color: colors.gold, size: 22),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // The three toggleable controls (Grid/Zoom/Rotation), left to
              // right along the bottom — one shared row rather than three
              // independently-positioned corners, so [FittedBox] can shrink
              // all three together (never grow them past their natural
              // size) whenever a narrow screen can't fit them side by side
              // at full size; on anything wide enough, this is a no-op and
              // they render exactly as big as they'd otherwise be.
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (_showGridControl)
                              Material(
                                color: colors.nightPanel.withValues(alpha: 0.75),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    _bottomPillRadius,
                                  ),
                                  side: BorderSide(
                                    color: colors.gold,
                                    width: kBorderWidthActive,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: SizedBox(
                                    height: _bottomPillHeight,
                                    child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Grid',
                                        style: TextStyle(
                                          color: colors.muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                      // Scaled down 20% along with the other
                                      // two sky-overlay controls (see
                                      // [_RollKnob]/[_ZoomSlider]'s own
                                      // sizing) — Switch has no size
                                      // parameter of its own, so this is the
                                      // plain way to shrink it without
                                      // losing its built-in tap/thumb-
                                      // animation behavior.
                                      // Colors come from the app's own
                                      // switch theme, same as every other
                                      // switch; only the 20% shrink is
                                      // local, matching the other two
                                      // sky-overlay controls' sizing.
                                      Transform.scale(
                                        scale: 0.8,
                                        child: Switch(
                                          value: widget.settings.showGrid,
                                          onChanged: (value) {
                                            widget.settings.setShowGrid(value);
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                    ],
                                    ),
                                  ),
                                ),
                              ),
                            if (_showGridControl &&
                                (_showZoomControl || showRotation))
                              const SizedBox(width: 12),
                            if (_showZoomControl)
                              _ZoomSlider(
                                zoom: _zoom,
                                minZoom: minZoomWithoutRepeats,
                                maxZoom: _maxZoom,
                                onChanged: (value) {
                                  _stopInertia();
                                  _flyController.stop();
                                  setState(() => _zoom = value);
                                },
                              ),
                            if (_showZoomControl && showRotation)
                              const SizedBox(width: 12),
                            // Touch already has its own two-finger rotate
                            // gesture (see `_handleScaleUpdate`'s
                            // `details.rotation`), which is exactly why this
                            // knob is hidden outright on mobile (see
                            // [isTouchOnlyMobile]) — kept on desktop/web,
                            // where there's no such gesture without it, and
                            // still user-toggleable there via
                            // [_showUiControlsMenu].
                            if (showRotation)
                              _RollKnob(
                                angle: cameraRollAngle(_camera),
                                onRoll: (delta) {
                                  _stopInertia();
                                  _flyController.stop();
                                  setState(() => _camera = _camera.rolled(delta));
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // The star FAB — an alternative way into the same menu the
              // drawer opens (see [_openMenuModal]), tried alongside the
              // drawer rather than replacing it. Deliberately not a disc/
              // chrome control like every other overlay button here: no
              // filled background, just a glowing gold ring around a
              // white glyph — as close to [SkySupernova]'s own "white
              // glyph inside a gold ring, glowing outward" look as a
              // plain widget (no shader) can get, so it reads as one
              // more thing burning up there rather than as UI sitting on
              // top of it.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Center(
                      child: _MenuStarButton(onTap: _openMenuModal),
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

/// The FAB's own dedicated supernova — the same glow [SkySupernova] draws
/// for each life area (see `shaders/menu_star_button.frag`, a stripped
/// copy of `shaders/sky_supernova.frag` with the 3D camera projection
/// removed, since this one never moves: it always sits fixed right behind
/// the menu button, no area icon, no rotating sigil, nothing else that
/// belongs to a real supernova on the sky). [Icons.star] (the plain solid
/// star) sits on top, blended into the glow with [BlendMode.overlay] (see
/// [_MenuStarSupernovaPainter.paint]) rather than pasted flat on top of
/// it — [Icons.stars] was tried alongside it too, but turned out to *be*
/// a disc with a star-shaped hole cut out rather than a separate glyph,
/// so it's hidden now.
class _MenuStarButton extends StatefulWidget {
  const _MenuStarButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_MenuStarButton> createState() => _MenuStarButtonState();
}

class _MenuStarButtonState extends State<_MenuStarButton>
    with SingleTickerProviderStateMixin {
  // 2/3 of the previous (95) pass, rounded.
  static const _iconSize = 64.0;
  static const _tapTargetSize = 110.0;
  // Big enough that the shader's own glow/spikes fade out naturally well
  // before this canvas's own edge, rather than clipping hard against a
  // boundary that's part of the visible glow.
  static const _glowCanvasSize = _iconSize * 6;
  // The shader's own ring sits at a fixed 0.09 (world units, not pixels).
  // iconSize/(2*0.09) alone puts its diameter at exactly the icon's own
  // — the *0.85 pulls it in a little further, so the ring's own radius
  // (not diameter) lands right at the icon's edge instead of sitting
  // just outside it.
  static const _scale = _iconSize / (2 * 0.09) * 0.85;

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
      'shaders/menu_star_button.frag',
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

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: widget.onTap,
        child: SizedBox(
          width: _tapTargetSize,
          height: _tapTargetSize,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (shader != null)
                IgnorePointer(
                  child: SizedBox(
                    width: _glowCanvasSize,
                    height: _glowCanvasSize,
                    child: CustomPaint(
                      painter: _MenuStarSupernovaPainter(
                        shader: shader,
                        time:
                            _elapsed.inMicroseconds /
                            Duration.microsecondsPerSecond,
                        scale: _scale,
                        iconSize: _iconSize,
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

class _MenuStarSupernovaPainter extends CustomPainter {
  const _MenuStarSupernovaPainter({
    required this.shader,
    required this.time,
    required this.scale,
    required this.iconSize,
  });

  final ui.FragmentShader shader;
  final double time;
  final double scale;
  final double iconSize;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time)
      ..setFloat(3, scale);

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = shader
        ..blendMode = BlendMode.plus,
    );

    // The same "rotating decoration" [SkySupernova._paintOutlineIcon]
    // draws behind each life area's own icon: a blurred gradient stroke
    // of the glyph's own outline, spun around its center by an angle
    // that grows with [time] — a rotating *gradient*, not a rotating
    // shape, so the highlight travels around the star without the star
    // itself turning. What actually pulses here isn't brightness (see
    // [supernovaGlow]'s own much subtler breathing `pulse`, still there
    // underneath) but which edge of the glyph is lit.
    const glowGradientColors = [Color(0xFFFFEFA0), Color(0xFFF0C078)];
    void paintRotatingGlow() {
      final text = String.fromCharCode(Icons.star.codePoint);
      final center = Offset(size.width, size.height) / 2;
      final glowAngle = time * 2.2;
      final glowAxis =
          Offset(math.cos(glowAngle), math.sin(glowAngle)) * (iconSize / 2);
      final glowShader = ui.Gradient.linear(
        center - glowAxis,
        center + glowAxis,
        glowGradientColors,
      );
      final glowPainter = TextPainter(textDirection: TextDirection.ltr)
        ..text = TextSpan(
          text: text,
          style: TextStyle(
            fontSize: iconSize,
            fontFamily: Icons.star.fontFamily,
            package: Icons.star.fontPackage,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = iconSize * 0.08
              ..shader = glowShader
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, iconSize * 0.04),
          ),
        )
        ..layout();
      final topLeft =
          center - Offset(glowPainter.width, glowPainter.height) / 2;
      glowPainter.paint(canvas, topLeft);
    }

    // [Icons.stars] turned out to *be* a disc — a filled circle with a
    // star-shaped hole cut out, no separate star glyph inside it — so it
    // added nothing on top of this glow and stays hidden. Only
    // [Icons.star] (the plain solid star) is drawn, blended with the
    // glow via [BlendMode.overlay] rather than pasted flat on top of it.
    void paintIcon(IconData icon, double opacity) {
      final text = String.fromCharCode(icon.codePoint);
      final iconPainter = TextPainter(textDirection: TextDirection.ltr)
        ..text = TextSpan(
          text: text,
          style: TextStyle(
            fontSize: iconSize,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            foreground: Paint()
              ..color = Colors.white.withValues(alpha: opacity)
              ..blendMode = BlendMode.overlay,
          ),
        )
        ..layout();
      final topLeft =
          Offset(size.width, size.height) / 2 -
          Offset(iconPainter.width, iconPainter.height) / 2;
      iconPainter.paint(canvas, topLeft);
    }

    paintRotatingGlow();
    paintIcon(Icons.star, 0.8);
  }

  @override
  bool shouldRepaint(covariant _MenuStarSupernovaPainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.scale != scale ||
      oldDelegate.iconSize != iconSize;
}

/// A two-finger rotate gesture (see `_handleScaleUpdate`) is touch-only —
/// a mouse/trackpad has no equivalent, so desktop/web needs its own
/// control for the same [SkyCamera.rolled]; shown on phone too (see
/// `SkyScreen.build`'s own comment on why) rather than hardcoded off
/// there just because touch already has the gesture. Drag anywhere
/// around this dial (not just directly on the icon) and the
/// camera rolls by however far the angle around the dial's own center
/// changed since the last frame — same feel as spinning a real dial or a
/// ship's wheel, and exactly the same underlying rotation a phone's
/// pinch-rotate drives.
///
/// Styled to match the "Grid" switch as closely as a circular dial can:
/// the same translucent `colors.nightPanel` disc (not a solid fill), the
/// same gold `colors.gold` a `Switch` turns to when it's the thing you're
/// actively engaging with, rather than the app's usual gold everywhere or
/// a separate white-and-navy scheme of its own. The small dot orbiting
/// just outside its rim — see [angle] — is what actually shows how far
/// you've rolled, the way a map app's own small compass badge shows its
/// needle rather than just a plain icon; solid gold, no glow, so it stays
/// a crisp, precise readout rather than a soft blob.
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
  // 20% smaller than before, matching the same shrink applied to the
  // "Grid" switch and [_ZoomSlider] — frees up more of the sky for
  // constellations/navigation without losing any of these controls.
  static const _knobSize = 42.0;
  // Bigger than _knobSize so the indicator dot has room to orbit just
  // outside the knob's own rim without getting clipped.
  static const _boxSize = 62.0;
  static const _orbitRadius = _knobSize / 2 + 6;
  static const _dotSize = 8.0;

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
              child: Material(
                color: colors.nightPanel.withValues(alpha: 0.75),
                shape: CircleBorder(
                  side: BorderSide(
                    color: colors.gold,
                    width: kBorderWidthActive,
                  ),
                ),
                child: SizedBox(
                  width: _knobSize,
                  height: _knobSize,
                  child: Icon(Icons.threesixty, color: colors.gold, size: 22),
                ),
              ),
            ),
          ),
          Positioned(
            left: dotCenter.dx - _dotSize / 2,
            top: dotCenter.dy - _dotSize / 2,
            child: DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, color: colors.gold),
              child: SizedBox(width: _dotSize, height: _dotSize),
            ),
          ),
        ],
      ),
    );
  }
}

/// A dedicated zoom control alongside the pinch/scroll-wheel gestures
/// `SkyScreen` already handles — styled like the "Grid" switch, same
/// as [_RollKnob]: the translucent `colors.nightPanel` pill, a muted
/// "Zoom" caption the same way "Grid" labels its own switch, and gold
/// (`colors.gold`) wherever the switch itself would turn gold — the
/// active track/thumb and the percentage readout, since that's the part
/// actually being engaged with. Always shown on both phone and web
/// (unlike the roll knob, which only covers a gap touch itself already
/// fills). A plain horizontal [Slider], the "Zoom" caption at its zoomed-
/// out (min) end and the percentage readout at its zoomed-in (max) end —
/// bottom-center alongside the Grid switch and roll knob (see
/// `SkyScreen.build`'s shared [FittedBox] row) rather than its own
/// rotated-on-its-side rail off to the right.
///
/// Mapped through `math.log` rather than [zoom] itself: zoom is
/// inherently multiplicative (min to max is a 100x span — see
/// `NebulaScreen._maxZoom`'s own doc comment), so a slider driven by the
/// raw value would spend almost its entire length on just the bottom
/// sliver of that range and leave the rest of the track meaningless — the
/// log scale is what makes the thumb's position actually track how
/// "zoomed in" the view feels.
class _ZoomSlider extends StatelessWidget {
  const _ZoomSlider({
    required this.zoom,
    required this.minZoom,
    required this.maxZoom,
    required this.onChanged,
  });

  final double zoom;
  final double minZoom;
  final double maxZoom;
  final ValueChanged<double> onChanged;

  static const _trackLength = 120.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final logMin = math.log(minZoom);
    final logMax = math.log(maxZoom);
    final logValue = math.log(zoom).clamp(logMin, logMax).toDouble();
    final percent = (((logValue - logMin) / (logMax - logMin)) * 100).round();

    return Material(
      color: colors.nightPanel.withValues(alpha: 0.75),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_bottomPillRadius),
        side: BorderSide(color: colors.gold, width: kBorderWidthActive),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          height: _bottomPillHeight,
          child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Zoom', style: TextStyle(color: colors.muted, fontSize: 12)),
            const SizedBox(width: 8),
            SizedBox(
              width: _trackLength,
              height: 24,
              child: SliderTheme(
                // Only the track height and the dimmer inactive track are
                // local: this slider sits on the sky itself, where the
                // app's own navy track would vanish into the background.
                data: SliderTheme.of(context).copyWith(
                  inactiveTrackColor: colors.muted.withValues(alpha: 0.35),
                  trackHeight: 3,
                ),
                child: Slider(
                  min: logMin,
                  max: logMax,
                  value: logValue,
                  onChanged: (value) => onChanged(math.exp(value)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Fixed width (enough for "100%", the widest this ever reads)
            // rather than sizing to the current text — otherwise the whole
            // pill (and everything sharing its row) subtly resizes as the
            // digit count changes while dragging.
            SizedBox(
              width: 34,
              child: Text(
                '$percent%',
                textAlign: TextAlign.right,
                // Belt-and-braces alongside the fixed width above: forces
                // exactly one line regardless of how tight that width is,
                // so "100%" (the one value with 3 digits) can never wrap
                // its "%" onto a second line and grow this pill taller
                // than the Grid switch sharing its row.
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  color: colors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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
