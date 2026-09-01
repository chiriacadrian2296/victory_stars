import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/life_area.dart';
import '../models/project.dart';

/// Reads and writes the user's projects as a single JSON-encoded list under
/// one [SharedPreferences] key, newest first — mirrors [StarRepository]'s
/// shape exactly, since the same "small list, always read/written whole"
/// reasoning applies here.
class ProjectRepository {
  ProjectRepository(this._prefs);

  static const _storageKey = 'projects-list';

  final SharedPreferences _prefs;

  static Future<ProjectRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ProjectRepository(prefs);
  }

  /// All projects currently stored, newest first.
  List<Project> getAll() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((entry) => Project.fromJson(entry as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Projects in [area], newest first.
  List<Project> getProjectsForArea(LifeArea area) {
    return getAll().where((p) => p.area == area).toList();
  }

  Future<Project> add({
    required String name,
    required LifeArea area,
    required String iconSlug,
    int? customConstellationId,
    String? description,
  }) async {
    final projects = getAll();
    final trimmedDescription = description?.trim();
    final project = Project(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name.trim(),
      area: area,
      iconSlug: iconSlug,
      customConstellationId: customConstellationId,
      description: (trimmedDescription == null || trimmedDescription.isEmpty)
          ? null
          : trimmedDescription,
      createdAt: DateTime.now(),
    );

    await _saveAll([project, ...projects]);
    return project;
  }

  /// Backfills a [Project] that predates the hand-drawn constellation editor
  /// (or was seeded without one) with a [CustomConstellation] created for
  /// it — see `backfillMissingConstellations`, the only caller. Keeps the
  /// project's position in the list. Throws if [projectId] doesn't match
  /// anything saved.
  Future<Project> assignCustomConstellation({
    required int projectId,
    required int customConstellationId,
  }) async {
    final projects = getAll();
    final index = projects.indexWhere((p) => p.id == projectId);
    if (index == -1) {
      throw StateError('No project found with id $projectId');
    }

    final updated = projects[index].copyWith(
      customConstellationId: customConstellationId,
    );
    projects[index] = updated;
    await _saveAll(projects);
    return updated;
  }

  /// Permanently deletes every project. Used by the "reset all data" action
  /// — there's no undo.
  Future<void> clear() async {
    await _prefs.remove(_storageKey);
  }

  Future<void> _saveAll(List<Project> projects) async {
    final encoded = jsonEncode(projects.map((p) => p.toJson()).toList());
    await _prefs.setString(_storageKey, encoded);
  }
}
