import 'app_strings.dart';

class StringsEn implements AppStrings {
  const StringsEn();

  @override
  String get languageCode => 'en';

  @override
  String get areaPhysical => 'Physical';
  @override
  String get areaPsychological => 'Psychological';
  @override
  String get areaProfessional => 'Professional';
  @override
  String get areaFinancial => 'Financial';
  @override
  String get areaPersonal => 'Personal';
  @override
  String get areaSocial => 'Social';
  @override
  String get areaSpiritual => 'Spiritual';
  @override
  String get areaPhilanthropic => 'Philanthropic';
  @override
  String get areaPhysicalDescription =>
      'Movement, strength, and the health that carries everything else.';
  @override
  String get areaPsychologicalDescription =>
      'Your mind — clarity, resilience, and emotional balance.';
  @override
  String get areaProfessionalDescription =>
      "Your work — career, craft, and the skills you're building.";
  @override
  String get areaFinancialDescription =>
      'Your money — saving, earning, and long-term security.';
  @override
  String get areaPersonalDescription =>
      'Your growth — habits, discipline, and self-improvement.';
  @override
  String get areaSocialDescription =>
      'Your people — friends, family, and real connection.';
  @override
  String get areaSpiritualDescription =>
      'Your inner life — meaning, stillness, and what you believe.';
  @override
  String get areaPhilanthropicDescription =>
      "Your impact — giving, service, and other people's lives.";

  @override
  String get navHome => 'Home';
  @override
  String get navSky => 'Sky';
  @override
  String get navNebula => 'Nebula';
  @override
  String get navStats => 'Stats';
  @override
  String get navSettings => 'Settings';
  @override
  String get collapseSidebarAction => 'Collapse sidebar';
  @override
  String get expandSidebarAction => 'Expand sidebar';

  @override
  String get statsEyebrow => 'YOUR NUMBERS';
  @override
  String get statsTitle => 'Statistics';

  @override
  String get homeEyebrow => 'YOUR PROGRESS';
  @override
  String get homeTitle => 'Your dashboard';
  @override
  String get homeSubtitle =>
      'Every star is a win, lit when you needed the light.';
  @override
  String get admireYourStars => 'Admire Your Stars';
  @override
  String get todayStarSectionLabel => "Today's star";
  @override
  String get litTodayTitle => "Congrats, you've lit a star today!";
  @override
  String get litTodayTitleHighlight => 'star';
  @override
  String get litTodaySubtitle => "- you've brought new light to your life -";
  @override
  String get litTodaySubtitleHighlight => 'light';
  @override
  String get notLitTodayLabel => 'No star lit today yet';
  @override
  String get notLitTodayHighlight => 'star';
  @override
  String get lightStarCta => 'Light One';
  @override
  String get totalStarsLabel => 'Total stars';
  @override
  String get streaksSectionLabel => 'Streaks';
  @override
  String get currentStreakLabel => 'Current streak';
  @override
  String get longestStreakLabel => 'Longest streak';
  @override
  String get activityLabel => 'Activity';
  @override
  String get dayDetailEmpty => 'No stars lit this day.';
  @override
  String get addStarForDayLabel => 'Add a star for this day';

  @override
  String get firstStarLabel => 'First star';
  @override
  String get mostRecentStarLabel => 'Most recent star';
  @override
  String get combinedIntensityLabel => 'Combined intensity';
  @override
  String get starsByAreaLabel => 'By supernova';
  @override
  String get streakFromLabel => 'From';
  @override
  String get streakToLabel => 'To';
  @override
  String get todayLabel => 'Today';
  @override
  String get starsLoggedLabel => 'Stars logged';
  @override
  @override
  String get noCurrentStreakBody =>
      'No streak going right now. Light a star today to start one.';

  @override
  String get searchHint => 'Search by title or description';
  @override
  String get noSearchResults => 'No stars match your search.';
  @override
  String get skyEmptyConstellations => 'No constellations yet.';
  @override
  String get skyEmptyStars => 'No stars yet.';
  @override
  String intensityCount(int value) => '$value intensity';
  @override
  String createdOnLabel(String date) => 'Created $date';
  @override
  String lastStarLabel(String date) => 'Last star $date';
  @override
  String get constellationsModeLabel => 'Constellations';
  @override
  String get listModeLabel => 'Stars';
  @override
  String get skyModeSupernovas => 'Supernovas';
  @override
  String get filterAreasAction => 'Filter areas';
  @override
  String get applyAreaFilterAction => 'Apply filter';
  @override
  String get filterKindSectionTitle => 'Star kind';
  @override
  String get allKindsLabel => 'All kinds';

  @override
  String get areaVisionLabel => 'Your vision for this area';
  @override
  String get areaVisionHint =>
      "What kind of reality do you want here? What are you working toward?";
  @override
  String get editVisionAction => 'Edit vision';
  @override
  String get areaConstellationsStatLabel => 'Constellations';
  @override
  String get areaStarsStatLabel => 'Stars';
  @override
  String get areaIntensityStatLabel => 'Intensity';

  @override
  String get dataSection => 'Debug tools';
  @override
  String get seedSampleData => 'Seed sample data';
  @override
  String seedSampleDataResult(int count) =>
      'Added $count stars to each seed constellation.';
  @override
  String get resetAllData => 'Reset all data';
  @override
  String get resetAllDataConfirmTitle => 'Reset all data?';
  @override
  String get resetAllDataConfirmBody =>
      'This permanently deletes every star and constellation. This cannot be undone.';
  @override
  String get cancel => 'Cancel';
  @override
  String get deleteEverything => 'Delete everything';
  @override
  String get allDataCleared => 'All data cleared.';
  @override
  String get archiveEmpty =>
      'Your archive is still empty. Light your first star, even a small one.';

  @override
  String get skyEyebrow => 'YOUR SKY';
  @override
  String get skyTitle => 'Explore your sky';
  @override
  String get skySubtitle => 'Every supernova holds its own constellations.';
  @override
  String starsCount(int count) => '$count star${count == 1 ? '' : 's'}';
  @override
  String areaEmptyProjects(String areaName) =>
      'No constellations yet in $areaName. Start one to begin lighting stars here.';

  @override
  String get constellationShapeMissing =>
      "This constellation's shape couldn't be found.";

  @override
  String get drawYourOwnConstellation => 'Draw your own constellation';
  @override
  String get drawYourOwnShort => 'Draw your own';
  @override
  String get constellationEditorTitle => 'Draw your constellation';
  @override
  String get constellationEditorEditTitle => 'Edit your constellation';
  @override
  String get constellationEditorEmptyHint =>
      'Tap anywhere to place your first star';
  @override
  String constellationEditorDisconnectedWarning(int count) =>
      '$count star${count == 1 ? '' : 's'} not connected yet';
  @override
  String get constellationEditorPointCapReached =>
      "You've reached the maximum number of stars";
  @override
  String get undoAction => 'Undo';
  @override
  String get redoAction => 'Redo';
  @override
  String get deletePointAction => 'Delete';
  @override
  String get saveConstellationAction => 'Save';
  @override
  String get nameYourConstellationTitle => 'Name your constellation';
  @override
  String get constellationNameHint => 'E.g. My own path';
  @override
  String get yourConstellationsLabel => 'Your constellations';
  @override
  String get constellationEditorGridToggleLabel => 'Grid';
  @override
  String get constellationEditorHelpAction => 'How this works';
  @override
  String get constellationEditorHelpTitle => 'How this works';
  @override
  String get constellationEditorHelpAddPoint => 'Tap empty space to add a star';
  @override
  String get constellationEditorHelpConnectPoint =>
      'Tap a star, then tap another to connect them with a line';
  @override
  String get constellationEditorHelpDisarmPoint =>
      'Tap the same star again to deselect it without connecting';
  @override
  String get constellationEditorHelpMovePoint =>
      'Press and drag a star to move it';
  @override
  String get constellationEditorHelpDeletePoint =>
      'Select a star, then tap the delete icon to remove it';
  @override
  String get constellationEditorHelpDontShowAgain => "Don't show this again";
  @override
  String get constellationEditorHelpClose => 'Got it';

  @override
  String get newProjectEyebrow => 'NEW CONSTELLATION';
  @override
  String get newProjectQuestion => 'What constellation is this?';
  @override
  String get areaLabel => 'Supernova';
  @override
  String get nameLabel => 'Name';
  @override
  String get newProjectNameHint => 'E.g. Build this app';
  @override
  String get projectDescriptionLabel => 'Description (optional)';
  @override
  String get projectDescriptionHint => "What's this project about?";
  @override
  String get iconLabel => 'Icon';
  @override
  String get chooseIconTitle => 'Choose an icon';
  @override
  String get pickerConfirmAction => 'OK';
  @override
  String get closeAction => 'Close';
  @override
  String get createProject => 'Create constellation';
  @override
  String get newProject => 'New constellation';

  @override
  String get newStarEyebrow => 'NEW STAR';
  @override
  String get editStarEyebrow => 'EDIT STAR';
  @override
  String get addWinQuestion => 'What did you get through?';
  @override
  String get addGoalQuestion => 'What do you want to achieve?';
  @override
  String get projectLabel => 'Constellation';
  @override
  String get selectAProject => 'Select a constellation';
  @override
  String get dateLabel => 'Date';
  @override
  String get selectADateHint => 'Select a date';
  @override
  String get timeLabel => 'Time';
  @override
  String get selectATimeHint => 'Select a time';
  @override
  String get titleFieldLabel => 'In a few words';
  @override
  String get titleHint => 'E.g. I held on after a rejection and kept going';
  @override
  String get detailsLabel => 'Details (optional)';
  @override
  String get detailsHint =>
      'What made this moment hard, and how you got through it';
  @override
  String get intensityLabel => 'Intensity';
  @override
  String get photoLabel => 'Photo (optional)';
  @override
  String get addPhotoHint => 'Add a photo';
  @override
  String get takePhotoOption => 'Take a photo';
  @override
  String get choosePhotoOption => 'Choose from library';
  @override
  String get photoPickError => "Couldn't get that photo. Try again?";
  @override
  String get cropPhotoTitle => 'Adjust photo';
  @override
  String get cropPhotoConfirm => 'Done';
  @override
  String get cropPhotoHint => 'Pinch and drag to fit your photo into the frame';
  @override
  String get saveChanges => 'Save changes';
  @override
  String get lightThisStar => 'Light this star';
  @override
  String get cannotSaveMissingInfo => "Can't save yet — some info is missing";
  @override
  String get gotIt => 'Got it';
  @override
  String get deleteStarConfirmTitle => 'Delete this star?';
  @override
  String get deleteStarConfirmBody =>
      "This turns the star into a dead one — it leaves here, but stays in its spot in the sky, and you can bring it back to life later.";
  @override
  String get deleteStarAction => 'Delete';
  @override
  String get discardChangesConfirmTitle => 'Discard changes?';
  @override
  String get discardChangesConfirmBody =>
      "You'll lose the changes you made to this star.";
  @override
  String get discardChangesAction => 'Discard';

  @override
  String get achievedToggleOn => 'Already achieved';
  @override
  String get achievedToggleOff => 'Future goal';
  @override
  String get targetDateLabel => 'Target date (optional)';
  @override
  String get selectATargetDateHint => 'Select a date';

  @override
  String goalTargetLabel(String date) => 'Goal for $date';
  @override
  String get markAchievedAction => 'Mark as achieved';
  @override
  String get markAchievedSheetTitle => 'How much did it take to get there?';
  @override
  String get markAchievedConfirm => 'Light this star';
  @override
  String get undoAchievedAction => 'Mark as not achieved';
  @override
  String get deadStarTitle => 'Dead star';
  @override
  String get deadStarBody =>
      'This star was deleted. You can bring it back to life as a brand new star, in the same spot in the sky.';
  @override
  String get resurrectAction => 'Resurrect this star';

  @override
  String get newHabitEyebrow => 'NEW PULSAR';
  @override
  String get editHabitEyebrow => 'EDIT PULSAR';
  @override
  String get addHabitQuestion => 'Which pulsar do you want to light?';
  @override
  String get habitFrequencyLabel => 'Frequency';
  @override
  String get habitFrequencyDaily => 'Every day';
  @override
  String get customReminderToggleLabel => 'Custom reminder time';
  @override
  String get deleteHabitConfirmTitle => 'Delete this pulsar?';
  @override
  String get deleteHabitConfirmBody =>
      'This permanently removes the pulsar and all of its history. This cannot be undone.';
  @override
  String get deleteHabitAction => 'Delete';

  @override
  String get habitCurrentStreakLabel => 'Current streak';
  @override
  String get markHabitDoneAction => 'Mark today as done';
  @override
  String get habitDoneTodayLabel => 'Done today';
  @override
  String get undoHabitTodayAction => 'Undo';

  @override
  String openGoalsBadge(int count) =>
      count == 1 ? '1 open goal' : '$count open goals';
  @override
  String activeHabitsBadge(int count) =>
      count == 1 ? '1 active pulsar' : '$count active pulsars';

  @override
  String get starKindVictoryLabel => 'Victories';
  @override
  String get starKindVictoryTagLabel => 'Victory';
  @override
  String get starKindGoalLabel => 'Goals';
  @override
  String get starKindDeadLabel => 'Dead stars';
  @override
  String get starKindPulsarChipLabel => 'Pulsars';
  @override
  String get starKindPulsarTagLabel => 'Pulsar';

  @override
  String get photoBadgeLabel => 'Photo';
  @override
  String get targetDateBadgeLabel => 'Target';
  @override
  String get deadDateBadgeLabel => 'Died';
  @override
  String get streakBadgeLabel => 'Streak';
  @override
  String get noPhotoLabel => 'No photo';
  @override
  String get noTargetDateLabel => 'No target date';
  @override
  String get noDeadDateLabel => 'No death date';

  @override
  String get admireTagline =>
      "For when you're in the dark and you need some light.";
  @override
  String get allAreasLabel => 'All supernovas';
  @override
  String get pickAtLeastOneArea => 'Pick at least one supernova to continue.';
  @override
  String get noStarsInSelection =>
      "No stars lit yet in the supernovas you picked.";
  @override
  String get viewYourStars => 'View your stars';

  @override
  String get addWinFabLabel => 'New victory';
  @override
  String get addGoalFabLabel => 'New goal';
  @override
  String get addHabitFabLabel => 'New pulsar';
  @override
  String get newConstellationOption => 'New constellation';

  @override
  List<String> get upliftingQuotes => const [
    "You don't have to see the whole staircase, just take the first step.",
    'Small steps still move you forward.',
    "You've survived every hard day so far. That's a perfect record.",
    'Rest is not the same as giving up.',
    'You are allowed to be both a work in progress and worthy of love at the same time.',
    'This feeling is real, but it is not permanent.',
    "You don't have to have it all figured out to keep going.",
    'Progress, not perfection.',
    "Some days, just being here is enough. That counts.",
    "You've made it through 100% of your worst days so far.",
    'Be patient with yourself. Nothing in nature blooms all year.',
    "It's okay to not be okay — just don't stay there alone.",
    "One breath at a time. That's all this moment is asking of you.",
    'You are stronger than you think and more loved than you know.',
    'Even the darkest night will end, and the sun will rise.',
    "Healing isn't linear, and that's alright.",
  ];

  @override
  String indexOfCount(int index, int total) => '$index of $total';
  @override
  String get shareStarLabel => 'Share this Star';
  @override
  String get shareStarError => "Couldn't share that star. Try again?";

  @override
  String get settingsEyebrow => 'SETTINGS';
  @override
  String get settingsTitle => 'Settings';
  @override
  String get appearanceSection => 'Appearance';
  @override
  String get themeLight => 'Light';
  @override
  String get themeDark => 'Dark';
  @override
  String get languageSection => 'Language';
  @override
  String get languageEnglish => 'English';
  @override
  String get languageItalian => 'Italiano';
  @override
  String get languageRomanian => 'Română';
  @override
  String get reminderSection => 'Daily reminder';
  @override
  String get reminderToggleLabel => 'Remind me to light a star';
  @override
  String get reminderTimeLabel => 'Reminder time';
  @override
  String get notificationPermissionDenied =>
      'Notifications are turned off for this app in your phone settings.';
  @override
  String get testNotificationButton => 'Send test notification';
  @override
  String get reminderNotificationTitle => 'Light a star';

  @override
  List<String> get reminderNotificationBodies => const [
    'What got you through today, even a little?',
    'Even the smallest step still lights a star.',
    'Take a moment — what went right today?',
    'Your sky is waiting for tonight\'s star.',
    'Did you get through something today? Write it down.',
  ];
  @override
  String get aboutSection => 'About';
  @override
  String aboutVersion(String version) => 'Version $version';
  @override
  String get aboutTagline =>
      'A personal growth app for recording the moments you got through.';

  @override
  List<String> get monthAbbreviations => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  List<String> get weekdayAbbreviations => const [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  String monthTitle(DateTime month) =>
      '${_fullMonths[month.month - 1]} ${month.year}';

  @override
  String get onboardingIntroTitle => 'Welcome to your Sky';
  @override
  String get onboardingIntroBody =>
      'Victory Stars turns the things you accomplish into your own night '
      "sky — a place to look back on everything you've been through.";
  @override
  String get onboardingVictoriesTitle => 'Every win becomes a star';
  @override
  String get onboardingVictoriesBody =>
      'The moment you get through something that mattered, you light a '
      'star. It stays there — proof of what you did, whenever you need to '
      'see it again.';
  @override
  String get onboardingGoalsTitle => 'Not every star is lit yet';
  @override
  String get onboardingGoalsBody =>
      "Set a goal for something you're working toward. Reach it and it "
      "lights up like any other star — let it go instead, and it becomes "
      "a dead star. Either way, it's still part of your sky.";
  @override
  String get onboardingHabitsTitle => 'Habits pulse like pulsars';
  @override
  String get onboardingHabitsBody =>
      'A habit you keep showing up for is a pulsar — it stays lit as long '
      'as you keep the rhythm going.';
  @override
  String get onboardingConstellationsTitle => 'Group them into constellations';
  @override
  String get onboardingConstellationsBody =>
      'Stars and pulsars about the same thing — a project, a relationship, '
      'anything — belong to a constellation you name yourself.';
  @override
  String get onboardingAreasTitle => 'Constellations live in supernovas';
  @override
  String get onboardingAreasBody =>
      'Every constellation sits inside one of 8 supernovas — the fixed '
      'areas of your life, from physical to social to spiritual. Together, '
      "they're your Sky.";
  @override
  String get onboardingOutroTitle => 'Ready to light your first star?';
  @override
  String get onboardingOutroBody =>
      'Head to the Sky tab any time to look back, or start adding wins '
      'right away.';
  @override
  String get onboardingNextAction => 'Next';
  @override
  String get onboardingGetStartedAction => 'Get started';
  @override
  String get onboardingSkipTooltip => 'Skip';
  @override
  String get replayOnboardingAction => 'Replay onboarding';
}

const _fullMonths = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
