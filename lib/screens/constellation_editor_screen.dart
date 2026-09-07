import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../data/constellation_editor_prefs.dart';
import '../data/constellation_shapes_v2.dart';
import '../data/custom_constellation_repository.dart';
import '../l10n/strings_scope.dart';
import '../models/custom_constellation.dart';
import '../theme/app_colors.dart';
import '../widgets/constellation_editor_painter.dart';
import '../widgets/responsive_content.dart';

/// Lets the user hand-draw their own constellation shape: tap empty space to
/// place a star, tap two stars in turn to connect/disconnect them, drag a
/// star to reposition it, and save the result as a reusable
/// [CustomConstellation]. Interaction mirrors the offline Astralarium
/// workflow already used to co-design the app's own built-in shapes (see
/// `tools/constellation-astralarium/`) — tap to place, tap-tap to connect —
/// brought in-app for end users.
///
/// Pass [existing] to open an already-saved shape for editing instead of
/// starting from a blank canvas — saving then updates that same
/// [CustomConstellation] (same id, same position in the user's list) rather
/// than creating a new one, via [CustomConstellationRepository.update].
///
/// The canvas is fixed-size and never pans/zooms: unlike
/// [ConstellationScreen] (which frames an already-known shape), the user is
/// actively placing points, and where they land within the canvas doesn't
/// matter — [normalizeEditorPoints] rescales everything into the shared 0..1
/// box once, at save time.
class ConstellationEditorScreen extends StatefulWidget {
  const ConstellationEditorScreen({
    super.key,
    required this.customConstellationRepository,
    this.existing,
  });

  final CustomConstellationRepository customConstellationRepository;
  final CustomConstellation? existing;

  @override
  State<ConstellationEditorScreen> createState() =>
      _ConstellationEditorScreenState();
}

/// A soft cap, distinct from `maxChainedStars` in constellation_layout.dart
/// (which bounds the *rendered, algorithmically grown* graph for
/// performance). This one bounds how many points a person can usefully
/// place and keep track of by hand in one sitting — the 20 built-in shapes
/// all land at 5-10 points, so this leaves generous headroom without
/// inviting a shape so dense it stops reading as a constellation on a phone
/// screen.
const int _maxEditorPoints = 25;

class _EditorSnapshot {
  const _EditorSnapshot(this.points, this.edges);
  final List<Offset> points;
  final List<(int, int)> edges;
}

class _ConstellationEditorScreenState extends State<ConstellationEditorScreen> {
  /// Working coordinates, relative to the canvas's own size (roughly 0..1,
  /// same convention a saved [ConstellationShape] uses — but not clamped:
  /// dragging a point past the visible canvas edge just pushes it slightly
  /// outside that range, which [normalizeEditorPoints] resolves at save
  /// time by re-fitting everything to the actual bounding box). Storing
  /// points this way — rather than in raw canvas-pixel space — means
  /// opening an existing [CustomConstellation] for editing is a direct
  /// assignment (its `shape.points` are already in this same convention),
  /// with no dependency on knowing the on-screen canvas's pixel size up
  /// front.
  final List<Offset> _points = [];
  final List<(int, int)> _edges = [];
  int? _armedIndex;
  int? _draggingIndex;
  final List<_EditorSnapshot> _undoStack = [];
  final List<_EditorSnapshot> _redoStack = [];

  /// The on-screen canvas's actual pixel size, refreshed every build (see
  /// the `LayoutBuilder` in [build]) — needed to convert between the
  /// relative [_points] and the raw pixel positions pointer events report
  /// and [ConstellationEditorPainter] draws in.
  Size _canvasSize = Size.zero;

  Offset? _pointerDownPosition;
  int? _pointerDownIndex;
  bool _isDragging = false;

  /// Graph-paper background: a fixed [_gridDivisions] x [_gridDivisions]
  /// grid across the whole canvas — the canvas itself is the one "big
  /// square", divided into 10x10 small ones, with no separate coarser tier.
  /// When [_gridEnabled], every added/dragged point snaps to the nearest
  /// grid vertex (see [_snapIfGridEnabled]).
  bool _gridEnabled = true;
  static const _gridDivisions = 10;

  /// [_canvasSize]-dependent, so always recomputed rather than cached — the
  /// canvas can resize (e.g. on rotation) between builds.
  double get _gridSpacing => _canvasSize.width / _gridDivisions;

  /// How far the pointer has to move from where it went down before a touch
  /// on an existing point counts as a drag rather than a tap. Deliberately
  /// small (real touchscreens always have a few pixels of finger wobble
  /// during a "still" tap) — the actual tap/connect/add logic lives in
  /// [_handleTap], driven by raw pointer events rather than
  /// [GestureDetector]'s onTap+onPan combo: on a real device, that combo let
  /// the pan recognizer occasionally win the gesture arena even for a
  /// stationary tap, silently swallowing the tap-to-connect gesture (see
  /// [_handlePointerDown]/[_handlePointerMove]/[_handlePointerUp] below).
  static const _dragActivationDistance = 8.0;

  ConstellationEditorPrefs? _prefs;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _points.addAll(existing.shape.points);
      _edges.addAll(existing.shape.edges);
    }
    _maybeAutoShowHelp();
  }

  /// [_points] and [ConstellationEditorPainter]/pointer events don't speak
  /// the same units — these two converters are the only place that
  /// boundary is crossed, using [_canvasSize] as captured by the most
  /// recent build's `LayoutBuilder`.
  Offset _toRelative(Offset pixelPosition) {
    if (_canvasSize.isEmpty) return pixelPosition;
    return Offset(
      pixelPosition.dx / _canvasSize.width,
      pixelPosition.dy / _canvasSize.height,
    );
  }

  List<Offset> get _pixelPoints => _points
      .map((p) => Offset(p.dx * _canvasSize.width, p.dy * _canvasSize.height))
      .toList();

  /// Snaps a raw pixel position to the nearest grid vertex when the grid is
  /// on — a no-op otherwise. Applied at the moment a point is added or
  /// dragged (see [_handleTap]/[_handlePointerMove]), before converting to
  /// [_points]' relative space, so the stored position is exactly on the
  /// grid rather than merely close to it.
  Offset _snapIfGridEnabled(Offset pixelPosition) {
    return _gridEnabled
        ? snapToGrid(pixelPosition, _gridSpacing)
        : pixelPosition;
  }

  Future<void> _maybeAutoShowHelp() async {
    final prefs = await ConstellationEditorPrefs.create();
    if (!mounted) return;
    _prefs = prefs;
    if (prefs.hideHelp) return;
    // Editing an already-saved shape means the user has already been
    // through the "how this works" tutorial once (they had to draw it in
    // the first place) — showing it again here would just be in the way.
    if (widget.existing != null) return;
    // Scheduled for after the first frame (not called directly here) since
    // showDialog needs a BuildContext with an Overlay already mounted above
    // it — this screen's own build() hasn't run yet during initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showHelp();
    });
  }

  /// Always available via the app bar's "?" icon regardless of the "don't
  /// show this again" preference — that flag only skips the *automatic*
  /// pop-up on [_maybeAutoShowHelp], never the manual one.
  Future<void> _showHelp() async {
    final prefs = _prefs ??= await ConstellationEditorPrefs.create();
    if (!mounted) return;
    final strings = context.strings;
    final colors = context.colors;
    var hideNextTime = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: colors.nightPanel,
          title: Text(
            strings.constellationEditorHelpTitle,
            style: TextStyle(color: colors.text),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpBullet(
                  text: strings.constellationEditorHelpAddPoint,
                  illustration: _addPointDiagram,
                ),
                _HelpBullet(
                  text: strings.constellationEditorHelpConnectPoint,
                  illustration: _connectDiagram,
                ),
                _HelpBullet(
                  text: strings.constellationEditorHelpDisarmPoint,
                  illustration: _disarmDiagram,
                ),
                _HelpBullet(
                  text: strings.constellationEditorHelpMovePoint,
                  illustration: _moveDiagram,
                ),
                _HelpBullet(
                  text: strings.constellationEditorHelpDeletePoint,
                  illustration: _deleteDiagram,
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () =>
                      setDialogState(() => hideNextTime = !hideNextTime),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Checkbox(
                          value: hideNextTime,
                          activeColor: colors.gold,
                          onChanged: (value) => setDialogState(
                            () => hideNextTime = value ?? false,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            strings.constellationEditorHelpDontShowAgain,
                            style: TextStyle(color: colors.muted, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await prefs.setHideHelp(hideNextTime);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: Text(
                strings.constellationEditorHelpClose,
                style: TextStyle(color: colors.gold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _EditorSnapshot _currentSnapshot() =>
      _EditorSnapshot(List.of(_points), List.of(_edges));

  void _pushUndoSnapshot() {
    _undoStack.add(_currentSnapshot());
    // A fresh edit invalidates whatever redo history existed — standard
    // undo/redo semantics (there's no single "future" once you've branched
    // off into a new change).
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    final last = _undoStack.removeLast();
    _redoStack.add(_currentSnapshot());
    setState(() {
      _points
        ..clear()
        ..addAll(last.points);
      _edges
        ..clear()
        ..addAll(last.edges);
      _armedIndex = null;
      _draggingIndex = null;
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    final next = _redoStack.removeLast();
    _undoStack.add(_currentSnapshot());
    setState(() {
      _points
        ..clear()
        ..addAll(next.points);
      _edges
        ..clear()
        ..addAll(next.edges);
      _armedIndex = null;
      _draggingIndex = null;
    });
  }

  void _toggleEdge(int a, int b) {
    final forward = _edges.indexWhere((e) => e.$1 == a && e.$2 == b);
    final backward = _edges.indexWhere((e) => e.$1 == b && e.$2 == a);
    if (forward != -1) {
      _edges.removeAt(forward);
    } else if (backward != -1) {
      _edges.removeAt(backward);
    } else {
      _edges.add((a, b));
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pointerDownPosition = event.localPosition;
    _pointerDownIndex = hitTestEditorPoint(event.localPosition, _pixelPoints);
    _isDragging = false;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final downIndex = _pointerDownIndex;
    final downPosition = _pointerDownPosition;
    if (downIndex == null || downPosition == null) return;

    if (!_isDragging) {
      if ((event.localPosition - downPosition).distance <
          _dragActivationDistance) {
        return;
      }
      _isDragging = true;
      _draggingIndex = downIndex;
      _pushUndoSnapshot();
    }
    setState(
      () => _points[downIndex] = _toRelative(
        _snapIfGridEnabled(event.localPosition),
      ),
    );
  }

  void _handlePointerUp(PointerUpEvent event) {
    final wasDragging = _isDragging;
    final downIndex = _pointerDownIndex;
    _pointerDownPosition = null;
    _pointerDownIndex = null;
    _isDragging = false;

    if (wasDragging) {
      setState(() => _draggingIndex = null);
      return;
    }
    _handleTap(downIndex, event.localPosition);
  }

  /// The actual tap logic (add/arm/connect), driven by raw pointer events —
  /// see [_dragActivationDistance]'s doc comment for why this isn't a plain
  /// [GestureDetector.onTapUp]. [tapped] is the point that was under the
  /// finger when it went *down* (not up), matching normal touch semantics
  /// and avoiding a second, possibly-different hit test at release.
  void _handleTap(int? tapped, Offset position) {
    if (tapped == null) {
      if (_points.length >= _maxEditorPoints) return;
      _pushUndoSnapshot();
      setState(() {
        _points.add(_toRelative(_snapIfGridEnabled(position)));
        _armedIndex = null;
      });
      return;
    }

    final armed = _armedIndex;
    if (armed == null) {
      setState(() => _armedIndex = tapped);
      return;
    }
    if (armed == tapped) {
      setState(() => _armedIndex = null);
      return;
    }

    _pushUndoSnapshot();
    setState(() {
      _toggleEdge(armed, tapped);
      _armedIndex = tapped;
    });
  }

  void _deleteArmedPoint() {
    final index = _armedIndex;
    if (index == null) return;

    _pushUndoSnapshot();
    final (newPoints, newEdges) = removeEditorPoint(_points, _edges, index);
    setState(() {
      _points
        ..clear()
        ..addAll(newPoints);
      _edges
        ..clear()
        ..addAll(newEdges);
      _armedIndex = null;
    });
  }

  int get _disconnectedCount {
    final connected = <int>{};
    for (final (a, b) in _edges) {
      connected.add(a);
      connected.add(b);
    }
    return _points.length - connected.length;
  }

  /// True once the canvas differs from whatever it started as — an empty
  /// canvas when creating a new shape, or [widget.existing]'s own saved
  /// points/edges when editing one. Compared against those originals
  /// directly rather than a separate "dirty" flag, so undo/redo back to the
  /// exact starting state also correctly clears this.
  bool get _hasUnsavedChanges {
    final initialPoints = widget.existing?.shape.points ?? const <Offset>[];
    final initialEdges = widget.existing?.shape.edges ?? const <(int, int)>[];
    return !listEquals(_points, initialPoints) || !listEquals(_edges, initialEdges);
  }

  /// Shared by the back button and the system back gesture (see the
  /// [PopScope] in [build]): leaving with unsaved changes needs
  /// confirmation first, everything else pops right away. [_save] itself
  /// pops directly rather than through here — an explicit [Navigator.pop]
  /// call always succeeds regardless of [PopScope.canPop], so a completed
  /// save is never blocked or re-prompted just because the canvas still
  /// differs from where it started.
  Future<void> _handleBack() async {
    if (!_hasUnsavedChanges) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await _confirmDiscard();
    if (discard && mounted) Navigator.of(context).pop();
  }

  /// Styled like the rest of the app's confirmations (see
  /// [SettingsScreen]'s reset-all-data prompt) — a muted cancel next to a
  /// [danger]-colored confirm action.
  Future<bool> _confirmDiscard() async {
    final colors = context.colors;
    final strings = context.strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.nightPanel,
        title: Text(
          strings.discardChangesConfirmTitle,
          style: TextStyle(color: colors.text),
        ),
        content: Text(
          strings.discardChangesConfirmBody,
          style: TextStyle(color: colors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel, style: TextStyle(color: colors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              strings.discardChangesAction,
              style: TextStyle(color: colors.danger),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _save() async {
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) =>
          _NameConstellationDialog(initialName: widget.existing?.name),
    );
    if (name == null || name.isEmpty || !mounted) return;

    final normalized = normalizeEditorPoints(_points);
    final shape = ConstellationShape(
      points: normalized,
      edges: List.of(_edges),
    );
    final existing = widget.existing;
    final saved = existing == null
        ? await widget.customConstellationRepository.add(
            name: name,
            shape: shape,
          )
        : await widget.customConstellationRepository.update(
            id: existing.id,
            name: name,
            shape: shape,
          );
    if (mounted) Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final canSave = _points.length >= 2;
    final disconnected = _disconnectedCount;

    final scaffold = Scaffold(
      backgroundColor: colors.night,
      body: SafeArea(
        child: ResponsiveContent(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _handleBack,
                    icon: Icon(Icons.arrow_back, color: colors.muted),
                  ),
                  Expanded(
                    child: Text(
                      widget.existing == null
                          ? strings.constellationEditorTitle
                          : strings.constellationEditorEditTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: colors.text,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: strings.constellationEditorGridToggleLabel,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.grid_on, size: 18, color: colors.muted),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: _gridEnabled,
                            onChanged: (value) =>
                                setState(() => _gridEnabled = value),
                            activeThumbColor: colors.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _showHelp,
                    icon: Icon(Icons.help_outline, color: colors.muted),
                    tooltip: strings.constellationEditorHelpAction,
                  ),
                ],
              ),
              Expanded(
                // The canvas is a square capped to whichever of the
                // available width/height is smaller — sizing it off width
                // alone (an AspectRatio taking the Column's full width)
                // could ask for more height than this region actually has
                // on a wide-but-short viewport (typical of a browser
                // window), overflowing past the controls below it. Title
                // (only shown when editing an existing shape) gets its own
                // fixed slot above the canvas; equal flex above/below what's
                // left centers the canvas in the remaining space.
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const titleHeight = 44.0;
                    final hasTitle = widget.existing != null;
                    final availableForCanvas =
                        constraints.maxHeight - (hasTitle ? titleHeight : 0);
                    final canvasSize = math.min(
                      constraints.maxWidth,
                      availableForCanvas,
                    );
                    return Column(
                      children: [
                        if (hasTitle)
                          SizedBox(
                            height: titleHeight,
                            child: Center(
                              child: _ExistingConstellationHeader(
                                constellation: widget.existing!,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Center(
                            child: SizedBox(
                              width: canvasSize,
                              height: canvasSize,
                              child: LayoutBuilder(
                                builder: (context, canvasConstraints) {
                                  _canvasSize = canvasConstraints.biggest;
                                  return Listener(
                                    behavior: HitTestBehavior.opaque,
                                    onPointerDown: _handlePointerDown,
                                    onPointerMove: _handlePointerMove,
                                    onPointerUp: _handlePointerUp,
                                    child: Container(
                                      clipBehavior: Clip.antiAlias,
                                      decoration: BoxDecoration(
                                        color: colors.nightPanel,
                                        border: Border.all(
                                          color: colors.nightBorder,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          if (_gridEnabled)
                                            Positioned.fill(
                                              child: CustomPaint(
                                                painter: _GridPainter(
                                                  divisions: _gridDivisions,
                                                  color: colors.nightBorder,
                                                  // Just a touch brighter than
                                                  // the regular grid lines —
                                                  // a small blend toward
                                                  // `muted` rather than
                                                  // jumping straight to it,
                                                  // so the center reads as
                                                  // "the same grid, slightly
                                                  // lifted" rather than a
                                                  // visually distinct line.
                                                  centerColor: Color.lerp(
                                                    colors.nightBorder,
                                                    colors.muted,
                                                    0.3,
                                                  )!,
                                                ),
                                              ),
                                            ),
                                          if (_points.isEmpty)
                                            Center(
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  24,
                                                ),
                                                child: Text(
                                                  strings
                                                      .constellationEditorEmptyHint,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: colors.muted,
                                                  ),
                                                ),
                                              ),
                                            )
                                          else
                                            CustomPaint(
                                              size: canvasConstraints.biggest,
                                              painter: ConstellationEditorPainter(
                                                points: _pixelPoints,
                                                edges: _edges,
                                                highlightedIndex:
                                                    _armedIndex ??
                                                    _draggingIndex,
                                                pointColor: colors.text,
                                                highlightColor: colors.gold,
                                                lineColor: colors.gold
                                                    .withValues(alpha: 0.5),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                // A Row of Flexible buttons, not a Wrap — a Wrap drops to a
                // second line once the three pills stop fitting (which a
                // longer translation, e.g. Romanian, hits easily), while
                // Flexible instead lets each pill's own label ellipsize so
                // all three always stay on one row.
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: _EditorActionButton(
                        icon: Icons.undo,
                        label: strings.undoAction,
                        onTap: _undoStack.isEmpty ? null : _undo,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: _EditorActionButton(
                        icon: Icons.redo,
                        label: strings.redoAction,
                        onTap: _redoStack.isEmpty ? null : _redo,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: _EditorActionButton(
                        icon: Icons.delete_outline,
                        label: strings.deletePointAction,
                        onTap: _armedIndex == null ? null : _deleteArmedPoint,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Text(
                  _points.length >= _maxEditorPoints
                      ? strings.constellationEditorPointCapReached
                      : disconnected > 0
                      ? strings.constellationEditorDisconnectedWarning(
                          disconnected,
                        )
                      : '',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: colors.muted),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Center(
                  child: ElevatedButton(
                    onPressed: canSave ? _save : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.gold,
                      foregroundColor: colors.onGold,
                      disabledBackgroundColor: colors.nightBorder,
                      disabledForegroundColor: colors.muted,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      strings.saveConstellationAction,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: scaffold,
    );
  }
}

/// A small gold pill button for the undo/delete actions below the canvas —
/// mirrors `_ActionButton` in star_reader_screen.dart (same
/// `Material`+`StadiumBorder`+`InkWell` gold-pill treatment used for that
/// screen's share/mark-achieved/resurrect action), just sized down to sit
/// two-across and with an explicit disabled look (dimmed border/text)
/// instead of always being tappable.
class _EditorActionButton extends StatelessWidget {
  const _EditorActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onTap != null;
    final foreground = enabled ? colors.onGold : colors.muted;

    return Material(
      color: enabled ? colors.gold : colors.nightBorder,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foreground, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
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

/// The name (and description, if there is one) of the shape being edited,
/// shown above the canvas — only when editing an already-saved
/// [CustomConstellation] (a brand new shape has neither yet, since both are
/// only entered at save time).
/// A shape only ever has a name — no description (see [CustomConstellation]'s
/// own doc comment: the same shape can be reused across several projects,
/// so "what it means" belongs to the project, not the shape).
class _ExistingConstellationHeader extends StatelessWidget {
  const _ExistingConstellationHeader({required this.constellation});

  final CustomConstellation constellation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        // Symmetric top/bottom — was 4/14 before, which pushed the title
        // toward the top of its own block instead of centering it there.
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Text(
          constellation.name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: colors.text,
          ),
        ),
      ),
    );
  }
}

/// One row of the help dialog: a small hand-drawn-looking diagram (see
/// [_GestureDiagram]) illustrating the gesture, next to its text
/// description — a picture of the before/after state reads faster than the
/// sentence alone, especially for the two-tap connect/disconnect gestures
/// that are hardest to describe in words.
class _HelpBullet extends StatelessWidget {
  const _HelpBullet({required this.text, required this.illustration});

  final String text;
  final Widget illustration;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          illustration,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: colors.muted, fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

/// Where one dot sits in a [_GestureDiagram]'s normalized (0..1) box, and
/// how it should be drawn: [ghost] for "not there yet / no longer there"
/// (a dashed outline instead of a filled dot), [ringed] for "currently
/// selected/armed" (an extra gold ring, matching
/// [ConstellationEditorPainter]'s own selection ring in the real canvas).
class _DiagramDot {
  const _DiagramDot(this.position, {this.ghost = false, this.ringed = false});

  final Offset position;
  final bool ghost;
  final bool ringed;
}

/// A tiny, static before/after illustration for one editor gesture — dots,
/// optional connecting/trailing lines, an optional center arrow, and an
/// optional small icon overlay (tap, drag, delete) — built entirely from
/// [CustomPainter] primitives plus a couple of [Icon]s, so no image assets
/// are needed. Colors are resolved from the active theme at build time
/// (via `context.colors`) rather than passed in, so every diagram instance
/// below can be a compile-time `const`.
class _GestureDiagram extends StatelessWidget {
  const _GestureDiagram({
    required this.dots,
    this.line,
    this.trail,
    this.showArrow = false,
    this.icon,
    this.iconAt,
    this.iconIsDanger = false,
  });

  final List<_DiagramDot> dots;

  /// A solid connecting line between two dots (by index) — "these two stars
  /// are now linked".
  final (int, int)? line;

  /// A dashed line between two dots (by index) — a drag trail from where a
  /// star used to be to where it is now.
  final (int, int)? trail;

  /// A short horizontal arrow through the diagram's center, for a
  /// before/after state change that isn't a physical connection or move
  /// (e.g. "armed" → "not armed", "here" → "deleted").
  final bool showArrow;

  final IconData? icon;
  final Offset? iconAt;
  final bool iconIsDanger;

  static const _width = 74.0;
  static const _height = 44.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final iconAtValue = iconAt;
    return SizedBox(
      width: _width,
      height: _height,
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(_width, _height),
            painter: _GestureDiagramPainter(
              dots: dots,
              line: line,
              trail: trail,
              showArrow: showArrow,
              dotColor: colors.text,
              ghostColor: colors.muted,
              ringColor: colors.gold,
              lineColor: colors.gold,
              arrowColor: colors.muted,
            ),
          ),
          if (icon != null && iconAtValue != null)
            Positioned(
              left: iconAtValue.dx * _width - 8,
              top: iconAtValue.dy * _height - 8,
              child: Icon(
                icon,
                size: 15,
                color: iconIsDanger ? colors.danger : colors.gold,
              ),
            ),
        ],
      ),
    );
  }
}

class _GestureDiagramPainter extends CustomPainter {
  const _GestureDiagramPainter({
    required this.dots,
    required this.line,
    required this.trail,
    required this.showArrow,
    required this.dotColor,
    required this.ghostColor,
    required this.ringColor,
    required this.lineColor,
    required this.arrowColor,
  });

  final List<_DiagramDot> dots;
  final (int, int)? line;
  final (int, int)? trail;
  final bool showArrow;
  final Color dotColor;
  final Color ghostColor;
  final Color ringColor;
  final Color lineColor;
  final Color arrowColor;

  static const _dotRadius = 4.0;
  static const _ringRadius = 7.5;
  static const _ghostRadius = 5.0;

  Offset _px(Offset normalized, Size size) =>
      Offset(normalized.dx * size.width, normalized.dy * size.height);

  @override
  void paint(Canvas canvas, Size size) {
    final solidLine = line;
    if (solidLine != null) {
      canvas.drawLine(
        _px(dots[solidLine.$1].position, size),
        _px(dots[solidLine.$2].position, size),
        Paint()
          ..color = lineColor
          ..strokeWidth = 1.5,
      );
    }

    final dashedTrail = trail;
    if (dashedTrail != null) {
      _drawDashedLine(
        canvas,
        _px(dots[dashedTrail.$1].position, size),
        _px(dots[dashedTrail.$2].position, size),
        Paint()
          ..color = ghostColor
          ..strokeWidth = 1.2,
      );
    }

    for (final dot in dots) {
      final center = _px(dot.position, size);
      if (dot.ghost) {
        _drawDashedCircle(
          canvas,
          center,
          _ghostRadius,
          Paint()
            ..color = ghostColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      } else {
        canvas.drawCircle(center, _dotRadius, Paint()..color = dotColor);
      }
      if (dot.ringed) {
        canvas.drawCircle(
          center,
          _ringRadius,
          Paint()
            ..color = ringColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    if (showArrow) {
      final y = size.height / 2;
      final start = Offset(size.width * 0.4, y);
      final end = Offset(size.width * 0.6, y);
      final arrowPaint = Paint()
        ..color = arrowColor
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(start, end, arrowPaint);
      final headPath = Path()
        ..moveTo(end.dx - 4, end.dy - 3)
        ..lineTo(end.dx, end.dy)
        ..lineTo(end.dx - 4, end.dy + 3);
      canvas.drawPath(headPath, arrowPaint);
    }
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    const dashCount = 10;
    for (var i = 0; i < dashCount; i += 2) {
      final startAngle = (i / dashCount) * 2 * math.pi;
      const sweep = (1 / dashCount) * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dashLength = 3.0, gapLength = 2.5;
    final total = (b - a).distance;
    if (total == 0) return;
    final direction = (b - a) / total;
    var covered = 0.0;
    while (covered < total) {
      final segmentEnd = math.min(covered + dashLength, total);
      canvas.drawLine(
        a + direction * covered,
        a + direction * segmentEnd,
        paint,
      );
      covered = segmentEnd + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant _GestureDiagramPainter oldDelegate) => false;
}

const _addPointDiagram = _GestureDiagram(
  dots: [
    _DiagramDot(Offset(0.28, 0.5), ghost: true),
    _DiagramDot(Offset(0.75, 0.5)),
  ],
  showArrow: true,
  icon: Icons.touch_app,
  iconAt: Offset(0.28, 0.15),
);

const _connectDiagram = _GestureDiagram(
  dots: [
    _DiagramDot(Offset(0.25, 0.5), ringed: true),
    _DiagramDot(Offset(0.75, 0.5)),
  ],
  line: (0, 1),
  icon: Icons.touch_app,
  iconAt: Offset(0.75, 0.15),
);

const _disarmDiagram = _GestureDiagram(
  dots: [
    _DiagramDot(Offset(0.3, 0.5), ringed: true),
    _DiagramDot(Offset(0.7, 0.5)),
  ],
  showArrow: true,
  icon: Icons.touch_app,
  iconAt: Offset(0.3, 0.15),
);

const _moveDiagram = _GestureDiagram(
  dots: [
    _DiagramDot(Offset(0.25, 0.72), ghost: true),
    _DiagramDot(Offset(0.75, 0.28)),
  ],
  trail: (0, 1),
  icon: Icons.pan_tool_alt,
  iconAt: Offset(0.25, 0.72),
);

const _deleteDiagram = _GestureDiagram(
  dots: [
    _DiagramDot(Offset(0.3, 0.5), ringed: true),
    _DiagramDot(Offset(0.7, 0.5), ghost: true),
  ],
  showArrow: true,
  icon: Icons.delete_outline,
  iconAt: Offset(0.7, 0.15),
  iconIsDanger: true,
);

/// A graph-paper backdrop for the editor canvas: a uniform grid dividing
/// the whole canvas — the one "big square" — into [divisions] equal small
/// ones on each axis, with the center vertical/horizontal line emphasized
/// (see [centerColor]) so the middle of the shape stays easy to spot.
/// Purely decorative (and a visual reference for [_snapIfGridEnabled]'s
/// vertices).
class _GridPainter extends CustomPainter {
  const _GridPainter({
    required this.divisions,
    required this.color,
    required this.centerColor,
  });

  final int divisions;
  final Color color;

  /// The one vertical and one horizontal line through the exact center
  /// (only when [divisions] is even — [_ConstellationEditorScreenState._gridDivisions]
  /// is fixed at 10, so this always lands cleanly) are drawn in this
  /// brighter shade of the same neutral grid color, same stroke width as
  /// every other line — just enough to keep the canvas's center visible at
  /// a glance without turning it into a visually distinct accent line.
  final Color centerColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (divisions <= 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final centerPaint = Paint()
      ..color = centerColor
      ..strokeWidth = 1;
    final centerIndex = divisions / 2;

    for (var i = 0; i <= divisions; i++) {
      final x = size.width * i / divisions;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        i == centerIndex ? centerPaint : paint,
      );
    }
    for (var i = 0; i <= divisions; i++) {
      final y = size.height * i / divisions;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        i == centerIndex ? centerPaint : paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return divisions != oldDelegate.divisions ||
        color != oldDelegate.color ||
        centerColor != oldDelegate.centerColor;
  }
}

/// The "name your constellation" prompt shown by [_ConstellationEditorScreenState._save]
/// — its own [TextEditingController] lives and dies with *this widget's*
/// element, not with the `showDialog` call's Future. `showDialog`'s Future
/// resolves the instant `Navigator.pop` is called, before the dialog route's
/// exit transition has actually finished removing this widget's `TextField`
/// from the tree — disposing the controller right after that `await` (as
/// this used to) could hit a still-animating, still-mounted `TextField`
/// still holding the disposed controller, throwing "used after being
/// disposed" for the transition's remaining frames (the app's own users
/// reported this as a brief red error screen right after saving a shape,
/// self-recovering once the dialog actually finished closing). Owning the
/// controller here instead means Flutter disposes it at the correct moment
/// on its own — when this widget's own `State` actually unmounts.
class _NameConstellationDialog extends StatefulWidget {
  const _NameConstellationDialog({this.initialName});

  final String? initialName;

  @override
  State<_NameConstellationDialog> createState() =>
      _NameConstellationDialogState();
}

class _NameConstellationDialogState extends State<_NameConstellationDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final colors = context.colors;
    return AlertDialog(
      backgroundColor: colors.nightPanel,
      title: Text(
        strings.nameYourConstellationTitle,
        style: TextStyle(color: colors.text),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: TextStyle(color: colors.text),
        decoration: InputDecoration(hintText: strings.constellationNameHint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel, style: TextStyle(color: colors.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(
            strings.saveConstellationAction,
            style: TextStyle(color: colors.gold),
          ),
        ),
      ],
    );
  }
}
