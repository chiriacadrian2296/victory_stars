import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/win.dart';

/// Reads and writes the user's wins as a single JSON-encoded list under one
/// [SharedPreferences] key, newest first.
///
/// The whole list is small (personal milestones, not a high-volume log) and
/// is always read/written together, so there's no need for a real database:
/// this mirrors the storage shape already validated in the React prototype
/// (one string key holding the serialized array).
class WinRepository {
  WinRepository(this._prefs);

  static const _storageKey = 'wins-list';

  final SharedPreferences _prefs;

  /// Creates a repository backed by the platform's [SharedPreferences]
  /// instance. Call once during app startup and reuse it — after this
  /// initial await, [getAll] reads from an in-memory cache and is
  /// synchronous.
  static Future<WinRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return WinRepository(prefs);
  }

  /// All wins currently stored, newest first. Never throws on missing or
  /// corrupted data — returns an empty list instead, since a blank archive
  /// is a safe fallback for a personal-growth log.
  List<Win> getAll() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((entry) => Win.fromJson(entry as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Records a new win and persists the updated list. [number] is assigned
  /// automatically as one more than the highest existing number.
  Future<Win> add({required String title, String? description}) async {
    final wins = getAll();
    final nextNumber = wins.fold<int>(0, (max, w) => w.number > max ? w.number : max) + 1;
    final trimmedDescription = description?.trim();

    final win = Win(
      id: DateTime.now().millisecondsSinceEpoch,
      number: nextNumber,
      title: title.trim(),
      description: (trimmedDescription == null || trimmedDescription.isEmpty) ? null : trimmedDescription,
      date: DateTime.now(),
    );

    await _saveAll([win, ...wins]);
    return win;
  }

  Future<void> _saveAll(List<Win> wins) async {
    final encoded = jsonEncode(wins.map((w) => w.toJson()).toList());
    await _prefs.setString(_storageKey, encoded);
  }
}
