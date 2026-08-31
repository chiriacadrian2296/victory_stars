import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit_completion.dart';

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Reads and writes every habit's daily completions as a single JSON-encoded
/// list under one [SharedPreferences] key — kept separate from [Habit]
/// itself (rather than embedded in it) so editing a habit's title never has
/// to read/write years of accumulated completion dates, and so stats
/// utilities can bucket by day the same way `star_stats.dart` already does
/// for stars.
class HabitCompletionRepository {
  HabitCompletionRepository(this._prefs);

  static const _storageKey = 'habit-completions-list-v1';

  final SharedPreferences _prefs;

  static Future<HabitCompletionRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return HabitCompletionRepository(prefs);
  }

  List<HabitCompletion> getAll() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map(
            (entry) => HabitCompletion.fromJson(entry as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<HabitCompletion> getAllForHabit(int habitId) {
    return getAll().where((c) => c.habitId == habitId).toList();
  }

  /// Marks [habitId] done for [date] (defaults to today), normalized to
  /// day-only. Idempotent — a habit already marked done that day is left
  /// untouched, at most one completion record per (habit, day).
  Future<void> markDone(int habitId, {DateTime? date}) async {
    final day = _dateOnly(date ?? DateTime.now());
    final completions = getAll();
    final alreadyDone = completions.any(
      (c) => c.habitId == habitId && c.date == day,
    );
    if (alreadyDone) return;

    final completion = HabitCompletion(
      id: DateTime.now().microsecondsSinceEpoch,
      habitId: habitId,
      date: day,
    );
    await _saveAll([completion, ...completions]);
  }

  /// Undoes a mis-tap: removes [habitId]'s completion record for [date] (day
  /// granularity), if any.
  Future<void> unmarkDone(int habitId, DateTime date) async {
    final day = _dateOnly(date);
    final completions = getAll();
    final nextCompletions = completions
        .where((c) => !(c.habitId == habitId && c.date == day))
        .toList();
    await _saveAll(nextCompletions);
  }

  /// Permanently removes every completion for [habitId] — called by
  /// [HabitRepository.delete], since a deleted habit has no tombstone to
  /// keep its history attached to.
  Future<void> deleteAllForHabit(int habitId) async {
    final completions = getAll();
    final nextCompletions = completions
        .where((c) => c.habitId != habitId)
        .toList();
    await _saveAll(nextCompletions);
  }

  Future<void> clear() async {
    await _prefs.remove(_storageKey);
  }

  Future<void> _saveAll(List<HabitCompletion> completions) async {
    final encoded = jsonEncode(completions.map((c) => c.toJson()).toList());
    await _prefs.setString(_storageKey, encoded);
  }
}
