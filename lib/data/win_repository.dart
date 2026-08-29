import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/win.dart';
import 'photo_storage.dart';

/// Reads and writes the user's wins as a single JSON-encoded list under one
/// [SharedPreferences] key, newest first.
///
/// The whole list is small (personal milestones, not a high-volume log) and
/// is always read/written together, so there's no need for a real database:
/// this mirrors the storage shape already validated in the React prototype
/// (one string key holding the serialized array).
class WinRepository {
  WinRepository(this._prefs);

  // v3: wins now also carry an intensity (1-5). No real user data exists
  // yet, so this is a clean key bump rather than an in-place migration.
  static const _storageKey = 'wins-list-v3';

  final SharedPreferences _prefs;

  /// Creates a repository backed by the platform's [SharedPreferences]
  /// instance. Call once during app startup and reuse it — after this
  /// initial await, [getAll] reads from an in-memory cache and is
  /// synchronous.
  static Future<WinRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return WinRepository(prefs);
  }

  /// All wins currently stored, newest first by [Win.date] (ties broken by
  /// [Win.id]) — sorted explicitly rather than relying on storage order,
  /// since backdated wins (e.g. seed data) can be added out of date order.
  /// Never throws on missing or corrupted data — returns an empty list
  /// instead, since a blank archive is a safe fallback for a personal-
  /// growth log.
  List<Win> getAll() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final wins = decoded.map((entry) => Win.fromJson(entry as Map<String, dynamic>)).toList();
      wins.sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : b.id.compareTo(a.id);
      });
      return wins;
    } catch (_) {
      return const [];
    }
  }

  /// Wins belonging to [projectId], oldest first. This ordering is what a
  /// constellation's star slots are assigned against, so it lives here once
  /// rather than being re-derived (and risking a reversed order) at each
  /// call site.
  ///
  /// A win's position in this list is its star-slot index — nothing stores
  /// that index directly, so [delete]ing a win shifts every later win in
  /// the same project up one slot, moving their stars along with it. Same
  /// idea as reordering photos in a gallery grid: expected, not a bug.
  List<Win> getAllForProject(int projectId) {
    return getAll().where((w) => w.projectId == projectId).toList().reversed.toList();
  }

  /// Records a new win and persists the updated list. [number] is assigned
  /// automatically as one more than the highest existing number. [date]
  /// defaults to now; callers that backdate wins (e.g. seed data) can pass
  /// an explicit date — [id] still comes from the real creation time, so
  /// uniqueness never depends on the (possibly backdated, possibly
  /// colliding) [date].
  Future<Win> add({
    required String title,
    String? description,
    required int projectId,
    required int intensity,
    DateTime? date,
    String? photoPath,
  }) async {
    final wins = getAll();
    final nextNumber = wins.fold<int>(0, (max, w) => w.number > max ? w.number : max) + 1;
    final trimmedDescription = description?.trim();

    final win = Win(
      id: DateTime.now().millisecondsSinceEpoch,
      number: nextNumber,
      projectId: projectId,
      title: title.trim(),
      description: (trimmedDescription == null || trimmedDescription.isEmpty) ? null : trimmedDescription,
      date: date ?? DateTime.now(),
      intensity: intensity,
      photoPath: photoPath,
    );

    await _saveAll([win, ...wins]);
    return win;
  }

  /// Updates the title/description/project/intensity/date of the win
  /// identified by [id], keeping its number unchanged. Throws a
  /// [StateError] if no win with that id exists — callers always resolve it
  /// from a currently-displayed [Win], so a missing id would mean the list
  /// changed under them.
  ///
  /// Reassigning [projectId] moves the win's star to the new project's
  /// constellation immediately (star slots are derived from
  /// [getAllForProject], never stored) — but since every other win in the
  /// *old* project shifts up one slot to fill the gap, their star positions
  /// can visibly move too. Same underlying assumption as [getAllForProject]
  /// applies here — see its doc comment.
  Future<Win> update({
    required int id,
    required String title,
    String? description,
    required int projectId,
    required int intensity,
    required DateTime date,
    String? photoPath,
  }) async {
    final wins = getAll();
    final index = wins.indexWhere((w) => w.id == id);
    if (index == -1) {
      throw StateError('No win found with id $id');
    }

    final previousPhotoPath = wins[index].photoPath;
    final trimmedDescription = description?.trim();
    final updated = Win(
      id: wins[index].id,
      number: wins[index].number,
      projectId: projectId,
      title: title.trim(),
      description: (trimmedDescription == null || trimmedDescription.isEmpty) ? null : trimmedDescription,
      date: date,
      intensity: intensity,
      photoPath: photoPath,
    );

    final nextWins = [...wins]..[index] = updated;
    await _saveAll(nextWins);

    // A replaced or removed photo leaves its old file behind otherwise —
    // this is the one place that knows both the old and new path.
    if (previousPhotoPath != null && previousPhotoPath != photoPath) {
      await PhotoStorage.delete(previousPhotoPath);
    }

    return updated;
  }

  /// Permanently deletes the win identified by [id], and its photo file if
  /// it had one. Silently does nothing if no win with that id exists —
  /// deleting something already gone isn't an error worth surfacing.
  Future<void> delete(int id) async {
    final wins = getAll();
    final index = wins.indexWhere((w) => w.id == id);
    if (index == -1) return;

    final photoPath = wins[index].photoPath;
    final nextWins = [...wins]..removeAt(index);
    await _saveAll(nextWins);

    if (photoPath != null) {
      await PhotoStorage.delete(photoPath);
    }
  }

  /// Permanently deletes every win. Used by the "reset all data" action —
  /// there's no undo.
  Future<void> clear() async {
    await _prefs.remove(_storageKey);
  }

  Future<void> _saveAll(List<Win> wins) async {
    final encoded = jsonEncode(wins.map((w) => w.toJson()).toList());
    await _prefs.setString(_storageKey, encoded);
  }
}
