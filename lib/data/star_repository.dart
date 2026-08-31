import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/star.dart';
import 'photo_storage.dart';

/// Reads and writes the user's stars (victories and goals together — see
/// [Star]) as a single JSON-encoded list under one [SharedPreferences] key.
///
/// The whole list is small (personal milestones, not a high-volume log) and
/// is always read/written together, so there's no need for a real database.
class StarRepository {
  StarRepository(this._prefs);

  static const _storageKey = 'stars-list-v1';

  final SharedPreferences _prefs;

  /// Creates a repository backed by the platform's [SharedPreferences]
  /// instance. Call once during app startup and reuse it — after this
  /// initial await, [getAll] reads from an in-memory cache and is
  /// synchronous.
  static Future<StarRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StarRepository(prefs);
  }

  /// Every star currently stored, of every kind and every project — sorted
  /// by [Star.achievedDate] (falling back to [Star.createdAt] for a goal or
  /// a dead star that never had one), newest first, ties broken by [Star.id].
  /// Never throws on missing or corrupted data — returns an empty list
  /// instead, since a blank archive is a safe fallback for a personal-growth
  /// log.
  List<Star> getAll() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final stars = decoded
          .map((entry) => Star.fromJson(entry as Map<String, dynamic>))
          .toList();
      stars.sort((a, b) {
        final aKey = a.achievedDate ?? a.createdAt;
        final bKey = b.achievedDate ?? b.createdAt;
        final byDate = bKey.compareTo(aKey);
        return byDate != 0 ? byDate : b.id.compareTo(a.id);
      });
      return stars;
    } catch (_) {
      return const [];
    }
  }

  /// Every star belonging to [projectId] (victories, goals, and dead stars
  /// all together), sorted by [Star.slotSequence] — this is the order a
  /// constellation's star slots are assigned against, so it lives here once
  /// rather than being re-derived at each call site.
  List<Star> getAllForProject(int projectId) {
    final stars = getAll().where((s) => s.projectId == projectId).toList();
    stars.sort((a, b) => a.slotSequence.compareTo(b.slotSequence));
    return stars;
  }

  /// Records a new star. Pass [achievedDate] (and [intensity]) to log a
  /// victory directly; leave both null to create a goal instead.
  ///
  /// [slotSequence] is assigned automatically as one more than the highest
  /// existing slot in this project — permanent from here on, regardless of
  /// what happens to the star later. [number] ("this is your Nth victory")
  /// is assigned only if [achievedDate] is given.
  Future<Star> add({
    required String title,
    String? description,
    required int projectId,
    DateTime? targetDate,
    DateTime? achievedDate,
    int? intensity,
    String? photoPath,
  }) async {
    final stars = getAll();
    final nextSlot =
        stars
            .where((s) => s.projectId == projectId)
            .fold<int>(
              0,
              (max, s) => s.slotSequence > max ? s.slotSequence : max,
            ) +
        1;
    final trimmedDescription = description?.trim();

    final star = Star(
      id: DateTime.now().millisecondsSinceEpoch,
      projectId: projectId,
      slotSequence: nextSlot,
      number: achievedDate == null ? null : _nextNumber(stars),
      title: title.trim(),
      description: (trimmedDescription == null || trimmedDescription.isEmpty)
          ? null
          : trimmedDescription,
      createdAt: DateTime.now(),
      targetDate: targetDate,
      achievedDate: achievedDate,
      intensity: achievedDate == null ? null : intensity,
      photoPath: photoPath,
    );

    await _saveAll([star, ...stars]);
    return star;
  }

  /// Updates the title/description/project/target date/achieved state of
  /// the star identified by [id]. Never touches [Star.slotSequence] — that's
  /// permanent from creation. [Star.number] is assigned fresh if this update
  /// is what first sets [achievedDate], and cleared if it's what clears it
  /// back to null.
  ///
  /// Throws a [StateError] if no star with that id exists — callers always
  /// resolve it from a currently-displayed [Star], so a missing id would
  /// mean the list changed under them.
  Future<Star> update({
    required int id,
    required String title,
    String? description,
    required int projectId,
    DateTime? targetDate,
    DateTime? achievedDate,
    int? intensity,
    String? photoPath,
  }) async {
    final stars = getAll();
    final index = stars.indexWhere((s) => s.id == id);
    if (index == -1) {
      throw StateError('No star found with id $id');
    }
    final existing = stars[index];
    final trimmedDescription = description?.trim();

    int? number;
    if (achievedDate != null && existing.achievedDate == null) {
      number = _nextNumber(stars);
    } else if (achievedDate != null) {
      number = existing.number;
    }

    final updated = Star(
      id: existing.id,
      projectId: projectId,
      slotSequence: existing.slotSequence,
      number: number,
      title: title.trim(),
      description: (trimmedDescription == null || trimmedDescription.isEmpty)
          ? null
          : trimmedDescription,
      createdAt: existing.createdAt,
      targetDate: targetDate,
      achievedDate: achievedDate,
      intensity: achievedDate == null ? null : intensity,
      photoPath: photoPath,
      dead: existing.dead,
    );

    final nextStars = [...stars]..[index] = updated;
    await _saveAll(nextStars);

    final previousPhotoPath = existing.photoPath;
    if (previousPhotoPath != null && previousPhotoPath != photoPath) {
      await PhotoStorage.delete(previousPhotoPath);
    }

    return updated;
  }

  /// Quick "log it now" action for a goal, without going through the full
  /// edit form: sets [Star.achievedDate]/[Star.intensity] and assigns a
  /// fresh [Star.number].
  Future<Star> markAchieved(
    int id, {
    DateTime? achievedDate,
    required int intensity,
    String? photoPath,
  }) async {
    final stars = getAll();
    final index = stars.indexWhere((s) => s.id == id);
    if (index == -1) {
      throw StateError('No star found with id $id');
    }
    final existing = stars[index];
    final updated = Star(
      id: existing.id,
      projectId: existing.projectId,
      slotSequence: existing.slotSequence,
      number: _nextNumber(stars),
      title: existing.title,
      description: existing.description,
      createdAt: existing.createdAt,
      targetDate: existing.targetDate,
      achievedDate: achievedDate ?? DateTime.now(),
      intensity: intensity,
      photoPath: photoPath ?? existing.photoPath,
      dead: existing.dead,
    );

    final nextStars = [...stars]..[index] = updated;
    await _saveAll(nextStars);
    return updated;
  }

  /// Undoes [markAchieved] (or an edit that achieved this star): clears
  /// [Star.achievedDate]/[Star.intensity]/[Star.number], turning it back
  /// into an unlit goal. The photo, if any, is left alone — it isn't tied
  /// exclusively to being achieved.
  Future<Star> markNotAchieved(int id) async {
    final stars = getAll();
    final index = stars.indexWhere((s) => s.id == id);
    if (index == -1) {
      throw StateError('No star found with id $id');
    }
    final existing = stars[index];
    final updated = Star(
      id: existing.id,
      projectId: existing.projectId,
      slotSequence: existing.slotSequence,
      title: existing.title,
      description: existing.description,
      createdAt: existing.createdAt,
      targetDate: existing.targetDate,
      photoPath: existing.photoPath,
      dead: existing.dead,
    );

    final nextStars = [...stars]..[index] = updated;
    await _saveAll(nextStars);
    return updated;
  }

  /// "Deletes" the star identified by [id] — but never actually removes its
  /// record. Only [Star.dead] flips to true, so its [Star.slotSequence]
  /// stays occupied forever and no other star in the project ever shifts
  /// position. Everything else about the star (title, description, whether
  /// it was achieved) is left exactly as it was, ready to be inspected or
  /// brought back via [resurrect].
  Future<Star> delete(int id) async {
    final stars = getAll();
    final index = stars.indexWhere((s) => s.id == id);
    if (index == -1) {
      throw StateError('No star found with id $id');
    }
    final updated = stars[index].copyWith(dead: true);
    final nextStars = [...stars]..[index] = updated;
    await _saveAll(nextStars);
    return updated;
  }

  /// Brings a dead star back to life as a new star — same [id] and
  /// [Star.slotSequence] (so its place in the constellation never changes),
  /// entirely new content otherwise. A fresh [Star.number] is assigned if
  /// [achievedDate] is given (never the star's old number, even if it had
  /// one before being deleted).
  Future<Star> resurrect(
    int id, {
    required String title,
    String? description,
    required int projectId,
    DateTime? targetDate,
    DateTime? achievedDate,
    int? intensity,
    String? photoPath,
  }) async {
    final stars = getAll();
    final index = stars.indexWhere((s) => s.id == id);
    if (index == -1) {
      throw StateError('No star found with id $id');
    }
    final existing = stars[index];
    final trimmedDescription = description?.trim();

    final updated = Star(
      id: existing.id,
      projectId: projectId,
      slotSequence: existing.slotSequence,
      number: achievedDate == null ? null : _nextNumber(stars),
      title: title.trim(),
      description: (trimmedDescription == null || trimmedDescription.isEmpty)
          ? null
          : trimmedDescription,
      createdAt: existing.createdAt,
      targetDate: targetDate,
      achievedDate: achievedDate,
      intensity: achievedDate == null ? null : intensity,
      photoPath: photoPath,
    );

    final nextStars = [...stars]..[index] = updated;
    await _saveAll(nextStars);

    if (existing.photoPath != null && existing.photoPath != photoPath) {
      await PhotoStorage.delete(existing.photoPath!);
    }

    return updated;
  }

  /// Permanently deletes every star. Used by the "reset all data" action —
  /// there's no undo. Unlike [delete], this really does erase everything;
  /// tombstoning has no purpose once the whole archive is being wiped.
  Future<void> clear() async {
    await _prefs.remove(_storageKey);
  }

  int _nextNumber(List<Star> stars) {
    return stars.fold<int>(
          0,
          (max, s) => (s.number ?? 0) > max ? s.number! : max,
        ) +
        1;
  }

  Future<void> _saveAll(List<Star> stars) async {
    final encoded = jsonEncode(stars.map((s) => s.toJson()).toList());
    await _prefs.setString(_storageKey, encoded);
  }
}
