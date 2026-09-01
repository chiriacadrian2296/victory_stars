import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/custom_constellation.dart';
import 'constellation_shapes_v2.dart';

/// Reads and writes the user's hand-drawn constellation shapes as a single
/// JSON-encoded list under one [SharedPreferences] key, newest first —
/// mirrors [ProjectRepository]'s shape exactly, since the same "small list,
/// always read/written whole" reasoning applies here.
class CustomConstellationRepository {
  CustomConstellationRepository(this._prefs);

  static const _storageKey = 'custom-constellations-list';

  final SharedPreferences _prefs;

  static Future<CustomConstellationRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return CustomConstellationRepository(prefs);
  }

  /// All saved custom shapes, newest first.
  List<CustomConstellation> getAll() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map(
            (entry) =>
                CustomConstellation.fromJson(entry as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  CustomConstellation? getById(int id) {
    for (final shape in getAll()) {
      if (shape.id == id) return shape;
    }
    return null;
  }

  Future<CustomConstellation> add({
    required String name,
    required ConstellationShape shape,
  }) async {
    final shapes = getAll();
    final created = CustomConstellation(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name.trim(),
      shape: shape,
      createdAt: DateTime.now(),
    );

    await _saveAll([created, ...shapes]);
    return created;
  }

  /// Replaces the name/shape of an existing custom constellation in place,
  /// keeping its [CustomConstellation.id] (so any [Project.customConstellationId]
  /// referencing it keeps pointing at the right thing) and its position in
  /// the list (unlike [add], this doesn't move it to the front — editing
  /// isn't "creating something new"). Throws if [id] doesn't match anything
  /// saved.
  Future<CustomConstellation> update({
    required int id,
    required String name,
    required ConstellationShape shape,
  }) async {
    final shapes = getAll();
    final index = shapes.indexWhere((s) => s.id == id);
    if (index == -1) {
      throw StateError('No custom constellation found with id $id');
    }

    final updated = CustomConstellation(
      id: id,
      name: name.trim(),
      shape: shape,
      createdAt: shapes[index].createdAt,
    );
    shapes[index] = updated;
    await _saveAll(shapes);
    return updated;
  }

  /// Permanently deletes every custom shape. Used by the "reset all data"
  /// action — there's no undo.
  Future<void> clear() async {
    await _prefs.remove(_storageKey);
  }

  Future<void> _saveAll(List<CustomConstellation> shapes) async {
    final encoded = jsonEncode(shapes.map((s) => s.toJson()).toList());
    await _prefs.setString(_storageKey, encoded);
  }
}
