import 'app_strings.dart';

class StringsRo implements AppStrings {
  const StringsRo();

  @override
  String get languageCode => 'ro';

  @override
  String get areaPhysical => 'Fizic';
  @override
  String get areaPsychological => 'Psihologic';
  @override
  String get areaProfessional => 'Profesional';
  @override
  String get areaFinancial => 'Financiar';
  @override
  String get areaPersonal => 'Personal';
  @override
  String get areaSocial => 'Social';
  @override
  String get areaSpiritual => 'Spiritual';
  @override
  String get areaPhilanthropic => 'Filantropic';

  @override
  String get navHome => 'Acasă';
  @override
  String get navSky => 'Cer';
  @override
  String get navStars => 'Stele';
  @override
  String get navSettings => 'Setări';

  @override
  String get homeEyebrow => 'PROGRESUL TĂU';
  @override
  String get homeTitle => 'Panoul tău';
  @override
  String get homeSubtitle => 'Fiecare victorie e o stea, aprinsă atunci când aveai nevoie de lumină.';
  @override
  String get admireYourStars => 'Admiră-ți stelele';
  @override
  String get totalStarsLabel => 'Stele în total';
  @override
  String get currentStreakLabel => 'Serie curentă';
  @override
  String get longestStreakLabel => 'Cea mai lungă serie';
  @override
  String get activityLabel => 'Activitate';
  @override
  String get dayDetailEmpty => 'Nicio stea aprinsă în această zi.';

  @override
  String get starsEyebrow => 'STELELE TALE';
  @override
  String get starsTitle => 'Explorează-ți stelele';
  @override
  String get starsSubtitle => 'Alege o zonă, apoi caută în ea.';
  @override
  String get searchHint => 'Caută după titlu sau descriere';
  @override
  String get noSearchResults => 'Nicio stea nu corespunde căutării.';
  @override
  String get areaWinsEmpty => 'Nicio stea aprinsă încă în această zonă.';

  @override
  String get dataSection => 'Date';
  @override
  String get seedSampleData => 'Generează date de exemplu';
  @override
  String seedSampleDataResult(int count) => 'S-au adăugat $count victorii la fiecare proiect de exemplu.';
  @override
  String get resetAllData => 'Resetează toate datele';
  @override
  String get resetAllDataConfirmTitle => 'Resetezi toate datele?';
  @override
  String get resetAllDataConfirmBody =>
      'Această acțiune șterge definitiv fiecare victorie și proiect. Nu poate fi anulată.';
  @override
  String get cancel => 'Anulează';
  @override
  String get deleteEverything => 'Șterge tot';
  @override
  String get allDataCleared => 'Toate datele au fost șterse.';
  @override
  String get archiveEmpty => 'Arhiva ta e încă goală. Aprinde prima ta stea, chiar și una mică.';

  @override
  String get skyEyebrow => 'CERUL TĂU';
  @override
  String get skyTitle => 'Explorează-ți cerul';
  @override
  String get skySubtitle => 'Fiecare zonă are propriile constelații.';
  @override
  String starsCount(int count) => count == 1 ? '1 stea' : '$count stele';
  @override
  String get newProjectTooltip => 'Proiect nou';
  @override
  String areaEmptyProjects(String areaName) =>
      'Încă niciun proiect în $areaName. Începe unul pentru a aprinde primele stele aici.';

  @override
  String get addWinTooltip => 'Adaugă o victorie';
  @override
  String get constellationShapeMissing => 'Forma constelației acestui proiect nu a fost găsită.';

  @override
  String get newProjectEyebrow => 'PROIECT NOU';
  @override
  String get newProjectQuestion => 'Despre ce proiect e vorba?';
  @override
  String get areaLabel => 'Zonă';
  @override
  String get nameLabel => 'Nume';
  @override
  String get newProjectNameHint => 'Ex. Construiesc această aplicație';
  @override
  String get iconLabel => 'Pictogramă';
  @override
  String get createProject => 'Creează proiect';
  @override
  String get newProject => 'Proiect nou';

  @override
  String get newStarEyebrow => 'STEA NOUĂ';
  @override
  String get editStarEyebrow => 'EDITEAZĂ STEAUA';
  @override
  String get addWinQuestion => 'Ce ai reușit să depășești?';
  @override
  String get projectLabel => 'Proiect';
  @override
  String get selectAProject => 'Selectează un proiect';
  @override
  String get titleFieldLabel => 'În câteva cuvinte';
  @override
  String get titleHint => 'Ex. Am rezistat după o respingere și am continuat';
  @override
  String get detailsLabel => 'Detalii (opțional)';
  @override
  String get detailsHint => 'Ce a făcut acest moment dificil și cum ai trecut peste el';
  @override
  String get intensityLabel => 'Intensitate — cât te-a costat';
  @override
  String get saveChanges => 'Salvează modificările';
  @override
  String get lightThisStar => 'Aprinde această stea';

  @override
  String get admireTagline => 'Pentru când ești în întuneric și ai nevoie de puțină lumină.';
  @override
  String get allAreasLabel => 'Toate zonele';
  @override
  String get pickAtLeastOneArea => 'Alege cel puțin o zonă pentru a continua.';
  @override
  String get noStarsInSelection => 'Nicio stea aprinsă încă în zonele alese.';
  @override
  String get viewYourStars => 'Privește-ți stelele';

  @override
  String indexOfCount(int index, int total) => '$index din $total';

  @override
  String get settingsEyebrow => 'SETĂRI';
  @override
  String get settingsTitle => 'Setări';
  @override
  String get appearanceSection => 'Aspect';
  @override
  String get themeLight => 'Deschis';
  @override
  String get themeDark => 'Întunecat';
  @override
  String get languageSection => 'Limbă';
  @override
  String get languageEnglish => 'English';
  @override
  String get languageItalian => 'Italiano';
  @override
  String get languageRomanian => 'Română';
  @override
  String get reminderSection => 'Memento zilnic';
  @override
  String get reminderToggleLabel => 'Amintește-mi să notez o victorie';
  @override
  String get reminderTimeLabel => 'Ora mementoului';
  @override
  String get notificationPermissionDenied => 'Notificările sunt dezactivate pentru această aplicație în setările telefonului.';
  @override
  String get aboutSection => 'Despre';
  @override
  String aboutVersion(String version) => 'Versiunea $version';
  @override
  String get aboutTagline => 'O aplicație de dezvoltare personală pentru a nota momentele pe care le-ai depășit.';

  @override
  List<String> get monthAbbreviations => const [
        'Ian', 'Feb', 'Mar', 'Apr', 'Mai', 'Iun',
        'Iul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];

  @override
  List<String> get weekdayAbbreviations => const ['Lun', 'Mar', 'Mie', 'Joi', 'Vin', 'Sâm', 'Dum'];

  @override
  String monthTitle(DateTime month) => '${_fullMonths[month.month - 1]} ${month.year}';
}

const _fullMonths = [
  'Ianuarie', 'Februarie', 'Martie', 'Aprilie', 'Mai', 'Iunie',
  'Iulie', 'August', 'Septembrie', 'Octombrie', 'Noiembrie', 'Decembrie',
];
