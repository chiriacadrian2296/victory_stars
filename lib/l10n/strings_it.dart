import 'app_strings.dart';

class StringsIt implements AppStrings {
  const StringsIt();

  @override
  String get languageCode => 'it';

  @override
  String get areaPhysical => 'Fisica';
  @override
  String get areaPsychological => 'Psicologica';
  @override
  String get areaProfessional => 'Professionale';
  @override
  String get areaFinancial => 'Finanziaria';
  @override
  String get areaPersonal => 'Personale';
  @override
  String get areaSocial => 'Sociale';
  @override
  String get areaSpiritual => 'Spirituale';
  @override
  String get areaPhilanthropic => 'Filantropica';

  @override
  String get navHome => 'Home';
  @override
  String get navSky => 'Cielo';
  @override
  String get navSettings => 'Impostazioni';

  @override
  String get homeEyebrow => 'I TUOI PROGRESSI';
  @override
  String get homeTitle => 'La tua dashboard';
  @override
  String get homeSubtitle => 'Ogni stella è una vittoria, accesa quando ne avevi bisogno.';
  @override
  String get admireYourStars => 'Ammira le tue stelle';
  @override
  String get overviewLabel => 'Panoramica';
  @override
  String get totalStarsLabel => 'Stelle totali';
  @override
  String get currentStreakLabel => 'Serie attuale';
  @override
  String get longestStreakLabel => 'Serie record';
  @override
  String get activityLabel => 'Attività';
  @override
  String get dayDetailEmpty => 'Nessuna stella accesa in questo giorno.';

  @override
  String get firstStarLabel => 'Prima stella';
  @override
  String get mostRecentStarLabel => 'Stella più recente';
  @override
  String get combinedIntensityLabel => 'Intensità complessiva';
  @override
  String get starsByAreaLabel => 'Per supernova';
  @override
  String get streakFromLabel => 'Da';
  @override
  String get streakToLabel => 'A';
  @override
  String get todayLabel => 'Oggi';
  @override
  String get starsLoggedLabel => 'Stelle registrate';
  @override
  String get streakStillGoingLabel => 'Ancora in corso';
  @override
  String get noCurrentStreakBody => 'Nessuna serie in corso al momento. Accendi una stella oggi per iniziarne una.';

  @override
  String get searchHint => 'Cerca per titolo o descrizione';
  @override
  String get noSearchResults => 'Nessuna stella corrisponde alla ricerca.';
  @override
  String get areaWinsEmpty => 'Nessuna stella accesa in questa supernova, per ora.';
  @override
  String get constellationsModeLabel => 'Costellazioni';
  @override
  String get listModeLabel => 'Stelle';

  @override
  String get dataSection => 'Dati';
  @override
  String get seedSampleData => 'Genera dati di esempio';
  @override
  String seedSampleDataResult(int count) => 'Aggiunte $count stelle a ogni costellazione di esempio.';
  @override
  String get resetAllData => 'Azzera tutti i dati';
  @override
  String get resetAllDataConfirmTitle => 'Azzerare tutti i dati?';
  @override
  String get resetAllDataConfirmBody =>
      'Questa azione elimina definitivamente ogni stella e costellazione. Non può essere annullata.';
  @override
  String get cancel => 'Annulla';
  @override
  String get deleteEverything => 'Elimina tutto';
  @override
  String get allDataCleared => 'Tutti i dati sono stati eliminati.';
  @override
  String get archiveEmpty => 'Il tuo archivio è ancora vuoto. Accendi la tua prima stella, anche piccola.';

  @override
  String get skyEyebrow => 'IL TUO CIELO';
  @override
  String get skyTitle => 'Esplora il tuo cielo';
  @override
  String get skySubtitle => 'Ogni supernova ha le sue costellazioni.';
  @override
  String starsCount(int count) => count == 1 ? '1 stella' : '$count stelle';
  @override
  String areaEmptyProjects(String areaName) =>
      'Ancora nessuna costellazione in $areaName. Iniziane una per accendere le prime stelle qui.';

  @override
  String get constellationShapeMissing => 'La forma di questa costellazione non è stata trovata.';

  @override
  String get newProjectEyebrow => 'NUOVA COSTELLAZIONE';
  @override
  String get newProjectQuestion => 'Di che costellazione si tratta?';
  @override
  String get areaLabel => 'Supernova';
  @override
  String get nameLabel => 'Nome';
  @override
  String get newProjectNameHint => 'Es. Costruire questa app';
  @override
  String get iconLabel => 'Icona';
  @override
  String get createProject => 'Crea costellazione';
  @override
  String get newProject => 'Nuova costellazione';

  @override
  String get newStarEyebrow => 'NUOVA STELLA';
  @override
  String get editStarEyebrow => 'MODIFICA STELLA';
  @override
  String get addWinQuestion => 'Cosa hai superato?';
  @override
  String get projectLabel => 'Costellazione';
  @override
  String get selectAProject => 'Seleziona una costellazione';
  @override
  String get dateLabel => 'Data';
  @override
  String get titleFieldLabel => 'In poche parole';
  @override
  String get titleHint => 'Es. Ho retto dopo un rifiuto e sono andato avanti';
  @override
  String get detailsLabel => 'Dettagli (opzionale)';
  @override
  String get detailsHint => 'Cosa ha reso difficile questo momento e come l\'hai superato';
  @override
  String get intensityLabel => 'Intensità — quanto ti è costato';
  @override
  String get saveChanges => 'Salva modifiche';
  @override
  String get lightThisStar => 'Accendi questa stella';

  @override
  String get admireTagline => 'Per quando sei nel buio e hai bisogno di un po\' di luce.';
  @override
  String get allAreasLabel => 'Tutte le supernove';
  @override
  String get pickAtLeastOneArea => 'Scegli almeno una supernova per continuare.';
  @override
  String get noStarsInSelection => 'Nessuna stella ancora accesa nelle supernove scelte.';
  @override
  String get viewYourStars => 'Guarda le tue stelle';

  @override
  String get addWinFabLabel => 'Nuova stella';
  @override
  String get newConstellationOption => 'Nuova costellazione';

  @override
  List<String> get upliftingQuotes => const [
        'Non devi vedere tutta la scala, basta il primo gradino.',
        'Anche i piccoli passi ti portano avanti.',
        'Hai superato ogni giorno difficile finora. Un record perfetto.',
        'Riposare non significa arrendersi.',
        'Puoi essere un lavoro in corso e meritare amore, allo stesso tempo.',
        'Questo sentimento è reale, ma non è per sempre.',
        'Non devi avere tutte le risposte per continuare ad andare avanti.',
        'Progresso, non perfezione.',
        "Certi giorni basta essere ancora qui. E conta.",
        'Hai superato il 100% dei tuoi giorni peggiori, finora.',
        'Sii paziente con te stesso. In natura nulla fiorisce tutto l\'anno.',
        'Va bene non stare bene — solo non restarci da solo.',
        'Un respiro alla volta. È tutto ciò che questo momento ti chiede.',
        'Sei più forte di quanto pensi e più amato di quanto sai.',
        'Anche la notte più buia finisce, e il sole sorge di nuovo.',
        "Guarire non è un percorso lineare, ed è normale.",
      ];

  @override
  String indexOfCount(int index, int total) => '$index di $total';

  @override
  String get settingsEyebrow => 'IMPOSTAZIONI';
  @override
  String get settingsTitle => 'Impostazioni';
  @override
  String get appearanceSection => 'Aspetto';
  @override
  String get themeLight => 'Chiaro';
  @override
  String get themeDark => 'Scuro';
  @override
  String get languageSection => 'Lingua';
  @override
  String get languageEnglish => 'English';
  @override
  String get languageItalian => 'Italiano';
  @override
  String get languageRomanian => 'Română';
  @override
  String get reminderSection => 'Promemoria giornaliero';
  @override
  String get reminderToggleLabel => 'Ricordami di accendere una stella';
  @override
  String get reminderTimeLabel => 'Orario del promemoria';
  @override
  String get notificationPermissionDenied =>
      'Le notifiche sono disattivate per questa app nelle impostazioni del telefono.';
  @override
  String get testNotificationButton => 'Invia notifica di prova';
  @override
  String get reminderNotificationTitle => 'Accendi una stella';

  @override
  List<String> get reminderNotificationBodies => const [
        "Cosa ti ha aiutato a superare oggi, anche solo un po'?",
        'Anche il passo più piccolo accende una stella.',
        "Un attimo — cos'è andato bene oggi?",
        'Il tuo cielo aspetta la stella di stasera.',
        'Hai superato qualcosa oggi? Scrivilo.',
      ];
  @override
  String get aboutSection => 'Informazioni';
  @override
  String aboutVersion(String version) => 'Versione $version';
  @override
  String get aboutTagline => 'Un\'app di crescita personale per registrare i momenti che hai superato.';

  @override
  List<String> get monthAbbreviations => const [
        'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu',
        'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic',
      ];

  @override
  List<String> get weekdayAbbreviations => const ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

  @override
  String monthTitle(DateTime month) => '${_fullMonths[month.month - 1]} ${month.year}';
}

const _fullMonths = [
  'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
  'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre',
];
