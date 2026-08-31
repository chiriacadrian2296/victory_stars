import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';
import 'habit_completion_repository.dart';

/// Reads and writes the user's habits as a single JSON-encoded list under
/// one [SharedPreferences] key — mirrors [StarRepository]'s shape exactly.
class HabitRepository {
  HabitRepository(this._prefs);

  static const _storageKey = 'habits-list-v1';

  final SharedPreferences _prefs;

  static Future<HabitRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return HabitRepository(prefs);
  }

  List<Habit> getAll() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((entry) => Habit.fromJson(entry as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<Habit> getAllForProject(int projectId) {
    return getAll().where((h) => h.projectId == projectId).toList();
  }

  Future<Habit> add({
    required String title,
    String? description,
    required int projectId,
    int? reminderHour,
    int? reminderMinute,
  }) async {
    final habits = getAll();
    final trimmedDescription = description?.trim();
    final habit = Habit(
      id: DateTime.now().millisecondsSinceEpoch,
      projectId: projectId,
      title: title.trim(),
      description: (trimmedDescription == null || trimmedDescription.isEmpty)
          ? null
          : trimmedDescription,
      createdAt: DateTime.now(),
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
    );

    await _saveAll([habit, ...habits]);
    return habit;
  }

  Future<Habit> update({
    required int id,
    required String title,
    String? description,
    required int projectId,
    int? reminderHour,
    int? reminderMinute,
  }) async {
    final habits = getAll();
    final index = habits.indexWhere((h) => h.id == id);
    if (index == -1) {
      throw StateError('No habit found with id $id');
    }
    final existing = habits[index];
    final trimmedDescription = description?.trim();
    final updated = Habit(
      id: existing.id,
      projectId: projectId,
      title: title.trim(),
      description: (trimmedDescription == null || trimmedDescription.isEmpty)
          ? null
          : trimmedDescription,
      createdAt: existing.createdAt,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
    );

    final nextHabits = [...habits]..[index] = updated;
    await _saveAll(nextHabits);
    return updated;
  }

  /// Permanently deletes the habit identified by [id] and every completion
  /// it ever logged (via [completionRepository]) — unlike a [Star], a habit
  /// has no tombstone/resurrect concept, since there's no constellation slot
  /// of its own to preserve.
  Future<void> delete(
    int id, {
    required HabitCompletionRepository completionRepository,
  }) async {
    final habits = getAll();
    final index = habits.indexWhere((h) => h.id == id);
    if (index == -1) return;

    final nextHabits = [...habits]..removeAt(index);
    await _saveAll(nextHabits);
    await completionRepository.deleteAllForHabit(id);
  }

  Future<void> clear() async {
    await _prefs.remove(_storageKey);
  }

  Future<void> _saveAll(List<Habit> habits) async {
    final encoded = jsonEncode(habits.map((h) => h.toJson()).toList());
    await _prefs.setString(_storageKey, encoded);
  }
}
