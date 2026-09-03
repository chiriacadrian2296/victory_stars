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
  String get areaPhysicalDescription;
  String get areaPsychologicalDescription;
  String get areaProfessionalDescription;
  String get areaFinancialDescription;
  String get areaPersonalDescription;
  String get areaSocialDescription;
  String get areaSpiritualDescription;
  String get areaPhilanthropicDescription;

  // Bottom navigation
  String get navHome;
  String get navSky;
  String get navGalaxy;
  String get navStats;
  String get navSettings;
  String get collapseSidebarAction;
  String get expandSidebarAction;

  // Statistics tab
  String get statsEyebrow;
  String get statsTitle;

  // Home dashboard
  String get homeEyebrow;
  String get homeTitle;
  String get homeSubtitle;
  String get admireYourStars;
  String get todayStarSectionLabel;
  String get litTodayTitle;
  String get litTodayTitleHighlight;
  String get litTodaySubtitle;
  String get litTodaySubtitleHighlight;
  String get notLitTodayLabel;
  String get notLitTodayHighlight;
  String get lightStarCta;
  String get totalStarsLabel;
  String get streaksSectionLabel;
  String get currentStreakLabel;
  String get longestStreakLabel;
  String get activityLabel;
  String get dayDetailEmpty;
  String get addStarForDayLabel;

  // Stat detail screens (tapping Total Stars / Current Streak / Longest
  // Streak on the dashboard)
  String get firstStarLabel;
  String get mostRecentStarLabel;
  String get combinedIntensityLabel;
  String get starsByAreaLabel;
  String get streakFromLabel;
  String get streakToLabel;
  String get todayLabel;
  String get starsLoggedLabel;
  String get noCurrentStreakBody;

  // Area detail (constellations / list view switch)
  String get searchHint;
  String get noSearchResults;
  String get skyEmptyConstellations;
  String get skyEmptyStars;

  // Constellation card stats (Sky > area > Constellations view)
  String intensityCount(int value);
  String createdOnLabel(String date);
  String lastStarLabel(String date);

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
  String areaEmptyProjects(String areaName);
  String get constellationsModeLabel;
  String get listModeLabel;
  String get skyModeSupernovas;
  String get filterAreasAction;
  String get applyAreaFilterAction;
  String get filterKindSectionTitle;
  String get allKindsLabel;

  // Area detail (the vision text, description, and big stat numbers for a
  // single Supernova)
  String get areaVisionLabel;
  String get areaVisionHint;
  String get editVisionAction;
  String get areaConstellationsStatLabel;
  String get areaStarsStatLabel;
  String get areaIntensityStatLabel;

  // Constellation
  String get constellationShapeMissing;

  // Constellation editor (hand-drawn custom shapes)
  String get drawYourOwnConstellation;
  String get drawYourOwnShort;
  String get constellationEditorTitle;
  String get constellationEditorEditTitle;
  String get constellationEditorEmptyHint;
  String constellationEditorDisconnectedWarning(int count);
  String get constellationEditorPointCapReached;
  String get undoAction;
  String get redoAction;
  String get deletePointAction;
  String get saveConstellationAction;
  String get nameYourConstellationTitle;
  String get constellationNameHint;
  String get yourConstellationsLabel;
  String get constellationEditorGridToggleLabel;
  String get constellationEditorHelpAction;
  String get constellationEditorHelpTitle;
  String get constellationEditorHelpAddPoint;
  String get constellationEditorHelpConnectPoint;
  String get constellationEditorHelpDisarmPoint;
  String get constellationEditorHelpMovePoint;
  String get constellationEditorHelpDeletePoint;
  String get constellationEditorHelpDontShowAgain;
  String get constellationEditorHelpClose;

  // New project
  String get newProjectEyebrow;
  String get newProjectQuestion;
  String get areaLabel;
  String get nameLabel;
  String get newProjectNameHint;
  String get projectDescriptionLabel;
  String get projectDescriptionHint;
  String get iconLabel;
  String get chooseIconTitle;
  String get pickerConfirmAction;
  String get closeAction;
  String get createProject;
  String get newProject;

  // Add/edit win
  String get newStarEyebrow;
  String get editStarEyebrow;
  String get addWinQuestion;
  String get addGoalQuestion;
  String get projectLabel;
  String get selectAProject;
  String get dateLabel;
  String get selectADateHint;
  String get timeLabel;
  String get selectATimeHint;
  String get titleFieldLabel;
  String get titleHint;
  String get detailsLabel;
  String get detailsHint;
  String get intensityLabel;
  String get photoLabel;
  String get addPhotoHint;
  String get takePhotoOption;
  String get choosePhotoOption;
  String get photoPickError;
  String get cropPhotoTitle;
  String get cropPhotoConfirm;
  String get cropPhotoHint;
  String get saveChanges;
  String get lightThisStar;
  String get cannotSaveMissingInfo;
  String get gotIt;
  String get deleteStarConfirmTitle;
  String get deleteStarConfirmBody;
  String get deleteStarAction;
  String get discardChangesConfirmTitle;
  String get discardChangesConfirmBody;
  String get discardChangesAction;

  // Add/edit star — achieved vs. goal toggle
  String get achievedToggleOn;
  String get achievedToggleOff;
  String get targetDateLabel;
  String get selectATargetDateHint;

  // Star reader — goal/dead states
  String goalTargetLabel(String date);
  String get markAchievedAction;
  String get markAchievedSheetTitle;
  String get markAchievedConfirm;
  String get undoAchievedAction;
  String get deadStarTitle;
  String get deadStarBody;
  String get resurrectAction;

  // Add/edit habit
  String get newHabitEyebrow;
  String get editHabitEyebrow;
  String get addHabitQuestion;
  String get habitFrequencyLabel;
  String get habitFrequencyDaily;
  String get customReminderToggleLabel;
  String get deleteHabitConfirmTitle;
  String get deleteHabitConfirmBody;
  String get deleteHabitAction;

  // Habit reader
  String get habitCurrentStreakLabel;
  String get markHabitDoneAction;
  String get habitDoneTodayLabel;
  String get undoHabitTodayAction;

  // Project card badges (goals/habits, alongside the existing star count)
  String openGoalsBadge(int count);
  String activeHabitsBadge(int count);

  // Area "Stars" flat list — kind filter chips (plural, shown next to a
  // count) and per-card kind tags (singular, shown on every card's own
  // badge — goal/dead reuse achievedToggleOff/deadStarTitle instead of a
  // second string, since those already are the singular form).
  String get starKindVictoryLabel;
  String get starKindVictoryTagLabel;
  String get starKindGoalLabel;
  String get starKindDeadLabel;
  String get starKindPulsarChipLabel;
  String get starKindPulsarTagLabel;

  // Star card's "extra" badge — the one kind-specific fact shown between
  // the description and the intensity/date block (photo/target/death
  // date/streak), and the "created" line every card ends with.
  String get photoBadgeLabel;
  String get targetDateBadgeLabel;
  String get deadDateBadgeLabel;
  String get streakBadgeLabel;
  String get noPhotoLabel;
  String get noTargetDateLabel;
  String get noDeadDateLabel;

  // Admire Your Stars (random reflection, filterable by area)
  String get admireTagline;
  String get allAreasLabel;
  String get pickAtLeastOneArea;
  String get noStarsInSelection;
  String get viewYourStars;

  // Home FAB + its "create" menu
  String get addWinFabLabel;
  String get addGoalFabLabel;
  String get addHabitFabLabel;
  String get newConstellationOption;

  /// A fixed set of short, hand-written uplifting phrases — cycled through
  /// automatically, one at a time, by the quote carousel below the area
  /// chips in [AdmireStarsScreen]. Not a translation of a single canonical
  /// list; each language's phrasing is its own.
  List<String> get upliftingQuotes;

  // Star reader
  String indexOfCount(int index, int total);
  String get shareStarLabel;
  String get shareStarError;

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

  // Onboarding — the first-launch "stories" tutorial explaining the
  // star/goal/dead-star, pulsar, constellation, supernova metaphor. Also
  // reachable from Settings' Data section (debug builds only) to replay it.
  String get onboardingIntroTitle;
  String get onboardingIntroBody;
  String get onboardingVictoriesTitle;
  String get onboardingVictoriesBody;
  String get onboardingGoalsTitle;
  String get onboardingGoalsBody;
  String get onboardingHabitsTitle;
  String get onboardingHabitsBody;
  String get onboardingConstellationsTitle;
  String get onboardingConstellationsBody;
  String get onboardingAreasTitle;
  String get onboardingAreasBody;
  String get onboardingOutroTitle;
  String get onboardingOutroBody;
  String get onboardingNextAction;
  String get onboardingGetStartedAction;
  String get onboardingSkipTooltip;
  String get replayOnboardingAction;
}
