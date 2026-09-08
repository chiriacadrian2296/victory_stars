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

  // The Sky's own side menu — the app has exactly one screen now (the
  // Sky), and everything else opens from there.
  String get openMenuAction;
  String get menuLightAStar;
  String get menuNewConstellation;
  String get menuVisions;
  String get menuAdmire;
  String get menuSearch;
  String get menuSettings;

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
  String starsCount(int count);
  String areaEmptyProjects(String areaName);
  String get constellationsModeLabel;
  String get listModeLabel;
  String get skyModeSupernovas;
  String get filterAreasAction;
  String get applyAreaFilterAction;
  String get filterKindSectionTitle;
  String get allKindsLabel;
  String get searchButtonLabel;
  String get takeMeThereAction;

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

  // The star form — one page for every kind of star (see [StarKind]).
  String get newStarEyebrow;
  String get editStarEyebrow;

  /// Shown instead of [newStarEyebrow] when the form was opened by tapping
  /// a nascent star: nothing is being added, an existing star is being
  /// given a meaning.
  String get configureStarEyebrow;

  String get litStarQuestion;
  String get unlitStarQuestion;
  String get pulsarQuestion;
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

  /// One line under [intensityLabel] explaining what the 1-5 scale means —
  /// the intensity of the effort itself, the same on every kind of star.
  String get intensityCaption;

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

  /// The save action's label for a star that isn't being lit right now — an
  /// unlit star or a pulsar, both of which are placed in the sky rather
  /// than lit up.
  String get placeThisStarAction;

  String get cannotSaveMissingInfo;
  String get gotIt;
  String get deleteStarConfirmTitle;
  String get deleteStarConfirmBody;
  String get deletePulsarConfirmTitle;
  String get deletePulsarConfirmBody;
  String get deleteStarAction;
  String get discardChangesConfirmTitle;
  String get discardChangesConfirmBody;
  String get discardChangesAction;

  String get targetDateLabel;
  String get selectATargetDateHint;

  // Star reader — unlit/dead states
  String goalTargetLabel(String date);
  String get markAchievedAction;
  String get markAchievedSheetTitle;
  String get markAchievedConfirm;
  String get undoAchievedAction;
  String get deadStarBody;

  /// A dead star that used to be a pulsar says so, and says what reigniting
  /// it will give back — a pulsar again, never a free choice.
  String get deadPulsarBody;
  String get reigniteAction;

  // Pulsar-only fields on the star form
  String get pulsarTitleHint;
  String get habitFrequencyLabel;
  String get habitFrequencyDaily;
  String get customReminderToggleLabel;

  // Habit reader
  String get habitCurrentStreakLabel;
  String get markHabitDoneAction;
  String get habitDoneTodayLabel;
  String get undoHabitTodayAction;

  // Constellation card badges, alongside the existing star count
  String unlitStarsBadge(int count);
  String activePulsarsBadge(int count);

  // The five kinds of star (see [StarKind]) — each has a singular name for
  // one card's own label, a plural for filter chips and counts, a one-line
  // meaning that translates the astronomy back into plain words, and an
  // example for the metaphor guide. Always reached through `StarKindX`
  // rather than read directly, so no screen hardcodes which is which.
  String get starKindNascentName;
  String get starKindNascentPlural;
  String get starKindNascentMeaning;
  String get starKindNascentExample;
  String get starKindLitName;
  String get starKindLitPlural;
  String get starKindLitMeaning;
  String get starKindLitExample;
  String get starKindUnlitName;
  String get starKindUnlitPlural;
  String get starKindUnlitMeaning;
  String get starKindUnlitExample;
  String get starKindPulsarName;
  String get starKindPulsarPlural;
  String get starKindPulsarMeaning;
  String get starKindPulsarExample;
  String get starKindDeadName;
  String get starKindDeadPlural;
  String get starKindDeadMeaning;
  String get starKindDeadExample;

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

  String get newConstellationOption;

  // Your visions — the page that gathers all 8 supernovas so their visions
  // can be re-read and revised in one place.
  String get visionsEyebrow;
  String get visionsTitle;
  String get visionsSubtitle;
  String get visionEmptyLabel;

  // The metaphor guide — one page explaining every level of the sky and how
  // they nest, openable any time from Settings' debug tools.
  String get guideOpenAction;
  String get guideEyebrow;
  String get guideTitle;
  String get guideIntroBody;
  String get examplesLabel;
  String get guideAreaTitle;
  String get guideAreaMeaning;
  String get guideAreaBody;
  String get guideAreaExamples;
  String get guideConstellationTitle;
  String get guideConstellationMeaning;
  String get guideConstellationBody;
  String get guideConstellationExamples;
  String get guideStarTitle;
  String get guideStarMeaning;
  String get guideStarBody;
  String get guideStarExamples;
  String get guideKindsTitle;
  String get guideKindsBody;
  String get guideIntensityTitle;
  String get guideIntensityBody;

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

  // Onboarding — the first-launch "stories" tutorial, walking the same
  // metaphor the guide lays out in full: nascent/lit/pulsar/unlit/dead
  // stars, constellations, supernovas. Also reachable from Settings' debug
  // tools to replay it.
  String get onboardingIntroTitle;
  String get onboardingIntroBody;
  String get onboardingNascentTitle;
  String get onboardingNascentBody;
  String get onboardingLitTitle;
  String get onboardingLitBody;
  String get onboardingPulsarTitle;
  String get onboardingPulsarBody;
  String get onboardingUnlitTitle;
  String get onboardingUnlitBody;
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
