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
  String get navStats => 'Statistiche';
  @override
  String get navSettings => 'Impostazioni';
  @override
  String get collapseSidebarAction => 'Comprimi la barra laterale';
  @override
  String get expandSidebarAction => 'Espandi la barra laterale';

  @override
  String get statsEyebrow => 'I TUOI NUMERI';
  @override
  String get statsTitle => 'Statistiche';

  @override
  String get homeEyebrow => 'I TUOI PROGRESSI';
  @override
  String get homeTitle => 'La tua dashboard';
  @override
  String get homeSubtitle =>
      'Ogni stella è una vittoria, accesa quando ne avevi bisogno.';
  @override
  String get admireYourStars => 'Ammira le tue stelle';
  @override
  String get todayStarSectionLabel => 'Stella di oggi';
  @override
  String get litTodayTitle => 'Complimenti, hai acceso una stella oggi!';
  @override
  String get litTodayTitleHighlight => 'stella';
  @override
  String get litTodaySubtitle => '- hai portato nuova luce nella tua vita -';
  @override
  String get litTodaySubtitleHighlight => 'luce';
  @override
  String get notLitTodayLabel => 'Nessuna stella accesa oggi, per ora';
  @override
  String get notLitTodayHighlight => 'stella';
  @override
  String get lightStarCta => 'Accendine una';
  @override
  String get totalStarsLabel => 'Stelle totali';
  @override
  String get streaksSectionLabel => 'Serie';
  @override
  String get currentStreakLabel => 'Serie attuale';
  @override
  String get longestStreakLabel => 'Serie record';
  @override
  String get activityLabel => 'Attività';
  @override
  String get dayDetailEmpty => 'Nessuna stella accesa in questo giorno.';
  @override
  String get addStarForDayLabel => 'Aggiungi una stella per questo giorno';

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
  @override
  String get noCurrentStreakBody =>
      'Nessuna serie in corso al momento. Accendi una stella oggi per iniziarne una.';

  @override
  String get searchHint => 'Cerca per titolo o descrizione';
  @override
  String get noSearchResults => 'Nessuna stella corrisponde alla ricerca.';
  @override
  String get areaWinsEmpty => 'Ancora nessuna stella in questa supernova.';
  @override
  String intensityCount(int value) => '$value intensità';
  @override
  String createdOnLabel(String date) => 'Creata il $date';
  @override
  String lastStarLabel(String date) => 'Ultima stella $date';
  @override
  String get constellationsModeLabel => 'Costellazioni';
  @override
  String get listModeLabel => 'Stelle';

  @override
  String get dataSection => 'Dati';
  @override
  String get seedSampleData => 'Genera dati di esempio';
  @override
  String seedSampleDataResult(int count) =>
      'Aggiunte $count stelle a ogni costellazione di esempio.';
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
  String get archiveEmpty =>
      'Il tuo archivio è ancora vuoto. Accendi la tua prima stella, anche piccola.';

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
  String get constellationShapeMissing =>
      'La forma di questa costellazione non è stata trovata.';

  @override
  String get drawYourOwnConstellation => 'Disegna la tua costellazione';
  @override
  String get drawYourOwnShort => 'Disegna la tua';
  @override
  String get constellationEditorTitle => 'Disegna la tua costellazione';
  @override
  String get constellationEditorEditTitle => 'Modifica la tua costellazione';
  @override
  String get constellationEditorEmptyHint =>
      'Tocca ovunque per posizionare la prima stella';
  @override
  String constellationEditorDisconnectedWarning(int count) =>
      '$count stell${count == 1 ? 'a non ancora collegata' : 'e non ancora collegate'}';
  @override
  String get constellationEditorPointCapReached =>
      'Hai raggiunto il numero massimo di stelle';
  @override
  String get undoAction => 'Annulla';
  @override
  String get redoAction => 'Ripeti';
  @override
  String get deletePointAction => 'Elimina stella';
  @override
  String get saveConstellationAction => 'Salva';
  @override
  String get nameYourConstellationTitle => 'Dai un nome alla tua costellazione';
  @override
  String get constellationNameHint => 'Es. Il mio percorso';
  @override
  String get yourConstellationsLabel => 'Le tue costellazioni';
  @override
  String get constellationEditorGridToggleLabel => 'Griglia';
  @override
  String get constellationEditorHelpAction => 'Come funziona';
  @override
  String get constellationEditorHelpTitle => 'Come funziona';
  @override
  String get constellationEditorHelpAddPoint =>
      'Tocca uno spazio vuoto per aggiungere una stella';
  @override
  String get constellationEditorHelpConnectPoint =>
      'Tocca una stella, poi toccane un\'altra per collegarle con un segmento';
  @override
  String get constellationEditorHelpDisarmPoint =>
      'Tocca di nuovo la stessa stella per deselezionarla senza collegare';
  @override
  String get constellationEditorHelpMovePoint =>
      'Premi e trascina una stella per spostarla';
  @override
  String get constellationEditorHelpDeletePoint =>
      'Seleziona una stella, poi tocca l\'icona elimina per rimuoverla';
  @override
  String get constellationEditorHelpDontShowAgain => 'Non mostrarlo più';
  @override
  String get constellationEditorHelpClose => 'Ho capito';

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
  String get projectDescriptionLabel => 'Descrizione (opzionale)';
  @override
  String get projectDescriptionHint => 'Di cosa parla questo progetto?';
  @override
  String get iconLabel => 'Icona';
  @override
  String get chooseIconTitle => 'Scegli un\'icona';
  @override
  String get pickerConfirmAction => 'OK';
  @override
  String get closeAction => 'Chiudi';
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
  String get addGoalQuestion => 'Cosa vuoi raggiungere?';
  @override
  String get projectLabel => 'Costellazione';
  @override
  String get selectAProject => 'Seleziona una costellazione';
  @override
  String get dateLabel => 'Data';
  @override
  String get selectADateHint => 'Seleziona una data';
  @override
  String get timeLabel => 'Ora';
  @override
  String get selectATimeHint => 'Seleziona un orario';
  @override
  String get titleFieldLabel => 'In poche parole';
  @override
  String get titleHint => 'Es. Ho retto dopo un rifiuto e sono andato avanti';
  @override
  String get detailsLabel => 'Dettagli (opzionale)';
  @override
  String get detailsHint =>
      'Cosa ha reso difficile questo momento e come l\'hai superato';
  @override
  String get intensityLabel => 'Intensità';
  @override
  String get photoLabel => 'Foto (opzionale)';
  @override
  String get addPhotoHint => 'Aggiungi una foto';
  @override
  String get takePhotoOption => 'Scatta una foto';
  @override
  String get choosePhotoOption => 'Scegli dalla libreria';
  @override
  String get photoPickError =>
      'Non è stato possibile ottenere la foto. Riprova?';
  @override
  String get cropPhotoTitle => 'Modifica la foto';
  @override
  String get cropPhotoConfirm => 'Fatto';
  @override
  String get cropPhotoHint =>
      'Pizzica e trascina per adattare la foto alla cornice';
  @override
  String get saveChanges => 'Salva modifiche';
  @override
  String get lightThisStar => 'Accendi questa stella';
  @override
  String get cannotSaveMissingInfo =>
      'Impossibile salvare: mancano delle informazioni';
  @override
  String get gotIt => 'Ho capito';
  @override
  String get deleteStarConfirmTitle => 'Eliminare questa stella?';
  @override
  String get deleteStarConfirmBody =>
      'La stella diventerà una stella spenta: uscirà da qui, ma resterà al suo posto nel cielo e potrai farla rinascere in seguito.';
  @override
  String get deleteStarAction => 'Elimina';
  @override
  String get discardChangesConfirmTitle => 'Scartare le modifiche?';
  @override
  String get discardChangesConfirmBody =>
      'Perderai le modifiche fatte a questa stella.';
  @override
  String get discardChangesAction => 'Scarta modifiche';

  @override
  String get achievedToggleOn => 'Già raggiunta';
  @override
  String get achievedToggleOff => 'Obbiettivo futuro';
  @override
  String get targetDateLabel => 'Data obbiettivo (opzionale)';
  @override
  String get selectATargetDateHint => 'Seleziona una data';

  @override
  String goalTargetLabel(String date) => 'Obbiettivo per il $date';
  @override
  String get markAchievedAction => 'Segna come raggiunta';
  @override
  String get markAchievedSheetTitle => 'Quanto ti è costato raggiungerla?';
  @override
  String get markAchievedConfirm => 'Accendi questa stella';
  @override
  String get undoAchievedAction => 'Segna come non raggiunta';
  @override
  String get deadStarTitle => 'Stella spenta';
  @override
  String get deadStarBody =>
      'Questa stella è stata cancellata. Puoi farla rinascere come una stella nuova, nello stesso punto del cielo.';
  @override
  String get resurrectAction => 'Resuscita questa stella';

  @override
  String get newHabitEyebrow => 'NUOVO PULSAR';
  @override
  String get editHabitEyebrow => 'MODIFICA PULSAR';
  @override
  String get addHabitQuestion => 'Quale pulsar vuoi accendere?';
  @override
  String get habitFrequencyLabel => 'Frequenza';
  @override
  String get habitFrequencyDaily => 'Ogni giorno';
  @override
  String get customReminderToggleLabel => 'Orario promemoria personalizzato';
  @override
  String get deleteHabitConfirmTitle => 'Eliminare questo pulsar?';
  @override
  String get deleteHabitConfirmBody =>
      'Questo rimuove definitivamente il pulsar e tutta la sua cronologia. Non si può annullare.';
  @override
  String get deleteHabitAction => 'Elimina';

  @override
  String get habitCurrentStreakLabel => 'Serie attuale';
  @override
  String get markHabitDoneAction => 'Segna oggi come fatto';
  @override
  String get habitDoneTodayLabel => 'Fatto oggi';
  @override
  String get undoHabitTodayAction => 'Annulla';

  @override
  String openGoalsBadge(int count) =>
      count == 1 ? '1 obbiettivo aperto' : '$count obbiettivi aperti';
  @override
  String activeHabitsBadge(int count) =>
      count == 1 ? '1 pulsar attivo' : '$count pulsar attivi';

  @override
  String get starKindVictoryLabel => 'Vittorie';
  @override
  String get starKindVictoryTagLabel => 'Vittoria';
  @override
  String get starKindGoalLabel => 'Obbiettivi';
  @override
  String get starKindDeadLabel => 'Stelle morte';
  @override
  String get starKindPulsarChipLabel => 'Pulsar';
  @override
  String get starKindPulsarTagLabel => 'Pulsar';

  @override
  String get admireTagline =>
      'Per quando sei nel buio e hai bisogno di un po\' di luce.';
  @override
  String get allAreasLabel => 'Tutte le supernove';
  @override
  String get pickAtLeastOneArea =>
      'Scegli almeno una supernova per continuare.';
  @override
  String get noStarsInSelection =>
      'Nessuna stella ancora accesa nelle supernove scelte.';
  @override
  String get viewYourStars => 'Guarda le tue stelle';

  @override
  String get addWinFabLabel => 'Nuova vittoria';
  @override
  String get addGoalFabLabel => 'Nuovo obbiettivo';
  @override
  String get addHabitFabLabel => 'Nuovo pulsar';
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
  String get shareStarLabel => 'Condividi questa Stella';
  @override
  String get shareStarError =>
      'Non è stato possibile condividere questa stella. Riprova?';

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
  String get aboutTagline =>
      'Un\'app di crescita personale per registrare i momenti che hai superato.';

  @override
  List<String> get monthAbbreviations => const [
    'Gen',
    'Feb',
    'Mar',
    'Apr',
    'Mag',
    'Giu',
    'Lug',
    'Ago',
    'Set',
    'Ott',
    'Nov',
    'Dic',
  ];

  @override
  List<String> get weekdayAbbreviations => const [
    'Lun',
    'Mar',
    'Mer',
    'Gio',
    'Ven',
    'Sab',
    'Dom',
  ];

  @override
  String monthTitle(DateTime month) =>
      '${_fullMonths[month.month - 1]} ${month.year}';
}

const _fullMonths = [
  'Gennaio',
  'Febbraio',
  'Marzo',
  'Aprile',
  'Maggio',
  'Giugno',
  'Luglio',
  'Agosto',
  'Settembre',
  'Ottobre',
  'Novembre',
  'Dicembre',
];
