/// Every user-facing piece of text in the app, in one interface — resolved
/// per [SettingsController.locale] via `context.strings` (see
/// `strings_scope.dart`). Kept as a hand-written interface + one
/// implementation per language rather than Flutter's ARB/gen-l10n pipeline:
/// the language is a Settings choice here, not the device locale, and the
/// string set is small enough that a plain Dart class is simpler to read,
/// grep, and keep in sync than generated code.
abstract class AppStrings {
  String get languageCode;

  // Life areas
  String get areaPhysical;
  String get areaPsychological;
  String get areaProfessional;
  String get areaFinancial;
  String get areaPersonal;
  String get areaSocial;
  String get areaSpiritual;
  String get areaPhilanthropic;

  // Bottom navigation
  String get navHome;
  String get navSky;
  String get navStars;
  String get navSettings;

  // Home dashboard
  String get homeEyebrow;
  String get homeTitle;
  String get homeSubtitle;
  String get admireYourStars;
  String get totalStarsLabel;
  String get currentStreakLabel;
  String get longestStreakLabel;
  String get activityLabel;
  String get dayDetailEmpty;

  // Stars tab (browse by area + search)
  String get starsEyebrow;
  String get starsTitle;
  String get starsSubtitle;
  String get searchHint;
  String get noSearchResults;
  String get areaWinsEmpty;

  // Settings — data section (seed/reset, moved here from the old Home)
  String get dataSection;
  String get seedSampleData;
  String seedSampleDataResult(int count);
  String get resetAllData;
  String get resetAllDataConfirmTitle;
  String get resetAllDataConfirmBody;
  String get cancel;
  String get deleteEverything;
  String get allDataCleared;
  String get archiveEmpty;

  // Sky + area projects
  String get skyEyebrow;
  String get skyTitle;
  String get skySubtitle;
  String starsCount(int count);
  String get newProjectTooltip;
  String areaEmptyProjects(String areaName);

  // Constellation
  String get addWinTooltip;
  String get constellationShapeMissing;

  // New project
  String get newProjectEyebrow;
  String get newProjectQuestion;
  String get areaLabel;
  String get nameLabel;
  String get newProjectNameHint;
  String get iconLabel;
  String get createProject;
  String get newProject;

  // Add/edit win
  String get newStarEyebrow;
  String get editStarEyebrow;
  String get addWinQuestion;
  String get projectLabel;
  String get selectAProject;
  String get titleFieldLabel;
  String get titleHint;
  String get detailsLabel;
  String get detailsHint;
  String get intensityLabel;
  String get saveChanges;
  String get lightThisStar;

  // Admire Your Stars (random reflection, filterable by area)
  String get admireTagline;
  String get allAreasLabel;
  String get pickAtLeastOneArea;
  String get noStarsInSelection;
  String get viewYourStars;
  String get encouragementCta;

  // Home FAB + its long-press "create" menu
  String get addWinFabLabel;
  String get newConstellationOption;

  /// A fixed set of short, hand-written uplifting phrases — shown one at a
  /// time, shuffled, in [EncouragementScreen]. Not a translation of a
  /// single canonical list; each language's phrasing is its own.
  List<String> get upliftingQuotes;

  // Win reader
  String indexOfCount(int index, int total);

  // Settings
  String get settingsEyebrow;
  String get settingsTitle;
  String get appearanceSection;
  String get themeLight;
  String get themeDark;
  String get languageSection;
  String get languageEnglish;
  String get languageItalian;
  String get languageRomanian;
  String get reminderSection;
  String get reminderToggleLabel;
  String get reminderTimeLabel;
  String get notificationPermissionDenied;
  String get testNotificationButton;
  String get testNotificationSent;
  String get reminderNotificationTitle;

  /// A handful of varied notification body phrases, cycled through day by
  /// day so the reminder doesn't say the exact same thing every time.
  List<String> get reminderNotificationBodies;
  String get aboutSection;
  String aboutVersion(String version);
  String get aboutTagline;

  /// 12 short month abbreviations, January first, for [formatDisplayDate].
  List<String> get monthAbbreviations;

  /// 7 short weekday abbreviations, Monday first, for the dashboard's
  /// calendar header.
  List<String> get weekdayAbbreviations;

  /// The dashboard calendar's month heading, e.g. "August 2026".
  String monthTitle(DateTime month);
}
