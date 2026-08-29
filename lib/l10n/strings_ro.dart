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
  String get navSettings => 'Setări';

  @override
  String get homeEyebrow => 'PROGRESUL TĂU';
  @override
  String get homeTitle => 'Panoul tău';
  @override
  String get homeSubtitle => 'Fiecare stea e o victorie, aprinsă atunci când aveai nevoie de lumină.';
  @override
  String get admireYourStars => 'Admiră-ți stelele';
  @override
  String get todayStarSectionLabel => 'Steaua zilei';
  @override
  String get litTodayTitle => 'Felicitări, ai aprins o stea azi!';
  @override
  String get litTodayTitleHighlight => 'stea';
  @override
  String get litTodaySubtitle => '- ai adus lumină nouă în viața ta -';
  @override
  String get litTodaySubtitleHighlight => 'lumină';
  @override
  String get notLitTodayLabel => 'Nicio stea aprinsă azi încă';
  @override
  String get notLitTodayHighlight => 'stea';
  @override
  String get lightStarCta => 'Aprinde una';
  @override
  String get totalStarsLabel => 'Stele în total';
  @override
  String get streaksSectionLabel => 'Serii';
  @override
  String get currentStreakLabel => 'Serie curentă';
  @override
  String get longestStreakLabel => 'Cea mai lungă serie';
  @override
  String get activityLabel => 'Activitate';
  @override
  String get dayDetailEmpty => 'Nicio stea aprinsă în această zi.';
  @override
  String get addStarForDayLabel => 'Adaugă o stea pentru această zi';

  @override
  String get firstStarLabel => 'Prima stea';
  @override
  String get mostRecentStarLabel => 'Cea mai recentă stea';
  @override
  String get combinedIntensityLabel => 'Intensitate combinată';
  @override
  String get starsByAreaLabel => 'Pe supernove';
  @override
  String get streakFromLabel => 'De la';
  @override
  String get streakToLabel => 'Până la';
  @override
  String get todayLabel => 'Azi';
  @override
  String get starsLoggedLabel => 'Stele notate';
  @override
  @override
  String get noCurrentStreakBody => 'Nicio serie activă acum. Aprinde o stea azi ca să începi una.';

  @override
  String get searchHint => 'Caută după titlu sau descriere';
  @override
  String get noSearchResults => 'Nicio stea nu corespunde căutării.';
  @override
  String get areaWinsEmpty => 'Nicio stea aprinsă încă în această supernovă.';
  @override
  String intensityCount(int value) => '$value intensitate';
  @override
  String createdOnLabel(String date) => 'Creată la $date';
  @override
  String lastStarLabel(String date) => 'Ultima stea $date';
  @override
  String get constellationsModeLabel => 'Constelații';
  @override
  String get listModeLabel => 'Stele';

  @override
  String get dataSection => 'Date';
  @override
  String get seedSampleData => 'Generează date de exemplu';
  @override
  String seedSampleDataResult(int count) => 'S-au adăugat $count stele la fiecare constelație de exemplu.';
  @override
  String get resetAllData => 'Resetează toate datele';
  @override
  String get resetAllDataConfirmTitle => 'Resetezi toate datele?';
  @override
  String get resetAllDataConfirmBody =>
      'Această acțiune șterge definitiv fiecare stea și constelație. Nu poate fi anulată.';
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
  String get skySubtitle => 'Fiecare supernovă are propriile constelații.';
  @override
  String starsCount(int count) => count == 1 ? '1 stea' : '$count stele';
  @override
  String areaEmptyProjects(String areaName) =>
      'Încă nicio constelație în $areaName. Începe una pentru a aprinde primele stele aici.';

  @override
  String get constellationShapeMissing => 'Forma acestei constelații nu a fost găsită.';

  @override
  String get newProjectEyebrow => 'CONSTELAȚIE NOUĂ';
  @override
  String get newProjectQuestion => 'Despre ce constelație e vorba?';
  @override
  String get areaLabel => 'Supernovă';
  @override
  String get nameLabel => 'Nume';
  @override
  String get newProjectNameHint => 'Ex. Construiesc această aplicație';
  @override
  String get iconLabel => 'Pictogramă';
  @override
  String get createProject => 'Creează constelație';
  @override
  String get newProject => 'Constelație nouă';

  @override
  String get newStarEyebrow => 'STEA NOUĂ';
  @override
  String get editStarEyebrow => 'EDITEAZĂ STEAUA';
  @override
  String get addWinQuestion => 'Ce ai reușit să depășești?';
  @override
  String get projectLabel => 'Constelație';
  @override
  String get selectAProject => 'Selectează o constelație';
  @override
  String get dateLabel => 'Dată';
  @override
  String get selectADateHint => 'Selectează o dată';
  @override
  String get timeLabel => 'Ora';
  @override
  String get selectATimeHint => 'Selectează o oră';
  @override
  String get titleFieldLabel => 'În câteva cuvinte';
  @override
  String get titleHint => 'Ex. Am rezistat după o respingere și am continuat';
  @override
  String get detailsLabel => 'Detalii (opțional)';
  @override
  String get detailsHint => 'Ce a făcut acest moment dificil și cum ai trecut peste el';
  @override
  String get intensityLabel => 'Intensitate';
  @override
  String get photoLabel => 'Fotografie (opțional)';
  @override
  String get addPhotoHint => 'Adaugă o fotografie';
  @override
  String get takePhotoOption => 'Fă o fotografie';
  @override
  String get choosePhotoOption => 'Alege din galerie';
  @override
  String get photoPickError => 'Nu am putut obține fotografia. Încerci din nou?';
  @override
  String get cropPhotoTitle => 'Ajustează fotografia';
  @override
  String get cropPhotoConfirm => 'Gata';
  @override
  String get cropPhotoHint => 'Ciupește și trage pentru a încadra fotografia în cadru';
  @override
  String get saveChanges => 'Salvează modificările';
  @override
  String get lightThisStar => 'Aprinde această stea';
  @override
  String get deleteStarConfirmTitle => 'Ștergi această stea?';
  @override
  String get deleteStarConfirmBody =>
      'Aceasta elimină definitiv steaua și tot ce ai scris pentru ea. Nu poate fi anulat.';
  @override
  String get deleteStarAction => 'Șterge';
  @override
  String get discardChangesConfirmTitle => 'Renunți la modificări?';
  @override
  String get discardChangesConfirmBody => 'Vei pierde modificările făcute acestei stele.';
  @override
  String get discardChangesAction => 'Renunță la modificări';

  @override
  String get admireTagline => 'Pentru când ești în întuneric și ai nevoie de puțină lumină.';
  @override
  String get allAreasLabel => 'Toate supernovele';
  @override
  String get pickAtLeastOneArea => 'Alege cel puțin o supernovă pentru a continua.';
  @override
  String get noStarsInSelection => 'Nicio stea aprinsă încă în supernovele alese.';
  @override
  String get viewYourStars => 'Privește-ți stelele';

  @override
  String get addWinFabLabel => 'Stea nouă';
  @override
  String get newConstellationOption => 'Constelație nouă';

  @override
  List<String> get upliftingQuotes => const [
        'Nu trebuie să vezi toată scara, doar primul pas.',
        'Și pașii mici te duc mai departe.',
        'Ai trecut prin fiecare zi grea de până acum. Un record perfect.',
        'Odihna nu înseamnă renunțare.',
        'Poți fi în același timp o lucrare în desfășurare și demn de iubire.',
        'Acest sentiment e real, dar nu e permanent.',
        'Nu trebuie să ai totul clar ca să mergi mai departe.',
        'Progres, nu perfecțiune.',
        'Unele zile, e suficient să fii încă aici. Și contează.',
        'Ai trecut prin 100% din cele mai grele zile ale tale, până acum.',
        'Fii răbdător cu tine. Nimic în natură nu înflorește tot anul.',
        'E în regulă să nu fii bine — doar nu rămâne acolo singur.',
        'O respirație pe rând. Atât îți cere acest moment.',
        'Ești mai puternic decât crezi și mai iubit decât știi.',
        'Chiar și cea mai întunecată noapte se termină, iar soarele răsare din nou.',
        'Vindecarea nu e liniară, și e în regulă așa.',
      ];

  @override
  String indexOfCount(int index, int total) => '$index din $total';
  @override
  String get shareStarLabel => 'Distribuie această Stea';
  @override
  String get shareStarError => 'Nu am putut distribui această stea. Încerci din nou?';

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
  String get reminderToggleLabel => 'Amintește-mi să aprind o stea';
  @override
  String get reminderTimeLabel => 'Ora mementoului';
  @override
  String get notificationPermissionDenied =>
      'Notificările sunt dezactivate pentru această aplicație în setările telefonului.';
  @override
  String get testNotificationButton => 'Trimite o notificare de test';
  @override
  String get reminderNotificationTitle => 'Aprinde o stea';

  @override
  List<String> get reminderNotificationBodies => const [
        'Ce te-a ajutat să treci peste ziua de azi, chiar și puțin?',
        'Și cel mai mic pas aprinde o stea.',
        'Un moment — ce a mers bine azi?',
        'Cerul tău așteaptă steaua din seara asta.',
        'Ai trecut peste ceva azi? Notează-l.',
      ];
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
