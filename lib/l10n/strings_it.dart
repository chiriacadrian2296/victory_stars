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
  String get navStars => 'Stelle';
  @override
  String get navSettings => 'Impostazioni';

  @override
  String get homeEyebrow => 'I TUOI PROGRESSI';
  @override
  String get homeTitle => 'La tua dashboard';
  @override
  String get homeSubtitle => 'Ogni vittoria è una stella, accesa quando ne avevi bisogno.';
  @override
  String get admireYourStars => 'Ammira le tue stelle';
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
  String get starsEyebrow => 'LE TUE STELLE';
  @override
  String get starsTitle => 'Esplora le tue stelle';
  @override
  String get starsSubtitle => 'Scegli un\'area, poi cerca al suo interno.';
  @override
  String get searchHint => 'Cerca per titolo o descrizione';
  @override
  String get noSearchResults => 'Nessuna stella corrisponde alla ricerca.';
  @override
  String get areaWinsEmpty => 'Nessuna stella accesa in quest\'area, per ora.';

  @override
  String get dataSection => 'Dati';
  @override
  String get seedSampleData => 'Genera dati di esempio';
  @override
  String seedSampleDataResult(int count) => 'Aggiunte $count vittorie a ogni progetto di esempio.';
  @override
  String get resetAllData => 'Azzera tutti i dati';
  @override
  String get resetAllDataConfirmTitle => 'Azzerare tutti i dati?';
  @override
  String get resetAllDataConfirmBody =>
      'Questa azione elimina definitivamente ogni vittoria e progetto. Non può essere annullata.';
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
  String get skySubtitle => 'Ogni area ha le sue costellazioni.';
  @override
  String starsCount(int count) => count == 1 ? '1 stella' : '$count stelle';
  @override
  String get newProjectTooltip => 'Nuovo progetto';
  @override
  String areaEmptyProjects(String areaName) =>
      'Ancora nessun progetto in $areaName. Iniziane uno per accendere le prime stelle qui.';

  @override
  String get addWinTooltip => 'Aggiungi una vittoria';
  @override
  String get constellationShapeMissing => 'La forma della costellazione di questo progetto non è stata trovata.';

  @override
  String get newProjectEyebrow => 'NUOVO PROGETTO';
  @override
  String get newProjectQuestion => 'Di che progetto si tratta?';
  @override
  String get areaLabel => 'Area';
  @override
  String get nameLabel => 'Nome';
  @override
  String get newProjectNameHint => 'Es. Costruire questa app';
  @override
  String get iconLabel => 'Icona';
  @override
  String get createProject => 'Crea progetto';
  @override
  String get newProject => 'Nuovo progetto';

  @override
  String get newStarEyebrow => 'NUOVA STELLA';
  @override
  String get editStarEyebrow => 'MODIFICA STELLA';
  @override
  String get addWinQuestion => 'Cosa hai superato?';
  @override
  String get projectLabel => 'Progetto';
  @override
  String get selectAProject => 'Seleziona un progetto';
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
  String get crisisTitle => 'In questo momento sembra tutto buio.';
  @override
  String crisisSubtitleWithWins(int count) => count == 1
      ? 'Hai già acceso 1 stella finora. Guardiamole una alla volta.'
      : 'Hai già acceso $count stelle finora. Guardiamole una alla volta.';
  @override
  String get crisisSubtitleNoWins => 'Non hai ancora acceso nessuna stella. Torna qui quando ne avrai una.';
  @override
  String get viewYourStars => 'Guarda le tue stelle';

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
  String get reminderToggleLabel => 'Ricordami di registrare una vittoria';
  @override
  String get reminderTimeLabel => 'Orario del promemoria';
  @override
  String get notificationPermissionDenied =>
      'Le notifiche sono disattivate per questa app nelle impostazioni del telefono.';
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
