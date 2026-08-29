import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/project_repository.dart';
import '../data/win_repository.dart';
import '../l10n/strings_scope.dart';
import '../models/project.dart';
import '../models/win.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';
import '../widgets/area_tag.dart';
import '../widgets/intensity_bolts.dart';
import '../widgets/project_tag.dart';
import 'add_win_screen.dart';

/// Shows one win at a time, with looping prev/next navigation.
///
/// Used two ways:
/// - From the crisis intro, browsing everything starting at the most
///   recent win ([allowEdit] false — pure reflection, no editing).
/// - From a tap on a specific card in the home list, starting at that win
///   ([allowEdit] true — adds an edit button that reuses [AddWinScreen],
///   which requires [projectRepository] and [refreshWins] too, since
///   editing can now reassign a win to a different project).
class WinReaderScreen extends StatefulWidget {
  const WinReaderScreen({
    super.key,
    required this.repository,
    required this.initialWins,
    required this.startIndex,
    required this.projectsById,
    this.allowEdit = false,
    this.projectRepository,
    this.refreshWins,
  }) : assert(
         !allowEdit || (projectRepository != null && refreshWins != null),
         'projectRepository and refreshWins are required when allowEdit is true.',
       );

  final WinRepository repository;
  final List<Win> initialWins;
  final int startIndex;

  /// Resolves each win's project (and, through it, its area) for display.
  /// A win whose id isn't in here (stale data) still renders — just without
  /// that context row.
  final Map<int, Project> projectsById;
  final bool allowEdit;

  final ProjectRepository? projectRepository;

  /// Re-derives this reader's win list the same way [initialWins] was
  /// originally scoped (e.g. "all wins" from Home, or "this project's wins"
  /// from a constellation) — called after an edit so prev/next keeps
  /// browsing the right set instead of silently falling back to every win.
  final List<Win> Function()? refreshWins;

  @override
  State<WinReaderScreen> createState() => _WinReaderScreenState();
}

class _WinReaderScreenState extends State<WinReaderScreen> {
  late List<Win> _wins = widget.initialWins;
  late int _index = widget.startIndex;

  /// Captures [_ShareableStarCard] — a duplicate of this screen's
  /// background+content, minus the close/edit/share/prev/next chrome —
  /// which sits directly behind the real one so it's never actually seen,
  /// only ever captured as an image.
  final _shareKey = GlobalKey();
  bool _sharing = false;

  void _showPrevious() {
    setState(() => _index = (_index - 1 + _wins.length) % _wins.length);
  }

  void _showNext() {
    setState(() => _index = (_index + 1) % _wins.length);
  }

  Future<void> _shareCurrent() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary = _shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: MediaQuery.of(context).devicePixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw StateError('toByteData returned null');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/star_${DateTime.now().microsecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: _wins[_index].title),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.strings.shareStarError)));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _editCurrent() async {
    final current = _wins[_index];
    final result = await Navigator.of(context).push<Object>(
      MaterialPageRoute(
        builder: (_) => AddWinScreen(
          existingWin: current,
          contextProject: widget.projectsById[current.projectId],
          projectRepository: widget.projectRepository,
        ),
      ),
    );
    if (result == null) return;

    if (result is AddWinDeleteRequested) {
      await widget.repository.delete(current.id);
      final refreshedWins = widget.refreshWins!();
      if (refreshedWins.isEmpty) {
        // Nothing left in this scope to show — back out to wherever it's
        // browsed from, which will reflect the deletion on its own.
        if (mounted) Navigator.of(context).pop();
        return;
      }
      setState(() {
        _wins = refreshedWins;
        _index = _index.clamp(0, _wins.length - 1);
      });
      return;
    }

    final addResult = result as AddWinResult;
    final updated = await widget.repository.update(
      id: current.id,
      title: addResult.title,
      description: addResult.description,
      projectId: addResult.projectId,
      intensity: addResult.intensity,
      date: addResult.date,
      photoPath: addResult.photoPath,
    );

    final refreshedWins = widget.refreshWins!();
    final refreshedIndex = refreshedWins.indexWhere((w) => w.id == updated.id);
    if (refreshedIndex == -1) {
      // The edit moved this win out of the current scope (e.g. reassigned
      // to a different project while browsing this one's constellation) —
      // nothing left here to show it next to, so back out to wherever that
      // scope is browsed from, which will reflect the change on its own.
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() {
      _wins = refreshedWins;
      _index = refreshedIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final win = _wins[_index];
    final project = widget.projectsById[win.projectId];
    final colors = context.colors;
    final strings = context.strings;

    final photoPath = win.photoPath;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Sits directly behind the real background+content below, so it's
          // always fully covered and never actually seen — its only purpose
          // is to give _shareCurrent something to capture that's identical
          // to what's on screen, just without the close/edit/share/prev/next
          // buttons.
          RepaintBoundary(key: _shareKey, child: _ShareableStarCard(win: win, project: project)),
          // The win's own photo, full-bleed, with the usual gradient washed
          // over it at reduced opacity instead of solid — background rather
          // than a discrete element on the page. Wrapped in its own
          // AnimatedSwitcher (same fade+scale as the foreground content) so
          // swiping between stars crossfades the background too, instead of
          // it snapping instantly while the text/star fade in gracefully.
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                final scale = Tween<double>(begin: 0.94, end: 1.0).animate(animation);
                return FadeTransition(opacity: animation, child: ScaleTransition(scale: scale, child: child));
              },
              child: Stack(
                key: ValueKey(_index),
                fit: StackFit.expand,
                children: [
                  if (photoPath != null)
                    Image.file(File(photoPath), fit: BoxFit.cover, alignment: Alignment.center),
                  Container(
                    decoration: BoxDecoration(
                      gradient: photoPath == null
                          ? colors.crisisGradient
                          : RadialGradient(
                              center: const Alignment(0, -0.6),
                              radius: 1.2,
                              colors: [
                                colors.crisisGradientCenter.withValues(alpha: 0.55),
                                colors.crisisGradientMid.withValues(alpha: 0.75),
                                colors.crisisGradientOuter.withValues(alpha: 0.9),
                              ],
                              stops: const [0.0, 0.55, 1.0],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: colors.crisisMuted),
                      ),
                      Text(
                        strings.indexOfCount(_index + 1, _wins.length),
                        style: TextStyle(fontSize: 12, color: colors.crisisMuted),
                      ),
                      if (widget.allowEdit)
                        IconButton(
                          onPressed: _editCurrent,
                          icon: Icon(Icons.edit_outlined, color: colors.crisisMuted),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      // Swipe left/right as an alternative to the prev/next
                      // buttons below — velocity-based so a light flick still
                      // registers, not just a full-width drag.
                      onHorizontalDragEnd: (details) {
                        final velocity = details.primaryVelocity ?? 0;
                        if (velocity < -200) {
                          _showNext();
                        } else if (velocity > 200) {
                          _showPrevious();
                        }
                      },
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (child, animation) {
                              final scale = Tween<double>(begin: 0.94, end: 1.0).animate(animation);
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(scale: scale, child: child),
                              );
                            },
                            child: Column(
                              key: ValueKey(_index),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, size: 44, color: colors.gold),
                                const SizedBox(height: 28),
                                Text(
                                  formatDisplayDateTime(win.date, strings),
                                  style: TextStyle(fontSize: 15, color: colors.crisisMuted),
                                ),
                                if (project != null) ...[
                                  const SizedBox(height: 16),
                                  AreaTag(area: project.area, iconSize: 24, fontSize: 21),
                                  const SizedBox(height: 8),
                                  ProjectTag(project: project, textColor: colors.crisisMuted, iconSize: 17, fontSize: 17),
                                ],
                                const SizedBox(height: 24),
                                Text(
                                  win.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                    color: colors.text,
                                  ),
                                ),
                                if (win.description != null) ...[
                                  const SizedBox(height: 22),
                                  Text(
                                    win.description!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 18, height: 1.6, color: colors.crisisMuted),
                                  ),
                                ],
                                const SizedBox(height: 28),
                                IntensityBolts(intensity: win.intensity, size: 30, spacing: 6, emphasizeLast: true),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _NavCircleButton(icon: Icons.chevron_left, onTap: _showPrevious),
                      _ShareButton(sharing: _sharing, onTap: _shareCurrent, label: strings.shareStarLabel),
                      _NavCircleButton(icon: Icons.chevron_right, onTap: _showNext),
                    ],
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

/// A static duplicate of [_WinReaderScreenState]'s background+content —
/// same photo/gradient, same star icon/date/tags/title/description/bolts —
/// with none of the close/edit/share/prev-next chrome. Exists only to be
/// captured as an image by [_WinReaderScreenState._shareCurrent]; never
/// meant to be visibly seen (it sits fully covered behind the real thing).
class _ShareableStarCard extends StatelessWidget {
  const _ShareableStarCard({required this.win, required this.project});

  final Win win;
  final Project? project;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final photoPath = win.photoPath;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (photoPath != null) Image.file(File(photoPath), fit: BoxFit.cover, alignment: Alignment.center),
        Container(
          decoration: BoxDecoration(
            gradient: photoPath == null
                ? colors.crisisGradient
                : RadialGradient(
                    center: const Alignment(0, -0.6),
                    radius: 1.2,
                    colors: [
                      colors.crisisGradientCenter.withValues(alpha: 0.55),
                      colors.crisisGradientMid.withValues(alpha: 0.75),
                      colors.crisisGradientOuter.withValues(alpha: 0.9),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 44, color: colors.gold),
                  const SizedBox(height: 28),
                  Text(
                    formatDisplayDateTime(win.date, strings),
                    style: TextStyle(fontSize: 15, color: colors.crisisMuted),
                  ),
                  if (project != null) ...[
                    const SizedBox(height: 16),
                    AreaTag(area: project!.area, iconSize: 24, fontSize: 21),
                    const SizedBox(height: 8),
                    ProjectTag(project: project!, textColor: colors.crisisMuted, iconSize: 17, fontSize: 17),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    win.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w600, height: 1.35, color: colors.text),
                  ),
                  if (win.description != null) ...[
                    const SizedBox(height: 22),
                    Text(
                      win.description!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, height: 1.6, color: colors.crisisMuted),
                    ),
                  ],
                  const SizedBox(height: 28),
                  IntensityBolts(intensity: win.intensity, size: 30, spacing: 6, emphasizeLast: true),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavCircleButton extends StatelessWidget {
  const _NavCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      // Tinted with the same light blue as the close/edit icons up top
      // (colors.crisisMuted), instead of a plain neutral white, so the
      // whole page reads as one consistent palette.
      color: context.colors.crisisMuted.withValues(alpha: 0.15),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 48, height: 48, child: Icon(icon, color: context.colors.text)),
      ),
    );
  }
}

/// Same translucent-disc treatment as [_NavCircleButton] (which it now
/// sits between, in the same row) — just a bit bigger, and with a caption
/// underneath since "share" isn't as self-explanatory as an arrow.
class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.sharing, required this.onTap, required this.label});

  final bool sharing;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: colors.crisisMuted.withValues(alpha: 0.15),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: sharing ? null : onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Center(
                child: sharing
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: colors.text),
                      )
                    : Icon(Icons.share_outlined, color: colors.text, size: 28),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 15, color: Colors.white)),
      ],
    );
  }
}
