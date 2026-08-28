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

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.crisisGradient),
        child: SafeArea(
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
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
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
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: colors.crisisMuted,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          IntensityStars(intensity: win.intensity, size: 18),
                        ],
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
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: context.colors.text),
        ),
      ),
    );
  }
}
