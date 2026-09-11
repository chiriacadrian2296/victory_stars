import 'package:shared_preferences/shared_preferences.dart';

/// Whether the user has asked to stop seeing the "how this works" tutorial
/// dialog that greets a fresh `StarsShapeEditorScreen`. Its own tiny
/// SharedPreferences-backed flag rather than folding into
/// `SettingsRepository` — it's read and written entirely within that one
/// screen, so there's no reason to thread it through the app-wide
/// repository chain the way `StarsShapeRepository` is.
class ConstellationEditorPrefs {
  ConstellationEditorPrefs(this._prefs);

  static const _hideHelpKey = 'constellation-editor.hide-help';

  final SharedPreferences _prefs;

  static Future<ConstellationEditorPrefs> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ConstellationEditorPrefs(prefs);
  }

  bool get hideHelp => _prefs.getBool(_hideHelpKey) ?? false;

  Future<void> setHideHelp(bool value) => _prefs.setBool(_hideHelpKey, value);
}
