import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:share_plus/share_plus.dart';

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
import '../models/star.dart';
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
import '../widgets/shareable_lit_star_card.dart';
import '../widgets/sky_area_sigils.dart';
import '../widgets/sky_menu_drawer.dart';
import '../widgets/sky_navigation_target.dart';
import '../widgets/sky_supernova.dart';
import '../widgets/star_quick_look_panel.dart';
import 'admire_stars_screen.dart';
import 'area_detail_screen.dart';
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

  /// The three fly-to zoom levels — one per kind of sky element a tap can
  /// land on, each its own independently tunable number (see
  /// [zoomPercent]'s 0..100 scale) rather than one shared value or a
  /// per-content zoom-to-fit formula, so each can be dialed in on its own.
  /// Ascending, matching the funnel a tap chain actually walks down:
  /// supernova -> constellation -> star, each landing closer than the last.
  ///
  /// [_constellationZoomPercent] doubles as [_starTapMinZoomPercent] (see
  /// its own doc comment) on purpose — arriving at a constellation should
  /// leave its stars individually tappable immediately, not require an
  /// extra manual zoom in first.
  static const _areaZoomPercent = 35.0;
  static const _constellationZoomPercent = 75.0;
  static const _starZoomPercent = 95.0;

  /// How far back one double-tap-to-zoom-out (see [_handleTapUp]'s own
  /// manual double-tap tracking and [_zoomOutOneLevel]) steps: below
  /// [_areaZoomPercent] there's no fourth named level to retreat to, so it
  /// drops all the way to the sky's own default "furthest comfortable"
  /// zoom instead of a fourth magic number.
  static const _zoomOutFloorPercent = 0.0;

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

  /// Which star (if any) is showing its quick-look panel right now — set
  /// by [_openStar] for a genuine star (not a pulsar, not a still-nascent
  /// slot; both keep their own existing tap flow), alongside a
  /// [_flyTo] that lands it in the screen's top half rather than opening
  /// [StarReaderScreen] immediately. Both null together; see
  /// [_quickLookStar] for the actual [Star] this resolves to.
  PlacedConstellation? _quickLookConstellation;
  int? _quickLookStarIndex;
  final _quickLookShareKey = GlobalKey();
  bool _sharingQuickLookStar = false;

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

  /// Off for now so the star tap's own camera movement (see
  /// [_openStarQuickLook]) can be tuned on its own, without the panel's
  /// layout/behavior in the way while doing that — not deleted, the panel
  /// itself is otherwise unchanged.
  static const bool _showStarQuickLookPanel = false;

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
    _flyController = AnimationController(
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
    _openStarQuickLook(constellation, index, star);
  }

  /// Shows [constellation]'s star at [starIndex] in the quick-look panel
  /// (see [StarQuickLookPanel]) and flies the camera to it, dead center —
  /// same as every other "take me there" flight in the app (see
  /// `SkySearchScreen`'s own use of [_flyTo]). The full [StarReaderScreen]
  /// page is still just one tap away (see [_viewQuickLookStar]), not
  /// replaced.
  ///
  /// Flies to [renderStar]'s own exact position (via [starWorldPosition]),
  /// not [SkyStarTarget] — that only ever resolves to the *constellation's*
  /// shared anchor (see its own doc comment), so every star in the same
  /// constellation would fly to the identical spot; tapping a different
  /// star there wouldn't visibly move the camera at all, since it'd
  /// already be sitting at that same target from the previous tap.
  void _openStarQuickLook(
    PlacedConstellation constellation,
    int starIndex,
    ConstellationStar renderStar,
  ) {
    if (_showStarQuickLookPanel) {
      setState(() {
        _quickLookConstellation = constellation;
        _quickLookStarIndex = starIndex;
      });
    }
    final size = context.size;
    if (size == null) return;
    final world = starWorldPosition(
      constellation,
      renderStar,
      _camera,
      _zoom,
      size,
    );
    if (world == null) return;
    _flyToWorld(
      world,
      zoomFromPercent(_starZoomPercent).clamp(minZoomWithoutRepeats, _maxZoom),
    );
  }

  void _closeStarQuickLook() {
    setState(() {
      _quickLookConstellation = null;
      _quickLookStarIndex = null;
    });
  }

  /// The actual [Star] the quick-look panel is showing — re-read from
  /// [_quickLookConstellation] on every access (rather than cached
  /// separately) so an edit/achieve elsewhere that triggers [_refresh]
  /// never leaves the panel showing stale content.
  Star? get _quickLookStar {
    final constellation = _quickLookConstellation;
    final index = _quickLookStarIndex;
    if (constellation == null || index == null) return null;
    if (index >= constellation.stars.length) return null;
    return constellation.stars[index];
  }

  Future<void> _viewQuickLookStar() async {
    final constellation = _quickLookConstellation;
    final index = _quickLookStarIndex;
    if (constellation == null || index == null) return;
    _closeStarQuickLook();
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

  /// Mirrors `StarReaderScreen._editOrResurrectCurrent` exactly (same two
  /// branches, same repository calls) — just reached from the quick-look
  /// panel instead of the full reader page.
  Future<void> _editQuickLookStar() async {
    final constellation = _quickLookConstellation;
    final star = _quickLookStar;
    if (constellation == null || star == null) return;

    if (star.dead) {
      final result = await Navigator.of(context).push<Object>(
        MaterialPageRoute(
          builder: (_) => StarFormScreen(
            existingStar: star,
            contextProject: constellation.project,
            projectRepository: widget.projectRepository,
            customConstellationRepository: widget.customConstellationRepository,
            hideDelete: true,
          ),
        ),
      );
      if (result is! StarFormResult) return;
      await widget.starRepository.resurrect(
        star.id,
        title: result.title,
        description: result.description,
        projectId: result.projectId,
        targetDate: result.targetDate,
        achievedDate: result.achievedDate,
        intensity: result.intensity,
        photoPath: result.photoPath,
      );
      _closeStarQuickLook();
      _refresh();
      return;
    }

    final result = await Navigator.of(context).push<Object>(
      MaterialPageRoute(
        builder: (_) => StarFormScreen(
          existingStar: star,
          contextProject: constellation.project,
          projectRepository: widget.projectRepository,
          customConstellationRepository: widget.customConstellationRepository,
        ),
      ),
    );
    if (result == null) return;

    if (result is StarFormDeleteRequested) {
      await widget.starRepository.delete(star.id);
      _closeStarQuickLook();
      _refresh();
      return;
    }

    final addResult = result as StarFormResult;
    await widget.starRepository.update(
      id: star.id,
      title: addResult.title,
      description: addResult.description,
      projectId: addResult.projectId,
      targetDate: addResult.targetDate,
      achievedDate: addResult.achievedDate,
      intensity: addResult.intensity,
      photoPath: addResult.photoPath,
    );
    _closeStarQuickLook();
    _refresh();
  }

  Future<void> _deleteQuickLookStar() async {
    final star = _quickLookStar;
    if (star == null) return;
    final strings = context.strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.deleteStarConfirmTitle),
        content: Text(strings.deleteStarConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.deleteStarAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.starRepository.delete(star.id);
    _closeStarQuickLook();
    _refresh();
  }

  /// Mirrors `StarReaderScreen._shareCurrent` exactly (same
  /// [RenderRepaintBoundary] capture, same [SharePlus] call) — captures
  /// [_quickLookShareKey], which wraps a [ShareableLitStarCard] rendered
  /// far off-screen (see the `build` Stack) purely so it exists to
  /// capture; only ever reachable when [_quickLookStar] is lit (see
  /// [StarQuickLookPanel]'s own `onShare`, null otherwise).
  Future<void> _shareQuickLookStar() async {
    final star = _quickLookStar;
    if (star == null || !star.isLit || _sharingQuickLookStar) return;
    setState(() => _sharingQuickLookStar = true);
    try {
      final boundary =
          _quickLookShareKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(
        pixelRatio: MediaQuery.of(context).devicePixelRatio,
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw StateError('toByteData returned null');
      if (!mounted) return;
      final shareFile = XFile.fromData(
        byteData.buffer.asUint8List(),
        name: 'star_${DateTime.now().microsecondsSinceEpoch}.png',
        mimeType: 'image/png',
      );
      await SharePlus.instance.share(
        ShareParams(files: [shareFile], text: star.title),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.strings.shareStarError)));
      }
    } finally {
      if (mounted) setState(() => _sharingQuickLookStar = false);
    }
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
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ShootingStarsScreen()));
  }

  void _openFriends() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const FriendsScreen()));
  }

  void _openMetaphor() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const MetaphorScreen()));
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
      // [SkyMenuModalFrame] draws its own background/shape/handle and
      // handles its own drag-to-dismiss (see its own doc comment for
      // why) — turned off here so [BottomSheet]'s own versions of all
      // three don't render or compete underneath it.
      backgroundColor: Colors.transparent,
      elevation: 0,
      enableDrag: false,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      builder: (_) => SkyMenuModalFrame(
        builder: (scrollController, physics) => SkyMenuContent(
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
          scrollController: scrollController,
          physics: physics,
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

  /// The zoom [_flyTo] should land [target] at — see [_areaZoomPercent]/
  /// [_constellationZoomPercent]/[_starZoomPercent]'s own doc comment for
  /// why each is its own fixed level rather than a per-content
  /// zoom-to-fit formula.
  double _zoomFor(SkyNavigationTarget target, Size screenSize) {
    final percent = switch (target) {
      SkyAreaTarget() => _areaZoomPercent,
      SkyProjectTarget() => _constellationZoomPercent,
      SkyStarTarget() => _starZoomPercent,
    };
    return zoomFromPercent(percent).clamp(minZoomWithoutRepeats, _maxZoom);
  }

  /// Flies the camera to [target]'s spot on the sky sphere — dead center by
  /// default (see [SkyCamera.lookingAt]), zoomed per [_zoomFor]. Animated as
  /// one smooth sweep along the great circle from wherever the camera
  /// currently looks (see [SkyCamera.rotatedToAlignFraction]), Maps-style,
  /// rather than an instant cut — [_onFlyTick] drives it every frame.
  ///
  /// [anchorFraction] moves where [target] ends up landing on screen —
  /// (0.5, 0.5) (the default) is dead center; (0.5, 0.25) is what the star
  /// quick-look panel uses to land its star in the middle of the screen's
  /// top half rather than behind the panel covering the bottom half. Found
  /// via [screenToDirection]/[SkyCamera.rotatedToAlign] rather than a
  /// simplified pixel-offset: aim a camera dead-center at [target] first
  /// (`baseCamera`, forward == target's own direction, by construction),
  /// then rotate so whatever direction *would* render at [anchorFraction]
  /// under `baseCamera` instead renders at dead center — the same rotation
  /// forces [target] itself to land at [anchorFraction] instead (the two
  /// are the same rotation run in the two directions a single-axis
  /// alignment always is).
  void _flyTo(
    SkyNavigationTarget target, {
    Offset anchorFraction = const Offset(0.5, 0.5),
  }) {
    final size = context.size;
    if (size == null) return;
    final world = _worldFor(target);
    if (world == null) return;
    _flyToWorld(world, _zoomFor(target, size), anchorFraction: anchorFraction);
  }

  /// The actual flight, once a target has already been resolved to a
  /// world (azimuth, elevation) position and a zoom — split out from
  /// [_flyTo] so [_openStarQuickLook] can fly to a *specific star's* own
  /// exact position (see [starWorldPosition]) rather than [SkyStarTarget]'s
  /// coarser "somewhere in its constellation".
  void _flyToWorld(
    Offset world,
    double targetZoom, {
    Offset anchorFraction = const Offset(0.5, 0.5),
  }) {
    final size = context.size;
    if (size == null) return;

    final baseCamera = SkyCamera.lookingAt(
      azimuthTurns: world.dx,
      elevationTurns: world.dy,
    );

    var targetForward = baseCamera.forward;
    if (anchorFraction != const Offset(0.5, 0.5)) {
      final anchorPoint = Offset(
        size.width * anchorFraction.dx,
        size.height * anchorFraction.dy,
      );
      final anchorDirection = screenToDirection(
        anchorPoint,
        baseCamera,
        targetZoom,
        size,
      );
      targetForward = baseCamera
          .rotatedToAlign(anchorDirection, baseCamera.forward)
          .forward;
    }

    _stopInertia();
    _flyStartCamera = _camera;
    _flyTargetForward = targetForward;
    _flyStartZoom = _zoom;
    _flyTargetZoom = targetZoom;
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
      if (size != null &&
          size.height > 0 &&
          startCamera != null &&
          anchor != null) {
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
        _camera = startCamera
            .rotatedToAlign(current, anchor)
            .rolled(details.rotation);
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
        details.velocity.pixelsPerSecond /
        size.height /
        _zoom *
        _panSensitivity;
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
  /// See [_constellationZoomPercent]'s own doc comment for why this is
  /// that same value, not its own separate number.
  static const _starTapMinZoomPercent = _constellationZoomPercent;

  /// When and where the last tap that landed on *empty* sky happened —
  /// [_handleTapUp]'s own manual double-tap tracking, purely for
  /// [_zoomOutOneLevel]'s "double-tap empty sky to back out" gesture. Null
  /// whenever there's no such tap still eligible to be the first half of
  /// a double-tap.
  ///
  /// Deliberately not a real [GestureDetector.onDoubleTap] — registering
  /// one on the same detector as [onTapUp] would force *every* single tap
  /// (stars and constellations included) to wait out Flutter's own
  /// double-tap disambiguation window before firing at all, which read as
  /// a real, unwelcome lag on the app's single most common gesture. Empty
  /// sky is the only place a double-tap does anything, so tracking it by
  /// hand here — two plain taps close together in time and position, ordinary
  /// [onTapUp] firing immediately both times — gets the same gesture with
  /// no delay on everything else.
  DateTime? _lastEmptyTapTime;
  Offset? _lastEmptyTapPosition;

  static const _doubleTapWindow = Duration(milliseconds: 300);
  static const _doubleTapMaxDistance = 40.0;

  void _handleTapUp(TapUpDetails details) {
    final size = context.size;
    if (size == null) return;
    final hit = zoomPercent(_zoom) >= _starTapMinZoomPercent
        ? hitTestField(details.localPosition, _placed, _camera, _zoom, size)
        : null;
    if (hit != null) {
      _lastEmptyTapTime = null;
      _openStar(hit.$1, hit.$2);
      return;
    }
    // An invisible zone over each supernova's own icon — no visible change
    // to `SkySupernova`'s artwork, just the same tap-to-open-detail
    // behavior the Galaxy search popup's own Supernovas cards already have
    // (see [hitTestSupernovas]).
    final area = hitTestSupernovas(details.localPosition, _camera, _zoom, size);
    if (area != null) {
      _lastEmptyTapTime = null;
      _flyToArea(area);
      return;
    }
    // Same idea one level down: a tap that lands within a constellation's
    // own shape but not precisely on one of its stars (already handled
    // above) — see [hitTestConstellations].
    final constellation = hitTestConstellations(
      details.localPosition,
      _placed,
      _camera,
      _zoom,
      size,
    );
    if (constellation != null) {
      _lastEmptyTapTime = null;
      _flyToConstellation(constellation.project);
      return;
    }

    // Empty sky — see if this completes a double-tap with the previous
    // empty-sky tap (see [_lastEmptyTapTime]'s own doc comment).
    final now = DateTime.now();
    final lastTime = _lastEmptyTapTime;
    final lastPosition = _lastEmptyTapPosition;
    if (lastTime != null &&
        lastPosition != null &&
        now.difference(lastTime) < _doubleTapWindow &&
        (details.localPosition - lastPosition).distance < _doubleTapMaxDistance) {
      _lastEmptyTapTime = null;
      _lastEmptyTapPosition = null;
      _zoomOutOneLevel();
      return;
    }
    _lastEmptyTapTime = now;
    _lastEmptyTapPosition = details.localPosition;
  }

  /// Just the camera movement, dead center — same "take me there" flight
  /// every other target in the app gets, with no page opening behind it
  /// any more: a tap on a supernova used to push [AreaDetailScreen]
  /// straight away, which is removed here on purpose, not a screen
  /// [AreaDetailScreen] itself lost — it's still reachable from wherever
  /// it already was (e.g. the Galaxy search popup).
  void _flyToArea(LifeArea area) {
    _flyTo(SkyAreaTarget(area));
  }

  /// See [_flyToArea]'s own note — same change, for constellations.
  void _flyToConstellation(Project project) {
    _flyTo(SkyProjectTarget(project));
  }

  /// Steps back one rung of the [_areaZoomPercent]/
  /// [_constellationZoomPercent]/[_starZoomPercent] ladder from wherever
  /// [_zoom] currently sits — the largest rung strictly below it, or
  /// [_zoomOutFloorPercent] once already at or below the lowest one.
  /// Orientation is left exactly as it is; only zoom moves (see [_zoomTo]).
  void _zoomOutOneLevel() {
    const rungs = [
      _zoomOutFloorPercent,
      _areaZoomPercent,
      _constellationZoomPercent,
      _starZoomPercent,
    ];
    final currentPercent = zoomPercent(_zoom);
    var target = _zoomOutFloorPercent;
    for (final rung in rungs) {
      // A tiny margin below the current reading — without it, being
      // already sitting *exactly* on a rung (the usual case, having just
      // flown to one) would count that same rung as "below" itself due to
      // ordinary floating-point noise, and go nowhere.
      if (rung < currentPercent - 0.5) target = rung;
    }
    _zoomTo(zoomFromPercent(target).clamp(minZoomWithoutRepeats, _maxZoom));
  }

  /// Animates [_zoom] alone to [targetZoom], camera orientation
  /// unchanged — the zoom-only half of what [_flyToWorld] does, without
  /// its azimuth/elevation round-trip (there's no new direction to aim
  /// at here, just [_camera]'s own current one, exactly).
  void _zoomTo(double targetZoom) {
    _stopInertia();
    _flyStartCamera = _camera;
    _flyTargetForward = _camera.forward;
    _flyStartZoom = _zoom;
    _flyTargetZoom = targetZoom;
    _flyController
      ..stop()
      ..reset()
      ..forward();
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

    return PopScope(
      // The quick-look panel isn't a route of its own — a back gesture/
      // button with it open should close it (same as tapping its own X)
      // rather than leaving the sky screen entirely.
      canPop: _quickLookConstellation == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeStarQuickLook();
      },
      child: Scaffold(
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
        body: Stack(
          children: [
            Listener(
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
                                onTap: () =>
                                    _scaffoldKey.currentState?.openDrawer(),
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
                                  borderRadius: BorderRadius.circular(
                                    kRadiusField,
                                  ),
                                  boxShadow: goldGlow(
                                    colors,
                                    strength: 1.1,
                                    size: 56,
                                  ),
                                ),
                                child: Material(
                                  color: colors.gold,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      kRadiusField,
                                    ),
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
                                    borderRadius: BorderRadius.circular(
                                      kRadiusField,
                                    ),
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
                                  child: Icon(
                                    Icons.tune,
                                    color: colors.gold,
                                    size: 22,
                                  ),
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
                                      color: colors.nightPanel.withValues(
                                        alpha: 0.75,
                                      ),
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
                                        padding: const EdgeInsets.only(
                                          left: 10,
                                        ),
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
                                                  value:
                                                      widget.settings.showGrid,
                                                  onChanged: (value) {
                                                    widget.settings.setShowGrid(
                                                      value,
                                                    );
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
                                        setState(
                                          () => _camera = _camera.rolled(delta),
                                        );
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
            // A lit star's quick-look panel needs a real [ShareableLitStarCard]
            // laid out (not just described) somewhere to capture — see
            // [_shareQuickLookStar] — rendered here, far to the side, so it's
            // never actually visible: [Opacity] would skip painting it
            // entirely at 0, which [RenderRepaintBoundary.toImage] needs to
            // have happened at least once, so an off-screen [Positioned] is
            // used instead.
            if (_quickLookStar case final star? when star.isLit)
              Positioned(
                left: -MediaQuery.sizeOf(context).width * 2,
                top: 0,
                width: MediaQuery.sizeOf(context).width,
                height: MediaQuery.sizeOf(context).height,
                child: RepaintBoundary(
                  key: _quickLookShareKey,
                  child: ShareableLitStarCard(
                    star: star,
                    project: _quickLookConstellation?.project,
                  ),
                ),
              ),
            // The quick-look panel itself — bottom half of the screen (see
            // [_flyTo]'s own `anchorFraction` in [_openStarQuickLook], which
            // lands the star in the top half to match), sliding in/out as
            // [_quickLookStar] appears/disappears rather than popping a whole
            // new route, so the sky stays visible (and its camera fly-to
            // still animates) behind it.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: MediaQuery.sizeOf(context).height * 0.5,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                offset: _quickLookStar == null
                    ? const Offset(0, 1)
                    : Offset.zero,
                child: _buildQuickLookPanel(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// [AnimatedSlide]'s own `offset` keeps this mounted the whole time (it's
  /// what slides), so this can't just be `if (star != null) ... else
  /// SizedBox.shrink()` inline in a collection literal — [_quickLookStar]
  /// still has to resolve to *some* widget either way, hence a real method
  /// rather than a collection `if`.
  Widget _buildQuickLookPanel() {
    final star = _quickLookStar;
    if (star == null) return const SizedBox.shrink();
    return StarQuickLookPanel(
      star: star,
      project: _quickLookConstellation?.project,
      onClose: _closeStarQuickLook,
      onView: _viewQuickLookStar,
      onEdit: _editQuickLookStar,
      onShare: star.isLit ? _shareQuickLookStar : null,
      onDelete: star.dead ? null : _deleteQuickLookStar,
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
    with TickerProviderStateMixin {
  // 2/3 of the previous (95) pass, rounded, nudged down slightly again.
  // Still what the ring/glow/canvas below size themselves off of — see
  // [_starGlyphSize] for the star glyph's own, now-separate size.
  static const _iconSize = 58.0;
  // The star glyph itself, slightly smaller again than [_iconSize] —
  // split out from it on purpose: shrinking [_iconSize] directly would
  // have pulled the ring in to match too (see [_scale] below, sized off
  // [_iconSize]), when only the star itself was asked to shrink this
  // time.
  static const _starGlyphSize = _iconSize * 0.9;
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
  // The white ring + white star glyph [_MenuStarSupernovaPainter] used
  // to draw on top of the shader's own glow are swapped out for the
  // app's actual logo below, while a couple of looks are being compared
  // — off rather than deleted, so flipping it back to true restores
  // them exactly as they were.
  static const _showStarRingIcon = false;
  // The same disc already used at the top of the menu (see
  // [SkyMenuContent._logoAsset]) at that exact same size, but with its
  // gold ring/disc recolored to white — a plain asset swap (see
  // assets/icon/app_icon_ring_centered_white.png) rather than a runtime
  // tint. The header keeps the original gold version.
  static const _logoAsset = 'assets/icon/app_icon_ring_centered_white.png';
  static const _logoSize = 72.0;
  // Drawn into the same canvas as the shader's own glow (see
  // [_MenuStarSupernovaPainter.paint]) at this alpha, with plain normal
  // (srcOver) blending — [BlendMode.overlay] was tried first (see the
  // gallery in `MenuButtonGalleryScreen`) but read as too washed-out;
  // normal blending at 100% keeps the logo solid white instead.
  static const _logoOverlayOpacity = 1.0;
  // The "MENU" caption under the button, off for now — not deleted, see
  // [_showStarRingIcon] just above for the same pattern.
  static const _showMenuLabel = false;
  // Short enough that a deliberate hold doesn't feel like it's waiting on
  // anything, long enough that a stray touch while panning/zooming the
  // sky underneath this button has a real window to read as "not
  // actually a hold on this" before the menu opens.
  static const _chargeDuration = Duration(milliseconds: 500);

  ui.FragmentShader? _shader;
  // Decoded once and kept around rather than reloaded every frame — drawn
  // straight into [_MenuStarSupernovaPainter]'s own canvas (see
  // [paintLogo]) rather than as an [Image] widget, so it can share that
  // canvas's own blend-mode-against-the-glow treatment the same way the
  // star glyph it replaced did.
  ui.Image? _logoImage;
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;
  // A press doesn't open the menu itself — it charges this for as long
  // as the finger stays down, and the menu only opens once it reaches
  // 1.0 (see the status listener in initState); let go early and it
  // reverses back to 0 instead of firing. Its own value, read straight
  // in build() below (already rebuilding every frame off [_ticker]), is
  // what drives `supernovaGlow`'s own [chargeGlow].
  late final AnimationController _chargeController;
  // Shown briefly whenever a press lets go before the charge completes
  // — a plain tap reads as "nothing happened" otherwise, with no clue
  // that holding is what this button actually wants. Visible for
  // [_hintVisibleDuration], then faded out quickly (see the
  // AnimatedOpacity in build()) rather than lingering.
  bool _showHoldHint = false;
  Timer? _hintTimer;
  static const _hintVisibleDuration = Duration(milliseconds: 1100);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) => setState(() => _elapsed = elapsed))
      ..start();
    _chargeController =
        AnimationController(vsync: this, duration: _chargeDuration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _chargeController.reset();
              widget.onTap();
            }
          });
    _loadShader();
    _loadLogoImage();
  }

  Future<void> _loadShader() async {
    final program = await ui.FragmentProgram.fromAsset(
      'shaders/menu_star_button.frag',
    );
    if (!mounted) return;
    setState(() => _shader = program.fragmentShader());
  }

  Future<void> _loadLogoImage() async {
    final bytes = await rootBundle.load(_logoAsset);
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() => _logoImage = frame.image);
  }

  void _handlePressStart() {
    _chargeController.forward();
  }

  // Shared by both onTapUp (a genuine release) and onTapCancel (the
  // gesture arena handing this touch to something else, e.g. a pan
  // starting on top of this button) — either way, letting go before
  // reaching 1.0 backs the charge off rather than leaving it stuck
  // wherever it was, and is also exactly when the hint below is worth
  // showing — the press genuinely wasn't held long enough to open
  // anything.
  void _handlePressEnd() {
    if (_chargeController.status == AnimationStatus.forward) {
      _chargeController.reverse();
      _hintTimer?.cancel();
      setState(() => _showHoldHint = true);
      _hintTimer = Timer(_hintVisibleDuration, () {
        if (mounted) setState(() => _showHoldHint = false);
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _chargeController.dispose();
    _hintTimer?.cancel();
    _shader?.dispose();
    _logoImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shader = _shader;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [_buildButtonAndLabel(shader)],
        ),
        // Floating above the button via [Positioned] rather than
        // sitting in the Column's own flow — appearing/disappearing
        // shouldn't nudge the button or the MENU label up and down
        // every time it toggles.
        Positioned(
          top: -30,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _showHoldHint ? 1.0 : 0.0,
              // Fades in a little slower than it fades out — matches
              // asking for it to *disappear* "molto velocemente"
              // specifically, not necessarily appear that fast too.
              duration: Duration(milliseconds: _showHoldHint ? 200 : 120),
              child: Text(
                context.strings.menuButtonHoldHint.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                  shadows: [
                    Shadow(color: Color(0xFF6E8CD8), blurRadius: 6),
                    Shadow(color: Color(0xFF6E8CD8), blurRadius: 14),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtonAndLabel(ui.FragmentShader? shader) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            // The real logic lives in onTapDown/onTapUp/onTapCancel
            // below — [onTap] itself stays a no-op, kept only because
            // InkWell needs at least one tap handler set to wire up its
            // tap recognizer at all (so onTapDown/onTapUp/onTapCancel
            // actually fire).
            onTap: () {},
            onTapDown: (_) => _handlePressStart(),
            onTapUp: (_) => _handlePressEnd(),
            onTapCancel: _handlePressEnd,
            // No ripple/highlight of its own — [supernovaGlow]'s own
            // [chargeGlow] is the only feedback a press gets here;
            // Android's default translucent disc underneath would just
            // double up on it, off-center from the actual glow and in
            // a flat white that doesn't match.
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            child: SizedBox(
              width: _tapTargetSize,
              height: _tapTargetSize,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (shader != null)
                    IgnorePointer(
                      // A plain [SizedBox] here doesn't actually work:
                      // this sits inside a Stack that's inside a tight
                      // 110x110 SizedBox, and Stack's own
                      // StackFit.loose only loosens the *minimum* it
                      // passes to non-positioned children — the maximum
                      // stays 110, so a 384x384 SizedBox got silently
                      // clamped down to 110x110 despite the Stack's own
                      // `clipBehavior: Clip.none` (nothing was ever
                      // actually laid out bigger, so there was nothing
                      // to overflow). [OverflowBox] overrides its
                      // child's constraints outright, regardless of
                      // what it itself was given, which is what
                      // actually lets this canvas be bigger than the
                      // tap target around it.
                      child: OverflowBox(
                        minWidth: _glowCanvasSize,
                        maxWidth: _glowCanvasSize,
                        minHeight: _glowCanvasSize,
                        maxHeight: _glowCanvasSize,
                        child: CustomPaint(
                          painter: _MenuStarSupernovaPainter(
                            shader: shader,
                            time:
                                _elapsed.inMicroseconds /
                                Duration.microsecondsPerSecond,
                            scale: _scale,
                            starGlyphSize: _starGlyphSize,
                            charge: _chargeController.value,
                            showStarAndRing: _showStarRingIcon,
                            logoImage: _showStarRingIcon ? null : _logoImage,
                            logoSize: _logoSize,
                            logoOpacity: _logoOverlayOpacity,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // Just a plain caption — makes it clear at a glance that this
        // is a menu button, not another life-area supernova or a
        // decoration; deliberately small and secondary next to the
        // button itself, not competing with it. The two stacked
        // [Shadow]s are the same blue as the button's own glow — a
        // tight one for a bright core right against the letters, a
        // wide, soft one behind that — so the caption reads as lit by
        // the same light rather than just sitting near it.
        //
        // Pulled up with a negative [Transform.translate] rather than
        // just a smaller/zero gap above — the Column still reserves the
        // gap-less layout space below the button first, then this
        // shifts purely the *painted* position up into it, closer than
        // a real layout gap could go without the button and caption
        // starting to overlap in hit-testing too.
        if (_showMenuLabel)
          Transform.translate(
            offset: const Offset(0, -15),
            child: Text(
              // Reuses [openMenuAction] (already the localized "Menu",
              // used elsewhere as this same button's tooltip) rather than
              // a second, separate string for the same word — just
              // uppercased here to match this caption's own small-caps
              // styling, which the tooltip text doesn't need.
              context.strings.openMenuAction.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(color: Color(0xFF6E8CD8), blurRadius: 6),
                  Shadow(color: Color(0xFF6E8CD8), blurRadius: 18),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MenuStarSupernovaPainter extends CustomPainter {
  const _MenuStarSupernovaPainter({
    required this.shader,
    required this.time,
    required this.scale,
    required this.starGlyphSize,
    required this.charge,
    required this.showStarAndRing,
    required this.logoImage,
    required this.logoSize,
    required this.logoOpacity,
  });

  final ui.FragmentShader shader;
  final double time;
  final double scale;
  // The star glyph's own rendered size — deliberately not tied to
  // [scale] (which the ring/glow canvas size off of instead), so the
  // star can be resized on its own without dragging the ring along.
  final double starGlyphSize;
  // 0..1 — see `_MenuStarButtonState._chargeController`.
  final double charge;
  // See `_MenuStarButtonState._showStarRingIcon` — the shader's own
  // additive glow (drawn above, before this flag is even checked) always
  // stays; only the white ring + white star glyph below it are gated by
  // this, in favor of the app's own logo drawn on top instead.
  final bool showStarAndRing;
  // Null while the asset is still decoding, or while [showStarAndRing]
  // is true (the older ring+star look, with no logo to draw) — see
  // `_MenuStarButtonState._loadLogoImage`.
  final ui.Image? logoImage;
  // Matches [SkyMenuContent]'s own header logo size.
  final double logoSize;
  // See `_MenuStarButtonState._logoOverlayOpacity`.
  final double logoOpacity;

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

    // Tried, disabled: the same "rotating decoration"
    // [SkySupernova._paintOutlineIcon] draws behind each life area's own
    // icon — a blurred gradient stroke of the glyph's own outline, spun
    // around its center. That's exactly the problem here: it's a glow
    // that traces the star's own contour, and on this much smaller
    // button it just read as the star having its own outline glow
    // rather than a separate decoration — see [paintRing] below and
    // `supernovaGlow`'s own [nearGlow] for the shapeless central glow
    // that replaced it instead.
    //
    // const glowGradientColors = [Color(0xFFFFEFA0), Color(0xFFF0C078)];
    // void paintRotatingGlow() {
    //   final text = String.fromCharCode(Icons.star.codePoint);
    //   final center = Offset(size.width, size.height) / 2;
    //   final glowAngle = time * 2.2;
    //   final glowAxis =
    //       Offset(math.cos(glowAngle), math.sin(glowAngle)) * (iconSize / 2);
    //   final glowShader = ui.Gradient.linear(
    //     center - glowAxis,
    //     center + glowAxis,
    //     glowGradientColors,
    //   );
    //   final glowPainter = TextPainter(textDirection: TextDirection.ltr)
    //     ..text = TextSpan(
    //       text: text,
    //       style: TextStyle(
    //         fontSize: iconSize,
    //         fontFamily: Icons.star.fontFamily,
    //         package: Icons.star.fontPackage,
    //         foreground: Paint()
    //           ..style = PaintingStyle.stroke
    //           ..strokeWidth = iconSize * 0.08
    //           ..shader = glowShader
    //           ..maskFilter = MaskFilter.blur(BlurStyle.normal, iconSize * 0.04),
    //       ),
    //     )
    //     ..layout();
    //   final topLeft =
    //       center - Offset(glowPainter.width, glowPainter.height) / 2;
    //   glowPainter.paint(canvas, topLeft);
    // }

    // Tried dark navy here (and in [paintRing] below) for both, just to
    // see it — back to white now. [BlendMode.overlay] only ever
    // brightens what's under it, which is exactly why navy didn't read
    // as dark there; white doesn't have that problem.
    void paintIcon(IconData icon, double opacity) {
      final text = String.fromCharCode(icon.codePoint);
      final iconPainter = TextPainter(textDirection: TextDirection.ltr)
        ..text = TextSpan(
          text: text,
          style: TextStyle(
            fontSize: starGlyphSize,
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

    // Used to be part of the shader's own additive glow (drawn first,
    // via [shader] above) — but at 0.09 world units its radius sits
    // well inside the icon's own, so drawn there it was the icon
    // covering most of the ring rather than the ring sitting around
    // the icon. Painted here instead, after the icon, so it's
    // unambiguously the outermost thing — same idea as the real
    // supernovas' own fixed outer ring (see
    // `SkySupernova._paintOutlineIcon`'s [outlinePainter], also drawn
    // on top of its icon), just a plain stroked circle rather than a
    // glyph-shaped one since this ring was never meant to trace the
    // star's own outline.
    void paintRing() {
      final center = Offset(size.width, size.height) / 2;
      // [scale] is the exact same world-units-to-pixels factor passed
      // to the shader as `uScale`; 0.09/0.016 match that shader's own
      // former `ringRadius`/ring width.
      final radius = 0.09 * scale;
      final width = 0.016 * scale;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 3
          ..color = Colors.white.withValues(alpha: 0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 2)
          ..blendMode = BlendMode.plus,
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..color = Colors.white.withValues(alpha: 0.8)
          ..blendMode = BlendMode.plus,
      );
    }

    // Drawn straight into this same canvas, after the glow.
    void paintLogo() {
      final image = logoImage;
      if (image == null) return;
      final center = Offset(size.width, size.height) / 2;
      final rect = Rect.fromCenter(
        center: center,
        width: logoSize,
        height: logoSize,
      );
      final src = Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      );

      // 1. The crisp logo first, clipped to a circle (the source PNG is a
      // full square, transparent outside its own navy border — left
      // unclipped, that square's corners would show). [BlendMode.softLight]
      // instead of plain normal compositing: lets the glow drawn earlier on
      // this same canvas modulate the logo's whites/darks rather than just
      // sitting flatly on top of it.
      canvas.save();
      canvas.clipPath(Path()..addOval(rect));
      canvas.drawImageRect(
        image,
        src,
        rect,
        Paint()
          ..color = Colors.white.withValues(alpha: logoOpacity)
          ..blendMode = BlendMode.softLight
          ..filterQuality = FilterQuality.high,
      );
      canvas.restore();

      // 2. A soft, blurred, additive bloom drawn *after* the crisp logo —
      // it has to come last, or the crisp pass above (opaque, covering
      // almost this entire canvas) just paints straight over it and hides
      // it entirely. Deliberately unclipped, so the star's own light
      // visibly spreads past the disc's own edge into the glow around it
      // and eats into the dark disc immediately around it, rather than
      // either blocking the glow outright (opaque) or just letting it
      // passively show through (transparency) — "consumes what's around
      // it" rather than "lets it pass through".
      canvas.drawImageRect(
        image,
        src,
        rect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..blendMode = BlendMode.plus
          ..imageFilter = ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8)
          ..filterQuality = FilterQuality.high,
      );
    }

    if (showStarAndRing) {
      paintIcon(Icons.star, 0.8);
      paintRing();
    }
    paintLogo();
  }

  @override
  bool shouldRepaint(covariant _MenuStarSupernovaPainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.scale != scale ||
      oldDelegate.starGlyphSize != starGlyphSize ||
      oldDelegate.charge != charge ||
      oldDelegate.showStarAndRing != showStarAndRing ||
      oldDelegate.logoImage != logoImage ||
      oldDelegate.logoSize != logoSize ||
      oldDelegate.logoOpacity != logoOpacity;
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.gold,
              ),
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
