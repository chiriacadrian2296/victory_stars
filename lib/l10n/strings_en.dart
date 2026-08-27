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
  String get navHome => 'Home';
  @override
  String get navSky => 'Sky';
  @override
  String get navStars => 'Stars';
  @override
  String get navSettings => 'Settings';

  @override
  String get homeEyebrow => 'YOUR PROGRESS';
  @override
  String get homeTitle => 'Your dashboard';
  @override
  String get homeSubtitle => 'Every win is a star, lit when you needed the light.';
  @override
  String get admireYourStars => 'Admire Your Stars';
  @override
  String get totalStarsLabel => 'Total stars';
  @override
  String get currentStreakLabel => 'Current streak';
  @override
  String get longestStreakLabel => 'Longest streak';
  @override
  String get activityLabel => 'Activity';
  @override
  String get dayDetailEmpty => 'No stars lit this day.';

  @override
  String get starsEyebrow => 'YOUR STARS';
  @override
  String get starsTitle => 'Browse your stars';
  @override
  String get starsSubtitle => 'Pick an area, then search within it.';
  @override
  String get searchHint => 'Search by title or description';
  @override
  String get noSearchResults => 'No stars match your search.';
  @override
  String get areaWinsEmpty => 'No stars lit in this area yet.';

  @override
  String get dataSection => 'Data';
  @override
  String get seedSampleData => 'Seed sample data';
  @override
  String seedSampleDataResult(int count) => 'Added $count wins to each seed project.';
  @override
  String get resetAllData => 'Reset all data';
  @override
  String get resetAllDataConfirmTitle => 'Reset all data?';
  @override
  String get resetAllDataConfirmBody => 'This permanently deletes every win and project. This cannot be undone.';
  @override
  String get cancel => 'Cancel';
  @override
  String get deleteEverything => 'Delete everything';
  @override
  String get allDataCleared => 'All data cleared.';
  @override
  String get archiveEmpty => 'Your archive is still empty. Light your first star, even a small one.';

  @override
  String get skyEyebrow => 'YOUR SKY';
  @override
  String get skyTitle => 'Explore your sky';
  @override
  String get skySubtitle => 'Every area holds its own constellations.';
  @override
  String starsCount(int count) => '$count star${count == 1 ? '' : 's'}';
  @override
  String get newProjectTooltip => 'New project';
  @override
  String areaEmptyProjects(String areaName) =>
      'No projects yet in $areaName. Start one to begin lighting stars here.';

  @override
  String get addWinTooltip => 'Add a win';
  @override
  String get constellationShapeMissing => "This project's constellation shape couldn't be found.";

  @override
  String get newProjectEyebrow => 'NEW PROJECT';
  @override
  String get newProjectQuestion => 'What project is this?';
  @override
  String get areaLabel => 'Area';
  @override
  String get nameLabel => 'Name';
  @override
  String get newProjectNameHint => 'E.g. Build this app';
  @override
  String get iconLabel => 'Icon';
  @override
  String get createProject => 'Create project';
  @override
  String get newProject => 'New project';

  @override
  String get newStarEyebrow => 'NEW STAR';
  @override
  String get editStarEyebrow => 'EDIT STAR';
  @override
  String get addWinQuestion => 'What did you get through?';
  @override
  String get projectLabel => 'Project';
  @override
  String get selectAProject => 'Select a project';
  @override
  String get titleFieldLabel => 'In a few words';
  @override
  String get titleHint => 'E.g. I held on after a rejection and kept going';
  @override
  String get detailsLabel => 'Details (optional)';
  @override
  String get detailsHint => 'What made this moment hard, and how you got through it';
  @override
  String get intensityLabel => 'Intensity — how much this took out of you';
  @override
  String get saveChanges => 'Save changes';
  @override
  String get lightThisStar => 'Light this star';

  @override
  String get admireTagline => "For when you're in the dark and you need some light.";
  @override
  String get allAreasLabel => 'All areas';
  @override
  String get pickAtLeastOneArea => 'Pick at least one area to continue.';
  @override
  String get noStarsInSelection => "No stars lit yet in the areas you picked.";
  @override
  String get viewYourStars => 'View your stars';

  @override
  String indexOfCount(int index, int total) => '$index of $total';

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
  String get reminderToggleLabel => 'Remind me to log a win';
  @override
  String get reminderTimeLabel => 'Reminder time';
  @override
  String get notificationPermissionDenied => 'Notifications are turned off for this app in your phone settings.';
  @override
  String get aboutSection => 'About';
  @override
  String aboutVersion(String version) => 'Version $version';
  @override
  String get aboutTagline => 'A personal growth app for recording the moments you got through.';

  @override
  List<String> get monthAbbreviations => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];

  @override
  List<String> get weekdayAbbreviations => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  String monthTitle(DateTime month) => '${_fullMonths[month.month - 1]} ${month.year}';
}

const _fullMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
