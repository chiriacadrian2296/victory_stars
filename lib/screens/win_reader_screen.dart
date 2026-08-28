import 'dart:io';

import 'package:flutter/material.dart';

import '../data/project_repository.dart';
import '../data/win_repository.dart';
import '../l10n/strings_scope.dart';
import '../models/project.dart';
import '../models/win.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';
import '../widgets/area_tag.dart';
import '../widgets/intensity_stars.dart';
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

  void _showPrevious() {
    setState(() => _index = (_index - 1 + _wins.length) % _wins.length);
  }

  void _showNext() {
    setState(() => _index = (_index + 1) % _wins.length);
  }

  Future<void> _editCurrent() async {
    final current = _wins[_index];
    final result = await Navigator.of(context).push<AddWinResult>(
      MaterialPageRoute(
        builder: (_) => AddWinScreen(
          existingWin: current,
          contextProject: widget.projectsById[current.projectId],
          projectRepository: widget.projectRepository,
        ),
      ),
    );
    if (result == null) return;

    final updated = await widget.repository.update(
      id: current.id,
      title: result.title,
      description: result.description,
      projectId: result.projectId,
      intensity: result.intensity,
      date: result.date,
      photoPath: result.photoPath,
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
                                Icon(Icons.star, size: 30, color: colors.gold),
                                const SizedBox(height: 20),
                                Text(
                                  formatDisplayDateTime(win.date, strings),
                                  style: TextStyle(fontSize: 12, color: colors.crisisMuted),
                                ),
                                if (project != null) ...[
                                  const SizedBox(height: 12),
                                  AreaTag(area: project.area, iconSize: 18, fontSize: 17),
                                  const SizedBox(height: 6),
                                  ProjectTag(project: project, textColor: colors.crisisMuted),
                                ],
                                const SizedBox(height: 16),
                                Text(
                                  win.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                    color: colors.text,
                                  ),
                                ),
                                if (win.description != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    win.description!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 15, height: 1.6, color: colors.crisisMuted),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                IntensityStars(intensity: win.intensity, size: 18),
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

class _NavCircleButton extends StatelessWidget {
  const _NavCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 48, height: 48, child: Icon(icon, color: context.colors.text)),
      ),
    );
  }
}
