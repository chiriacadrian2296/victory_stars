import 'package:shared_preferences/shared_preferences.dart';

/// Reads and writes user-facing app settings (theme, language, daily
/// reminder). Each setting is its own [SharedPreferences] key rather than
/// one JSON blob — unlike [WinRepository]/[ProjectRepository]'s lists,
/// these are independent scalars with no shared ordering to preserve.
class SettingsRepository {
  SettingsRepository(this._prefs);

  static const _themeModeKey = 'settings.themeMode';
  static const _localeKey = 'settings.locale';
  static const _reminderEnabledKey = 'settings.reminderEnabled';
  static const _reminderHourKey = 'settings.reminderHour';
  static const _reminderMinuteKey = 'settings.reminderMinute';

  final SharedPreferences _prefs;

  static Future<SettingsRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsRepository(prefs);
  }

  /// 'dark' or 'light'. Defaults to 'dark' — the app's original palette.
  String get themeMode => _prefs.getString(_themeModeKey) ?? 'dark';

  Future<void> setThemeMode(String mode) => _prefs.setString(_themeModeKey, mode);

  /// 'en', 'it', or 'ro'. Defaults to 'en'.
  String get locale => _prefs.getString(_localeKey) ?? 'en';

  Future<void> setLocale(String code) => _prefs.setString(_localeKey, code);

  bool get reminderEnabled => _prefs.getBool(_reminderEnabledKey) ?? false;

  /// Hour/minute default to 20:00 the first time the reminder is turned on.
  int get reminderHour => _prefs.getInt(_reminderHourKey) ?? 20;

  int get reminderMinute => _prefs.getInt(_reminderMinuteKey) ?? 0;

  Future<void> setReminder({required bool enabled, required int hour, required int minute}) async {
    await _prefs.setBool(_reminderEnabledKey, enabled);
    await _prefs.setInt(_reminderHourKey, hour);
    await _prefs.setInt(_reminderMinuteKey, minute);
  }
}
