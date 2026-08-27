import 'package:flutter/material.dart';

import '../data/project_repository.dart';
import '../data/win_repository.dart';
import '../l10n/strings_scope.dart';
import '../models/life_area.dart';
import '../models/project.dart';
import '../models/win.dart';
import '../theme/app_colors.dart';
import 'win_reader_screen.dart';

/// Entry point for reflecting on saved wins — reachable from every tab
/// (see [RootScreen]'s persistent floating button), not tied to a "crisis"
/// moment specifically. Asks which life areas to draw from every time
/// (defaulting to all), then shows a shuffled, editable browse of every win
/// in that selection via [WinReaderScreen].
class AdmireStarsScreen extends StatefulWidget {
  const AdmireStarsScreen({super.key, required this.winRepository, required this.projectRepository});

  final WinRepository winRepository;
  final ProjectRepository projectRepository;

  @override
  State<AdmireStarsScreen> createState() => _AdmireStarsScreenState();
}

class _AdmireStarsScreenState extends State<AdmireStarsScreen> {
  Set<LifeArea> _selected = {...LifeArea.values};

  bool get _allSelected => _selected.length == LifeArea.values.length;

  void _toggleAll() {
    setState(() => _selected = _allSelected ? {} : {...LifeArea.values});
  }

  void _toggleArea(LifeArea area) {
    setState(() {
      if (!_selected.remove(area)) _selected.add(area);
    });
  }

  Map<int, Project> _projectsById() {
    return {for (final project in widget.projectRepository.getAll()) project.id: project};
  }

  List<Win> _poolForSelection() {
    final projectsById = _projectsById();
    return widget.winRepository.getAll().where((w) {
      final project = projectsById[w.projectId];
      return project != null && _selected.contains(project.area);
    }).toList();
  }

  Future<void> _start() async {
    final pool = _poolForSelection();
    if (pool.isEmpty) return;

    final shuffled = [...pool]..shuffle();
    final shuffledIds = shuffled.map((w) => w.id).toList();
    final selectionSnapshot = Set<LifeArea>.from(_selected);

    List<Win> currentInShuffledOrder() {
      final projectsById = _projectsById();
      final byId = {for (final w in widget.winRepository.getAll()) w.id: w};
      return shuffledIds
          .map((id) => byId[id])
          .whereType<Win>()
          .where((w) {
            final project = projectsById[w.projectId];
            return project != null && selectionSnapshot.contains(project.area);
          })
          .toList();
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WinReaderScreen(
          repository: widget.winRepository,
          initialWins: shuffled,
          startIndex: 0,
          allowEdit: true,
          projectsById: _projectsById(),
          projectRepository: widget.projectRepository,
          refreshWins: currentInShuffledOrder,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final poolSize = _poolForSelection().length;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.crisisGradient),
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: colors.crisisMuted),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        strings.admireYourStars,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        strings.admireTagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, height: 1.5, color: colors.crisisMuted),
                      ),
                      const SizedBox(height: 32),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _AreaChip(
                          label: strings.allAreasLabel,
                          selected: _allSelected,
                          onTap: _toggleAll,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final area in LifeArea.values)
                            _AreaChip(
                              label: area.displayName(strings),
                              icon: area.icon,
                              selected: _selected.contains(area),
                              onTap: () => _toggleArea(area),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                child: Column(
                  children: [
                    Text(
                      poolSize == 0 ? strings.pickAtLeastOneArea : strings.starsCount(poolSize),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: colors.crisisMuted),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: poolSize == 0 ? null : _start,
                        icon: const Icon(Icons.auto_awesome, size: 17),
                        label: Text(strings.viewYourStars),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.gold,
                          foregroundColor: colors.onGold,
                          disabledBackgroundColor: colors.crisisMuted.withValues(alpha: 0.15),
                          disabledForegroundColor: colors.crisisMuted,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AreaChip extends StatelessWidget {
  const _AreaChip({required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? colors.gold.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: selected ? colors.gold : colors.crisisMuted.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle : (icon ?? Icons.circle_outlined),
              size: 15,
              color: selected ? colors.gold : colors.crisisMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? colors.gold : colors.crisisMuted,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
