import 'package:flutter/material.dart';

import '../data/project_repository.dart';
import '../data/win_repository.dart';
import '../l10n/strings_scope.dart';
import '../models/life_area.dart';
import '../models/project.dart';
import '../models/win.dart';
import '../theme/app_colors.dart';
import '../widgets/win_card.dart';
import 'win_reader_screen.dart';

/// A flat, searchable list of every win in [area] (across all of that
/// area's projects), newest first — the Stars tab's second step after
/// picking an area. Search matches title or description, case-insensitive.
class AreaWinsScreen extends StatefulWidget {
  const AreaWinsScreen({super.key, required this.area, required this.projectRepository, required this.winRepository});

  final LifeArea area;
  final ProjectRepository projectRepository;
  final WinRepository winRepository;

  @override
  State<AreaWinsScreen> createState() => _AreaWinsScreenState();
}

class _AreaWinsScreenState extends State<AreaWinsScreen> {
  String _query = '';
  late Map<int, Project> _projectsById = _loadProjectsById();
  late List<Win> _areaWins = _loadAreaWins();

  Map<int, Project> _loadProjectsById() {
    return {
      for (final project in widget.projectRepository.getProjectsForArea(widget.area)) project.id: project,
    };
  }

  List<Win> _loadAreaWins() {
    final projectIds = _projectsById.keys.toSet();
    return widget.winRepository.getAll().where((w) => projectIds.contains(w.projectId)).toList();
  }

  List<Win> get _filteredWins {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _areaWins;
    return _areaWins.where((w) {
      return w.title.toLowerCase().contains(query) || (w.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _refresh() {
    setState(() {
      _projectsById = _loadProjectsById();
      _areaWins = _loadAreaWins();
    });
  }

  Future<void> _openWinReader(List<Win> wins, int index) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WinReaderScreen(
          repository: widget.winRepository,
          initialWins: wins,
          startIndex: index,
          allowEdit: true,
          projectsById: _projectsById,
          projectRepository: widget.projectRepository,
          refreshWins: () {
            _projectsById = _loadProjectsById();
            _areaWins = _loadAreaWins();
            return _filteredWins;
          },
        ),
      ),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final wins = _filteredWins;

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
                    widget.area.displayName(strings),
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: colors.text),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                style: TextStyle(color: colors.text, fontSize: 15),
                decoration: InputDecoration(
                  hintText: strings.searchHint,
                  prefixIcon: Icon(Icons.search, color: colors.muted, size: 20),
                ),
              ),
            ),
            Expanded(
              child: _areaWins.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Center(
                        child: Text(
                          strings.areaWinsEmpty,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: colors.muted),
                        ),
                      ),
                    )
                  : wins.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Center(
                            child: Text(
                              strings.noSearchResults,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: colors.muted),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: wins.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final win = wins[index];
                            return WinCard(
                              win: win,
                              project: _projectsById[win.projectId],
                              onTap: () => _openWinReader(wins, index),
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
