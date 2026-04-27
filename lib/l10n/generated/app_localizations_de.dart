// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Peak Flow';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get saveUpper => 'SPEICHERN';

  @override
  String get updateUpper => 'AKTUALISIEREN';

  @override
  String get apply => 'Anwenden';

  @override
  String get edit => 'bearbeiten';

  @override
  String get delete => 'löschen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsIntro =>
      'Passe Erinnerungen, Messwerte und Datenwerkzeuge an.';

  @override
  String get appearanceTitle => 'Darstellung';

  @override
  String get appearanceDescription =>
      'Lege fest, wie Peak Flow beim Erfassen deiner Messwerte aussieht.';

  @override
  String get languageTitle => 'Sprache';

  @override
  String get languageDescription =>
      'Wähle die Sprache, die in der App genutzt werden soll.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get darkModeTitle => 'Dunkelmodus';

  @override
  String get darkModeEnabledDescription => 'Der Dunkelmodus ist aktiviert.';

  @override
  String get darkModeDisabledDescription => 'Der Dunkelmodus ist deaktiviert.';

  @override
  String get primaryColorTitle => 'Akzentfarbe';

  @override
  String get primaryColorDescription =>
      'Wähle die Akzentfarbe für Buttons, Hervorhebungen und Steuerelemente.';

  @override
  String get peakFlowSetupTitle => 'Peak-Flow-Einrichtung';

  @override
  String get peakFlowSetupDescription =>
      'Lege die Gerätegrenze getrennt vom Maximalwert für deine Farbzonen fest.';

  @override
  String get deviceMaxCapacityTitle => 'Maximale Geräteleistung';

  @override
  String get deviceMaxCapacityDescription =>
      'Das ist der höchste Wert, den dein Gerät messen kann, und die Obergrenze für Eingaben und Diagramme.';

  @override
  String get deviceMaxLabel => 'Gerätemaximum L/min';

  @override
  String get automaticMaxTitle => 'Automatisches Maximum';

  @override
  String get manualMaxTitle => 'Manuelles Maximum';

  @override
  String get colorMaxDescription =>
      'Automatisch nutzt deinen höchsten gespeicherten Wert für die grünen, orangenen und roten Zonen. Schalte es aus, um ein eigenes Maximum einzugeben.';

  @override
  String currentAutomaticMax(int value) {
    return 'Aktuelles automatisches Maximum: $value L/min';
  }

  @override
  String automaticMaxFallback(int value) {
    return 'Der automatische Modus nutzt deinen besten gespeicherten Messwert, sobald einer vorhanden ist. Bis dahin wird $value L/min verwendet.';
  }

  @override
  String get manualMaxDescription =>
      'Der manuelle Modus nutzt den Wert unten als Farbreferenz.';

  @override
  String get manualColorMaxLabel => 'Manuelles Farbmaximum L/min';

  @override
  String get reminderNotificationTitle => 'Erinnerung';

  @override
  String get reminderNotificationDescription =>
      'Verwalte die tägliche Erinnerung und die Uhrzeit, zu der sie erscheint.';

  @override
  String get dailyReminderTitle => 'Tägliche Erinnerung';

  @override
  String get dailyReminderDescription =>
      'Schalte geplante Erinnerungen direkt auf diesem Bildschirm ein oder aus.';

  @override
  String get notificationTitleLabel => 'Titel';

  @override
  String get notificationBodyLabel => 'Text';

  @override
  String get notificationDefaultTitle => 'Teste deinen Peakflow';

  @override
  String get notificationDefaultBody => 'Trage jetzt deinen Peakflow-Wert ein!';

  @override
  String get reminderTimeTitle => 'Erinnerungszeit';

  @override
  String scheduledForEachDay(String time) {
    return 'Geplant für täglich $time.';
  }

  @override
  String get scheduledRemindersSupported =>
      'Tägliche geplante Erinnerungen sind auf Android, iPhone und macOS verfügbar.';

  @override
  String get scheduledRemindersSupportedSnackbar =>
      'Tägliche Erinnerungen werden derzeit auf Android, iPhone und macOS unterstützt.';

  @override
  String get notificationPermissionRequired =>
      'Zum Aktivieren täglicher Erinnerungen ist die Benachrichtigungsberechtigung erforderlich.';

  @override
  String get reminderUpdated => 'Erinnerung aktualisiert.';

  @override
  String get reminderUpdateFailed =>
      'Die Erinnerung konnte nicht aktualisiert werden, weil keine Benachrichtigungsberechtigung verfügbar ist.';

  @override
  String get dataTitle => 'Daten';

  @override
  String get dataDescription =>
      'Erstelle oder stelle eine portable Sicherung deiner Messwerte und Notizen wieder her.';

  @override
  String get jsonBackupTitle => 'JSON-Sicherung';

  @override
  String get jsonBackupDescription =>
      'Exportiere eine wiederherstellbare Sicherung oder importiere eine, um die lokalen Messwerte auf diesem Gerät zu ersetzen.';

  @override
  String get exportJson => 'JSON EXPORTIEREN';

  @override
  String get importJson => 'JSON IMPORTIEREN';

  @override
  String get exportDownloadStarted => 'Export-Download gestartet.';

  @override
  String get exportJsonBackupDialogTitle => 'JSON-Sicherung exportieren';

  @override
  String get jsonBackupSaved => 'JSON-Sicherung gespeichert.';

  @override
  String get jsonFileEmpty => 'Diese JSON-Datei ist leer.';

  @override
  String get jsonFileInvalid =>
      'Diese JSON-Datei ist keine gültige Peak-Flow-Sicherung.';

  @override
  String get jsonFileReadFailed =>
      'Diese JSON-Datei konnte nicht gelesen werden.';

  @override
  String get jsonFileImportFailed =>
      'Diese JSON-Datei konnte nicht importiert werden.';

  @override
  String get backupMergedNoNewData =>
      'Sicherung zusammengeführt. Es wurden keine neuen Daten gefunden.';

  @override
  String backupMerged(int days, int readings) {
    return '$days Tage zusammengeführt und $readings Messwerte hinzugefügt.';
  }

  @override
  String get importedOneDayFromJson => '1 Tag aus JSON importiert.';

  @override
  String importedDaysFromJson(int count) {
    return '$count Tage aus JSON importiert.';
  }

  @override
  String get importJsonBackupTitle => 'JSON-Sicherung importieren';

  @override
  String get fileLabel => 'Datei';

  @override
  String get sizeLabel => 'Größe';

  @override
  String get currentDataLabel => 'Aktuelle Daten';

  @override
  String get backupDataLabel => 'Sicherungsdaten';

  @override
  String get mergeResultLabel => 'Ergebnis der Zusammenführung';

  @override
  String daysTotal(int count) {
    return '$count Tage insgesamt';
  }

  @override
  String get newFromBackupLabel => 'Neu aus Sicherung';

  @override
  String daysReadings(int days, int readings) {
    return '$days Tage, $readings Messwerte';
  }

  @override
  String get duplicatesSkippedLabel => 'Duplikate übersprungen';

  @override
  String readingsCount(int count) {
    return '$count Messwerte';
  }

  @override
  String get daysChangedByMergeLabel => 'Durch Zusammenführung geänderte Tage';

  @override
  String daysCount(int count) {
    return '$count Tage';
  }

  @override
  String get symptomsAddedLabel => 'Symptome hinzugefügt';

  @override
  String get dayNotesFilledLabel => 'Tagesnotizen ergänzt';

  @override
  String get noteConflictsLabel => 'Notizkonflikte';

  @override
  String localNotesKept(int count) {
    return '$count lokale Notizen behalten';
  }

  @override
  String get replaceWouldRemoveLabel => 'Ersetzen würde entfernen';

  @override
  String localOnlyDays(int count) {
    return '$count nur lokale Tage';
  }

  @override
  String get cancelUpper => 'ABBRECHEN';

  @override
  String get importAndReplaceUpper => 'IMPORTIEREN UND ERSETZEN';

  @override
  String get importAndMergeUpper => 'IMPORTIEREN UND ZUSAMMENFÜHREN';

  @override
  String get mergeConfirmationTitle => 'Möchtest du wirklich zusammenführen?';

  @override
  String get replaceConfirmationTitle => 'Bist du sicher?';

  @override
  String mergeConfirmationMessage(
    int newReadings,
    int duplicateReadings,
    int dayNoteConflicts,
  ) {
    return 'Deine aktuellen Daten bleiben erhalten, $newReadings neue Messwerte werden hinzugefügt, $duplicateReadings doppelte Messwerte werden übersprungen und lokale Notizen bleiben bei $dayNoteConflicts Notizkonflikten erhalten.';
  }

  @override
  String replaceConfirmationMessage(
    String currentData,
    String backupData,
    int currentOnlyDays,
  ) {
    return 'Dies ersetzt deine aktuellen Daten ($currentData) durch die Sicherung ($backupData). $currentOnlyDays nur lokale Tage werden entfernt.';
  }

  @override
  String get mergeAndImportUpper => 'ZUSAMMENFÜHREN UND IMPORTIEREN';

  @override
  String formatDaysAndReadings(int days, int readings) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tage',
      one: '1 Tag',
    );
    String _temp1 = intl.Intl.pluralLogic(
      readings,
      locale: localeName,
      other: '$readings Messwerte',
      one: '1 Messwert',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String get debugTitle => 'Debug';

  @override
  String get debugDescription =>
      'Lade Beispieldaten für die Entwicklung oder lösche die lokale Datenbank erneut.';

  @override
  String get mockDataToolsTitle => 'Werkzeuge für Beispieldaten';

  @override
  String get mockDataToolsDescription =>
      'Diese Aktionen sind nur in Debug-Builds sichtbar und ersetzen deine aktuellen lokalen Daten.';

  @override
  String get mockDaysToGenerateLabel => 'Zu erzeugende Beispieltage';

  @override
  String allowedMockDaysRange(int min, int max) {
    return 'Erlaubter Bereich: $min bis $max Tage.';
  }

  @override
  String get loadMockData => 'BEISPIELDATEN LADEN';

  @override
  String get clearAllData => 'ALLE DATEN LÖSCHEN';

  @override
  String mockDataCountError(int min, int max) {
    return 'Gib eine Anzahl von Beispieldaten zwischen $min und $max ein.';
  }

  @override
  String loadedMockDays(int count) {
    return '$count Beispieltage geladen.';
  }

  @override
  String get allLocalDataCleared => 'Alle lokalen Daten gelöscht.';

  @override
  String get madeWith => 'Mit ❤️ von @joscha0 erstellt';

  @override
  String get addReadingTitle => 'Messwert hinzufügen';

  @override
  String get addReadingInstruction =>
      'Ziehe die Mittellinie, um den Messwert festzulegen, oder tippe auf die Zahl, um sie einzugeben.';

  @override
  String maximumReading(int value) {
    return 'Maximaler Messwert: $value L/min';
  }

  @override
  String get advancedTitle => 'Erweitert';

  @override
  String get advancedDescription =>
      'Füge Datum, Notizen und Symptome für diesen Tag hinzu.';

  @override
  String get whenTitle => 'Wann';

  @override
  String get addWhenDescription =>
      'Lege zuerst Datum und Uhrzeit für diesen Messwert fest.';

  @override
  String get dateLabel => 'Datum';

  @override
  String get timeLabel => 'Uhrzeit';

  @override
  String get notesTitle => 'Notizen';

  @override
  String get readingNotesDescription =>
      'Füge eine Notiz für diesen Messwert hinzu.';

  @override
  String get readingNotesLabel => 'Messwertnotizen';

  @override
  String get readingNotesHint => 'Wie hat sich die Messung angefühlt?';

  @override
  String get symptomsOfTheDayTitle => 'Symptome des Tages';

  @override
  String get addSymptomsDescription =>
      'Tippe alle zutreffenden Symptome an. Diese Tagessymptome und Notizen gelten für alle Messwerte dieses Datums.';

  @override
  String get dayNotesTitle => 'Tagesnotizen';

  @override
  String get dayNotesLabel => 'Tagesnotizen';

  @override
  String get dayNotesHint => 'Wetter, Medikamente, Sport, Auslöser...';

  @override
  String get editDayTitle => 'Tag bearbeiten';

  @override
  String editDayIntro(String date) {
    return 'Aktualisiere den gemeinsamen Tageskontext für $date.';
  }

  @override
  String editDaySymptomsDescription(String date) {
    return 'Diese Symptome gelten für alle Messwerte, die am $date gespeichert sind.';
  }

  @override
  String get editDayNotesDescription =>
      'Diese Notiz gilt ebenfalls für jeden Messwert dieses Datums.';

  @override
  String get editReadingTitle => 'Messwert bearbeiten';

  @override
  String editReadingIntro(String date) {
    return 'Aktualisiere die Messwertdetails für $date.';
  }

  @override
  String editReadingWhenDescription(String date) {
    return 'Dieser Messwert gehört zu $date. Du kannst die Uhrzeit hier anpassen.';
  }

  @override
  String get peakFlowValueTitle => 'Peak-Flow-Wert';

  @override
  String get editReadingValueDescription =>
      'Ziehe die Mittellinie, um den Messwert zu ändern, oder gib den Wert direkt ein.';

  @override
  String get deleteDayTitle => 'Tag löschen?';

  @override
  String get deleteDayMessage =>
      'Dies löscht den Tag und alle dafür gespeicherten Messwerte dauerhaft.';

  @override
  String get deleteDayConfirm => 'Tag löschen';

  @override
  String get deleteReadingTitle => 'Messwert löschen?';

  @override
  String get deleteReadingMessage => 'Dies löscht diesen Messwert dauerhaft.';

  @override
  String get deleteReadingConfirm => 'Messwert löschen';

  @override
  String get symptomsTitle => 'Symptome';

  @override
  String get readingsTitle => 'Messwerte';

  @override
  String get notesPrefix => 'Notizen: ';

  @override
  String get addReadingButton => 'Messwert hinzufügen';

  @override
  String get noValues => 'Keine Werte';

  @override
  String get timelineTab => 'Verlauf';

  @override
  String get graphTab => 'Diagramm';

  @override
  String get gapOneDay => '1 Tag';

  @override
  String gapDays(int count) {
    return '$count Tage';
  }

  @override
  String get gapBetween => 'dazwischen';

  @override
  String get gapMissing => 'fehlen';

  @override
  String get symptomCough => 'Husten';

  @override
  String get symptomCoughNight => 'Nächtlicher Husten';

  @override
  String get symptomWheezingBreathing => 'Pfeifende Atmung';

  @override
  String get symptomShortnessOfBreath => 'Kurzatmigkeit';

  @override
  String get symptomDifficultBreathing => 'Atembeschwerden';

  @override
  String get symptomChestTightnessOrPain =>
      'Engegefühl oder Schmerzen in der Brust';

  @override
  String get symptomUnableToWork => 'Arbeitsunfähig';

  @override
  String get dataScreenTitle => 'Daten';

  @override
  String get dateRangeTitle => 'Zeitraum';

  @override
  String get rangeAll => 'Alle';

  @override
  String get rangeLast3Months => 'Letzte 3 Monate';

  @override
  String get rangeCustom => 'Eigener';

  @override
  String get statAverage => 'Durchschnitt';

  @override
  String get statHighest => 'Höchster';

  @override
  String get statLowest => 'Niedrigster';

  @override
  String get statMeasurements => 'Messungen';

  @override
  String get timesUnit => 'mal';

  @override
  String get reportsTitle => 'Berichte';

  @override
  String exportReportFor(String range) {
    return 'Bericht für $range exportieren';
  }

  @override
  String get generatingPdf => 'PDF wird erstellt';

  @override
  String get pdfReport => 'PDF-Bericht';

  @override
  String get generatingCsv => 'CSV wird erstellt';

  @override
  String get csvReport => 'CSV-Bericht';

  @override
  String get savePdfReportDialogTitle => 'PDF-Bericht speichern';

  @override
  String get pdfReportDownloadStarted => 'PDF-Bericht-Download gestartet.';

  @override
  String get pdfReportSaved => 'PDF-Bericht gespeichert.';

  @override
  String get pdfReportGenerateFailed =>
      'Der PDF-Bericht konnte nicht erstellt werden.';

  @override
  String get saveCsvReportDialogTitle => 'CSV-Bericht speichern';

  @override
  String get csvReportDownloadStarted => 'CSV-Bericht-Download gestartet.';

  @override
  String get csvReportSaved => 'CSV-Bericht gespeichert.';

  @override
  String get csvReportGenerateFailed =>
      'Der CSV-Bericht konnte nicht erstellt werden.';

  @override
  String get noDataAvailable => 'Noch keine Daten verfügbar.';

  @override
  String get customRangeTitle => 'Eigener Zeitraum';

  @override
  String get customRangeDescription =>
      'Wähle Start- und Enddatum für das Diagramm.';

  @override
  String get startLabel => 'Start';

  @override
  String get endLabel => 'Ende';

  @override
  String get zoneStable => 'Stabil';

  @override
  String get zoneCaution => 'Vorsicht';

  @override
  String get zoneActionNeeded => 'Handlungsbedarf';

  @override
  String reportPageOf(int page, int pages) {
    return 'Seite $page von $pages';
  }

  @override
  String get peakFlowReportTitle => 'Peak-Flow-Bericht';

  @override
  String reportRange(String range) {
    return 'Zeitraum: $range';
  }

  @override
  String reportGenerated(String date) {
    return 'Erstellt: $date';
  }

  @override
  String get reportStats => 'Statistiken';

  @override
  String get reportAverage => 'Durchschnitt';

  @override
  String get reportReadingsByZone => 'Messwerte nach Zone';

  @override
  String get reportReferenceMax => 'Referenzmaximum';

  @override
  String get reportActionNeededDates => 'Termine mit Handlungsbedarf';

  @override
  String get reportNoActionNeeded =>
      'Keine Messwerte lagen in der Zone mit Handlungsbedarf.';

  @override
  String get reportNoSavedReadingsRange =>
      'In diesem Zeitraum sind keine Messwerte gespeichert.';

  @override
  String get reportNoSavedReadingsMonth =>
      'Für diesen Monat sind keine Messwerte gespeichert.';

  @override
  String get reportNoGraphReadingsMonth =>
      'Für diesen Monat gibt es keine Messwerte zum Darstellen.';

  @override
  String get reportXAxisDescription =>
      'X-Achse: Tag des Monats. Die Hintergrundbereiche entsprechen den App-Zonen.';

  @override
  String reportDayNote(String note) {
    return 'Tagesnotiz: $note';
  }

  @override
  String reportSymptoms(String symptoms) {
    return 'Symptome: $symptoms';
  }

  @override
  String get reportNoReadingsDay =>
      'Für diesen Tag sind keine Messwerte gespeichert.';

  @override
  String get reportTime => 'Uhrzeit';

  @override
  String get reportValue => 'Wert';

  @override
  String get reportZone => 'Zone';

  @override
  String get reportReadingNote => 'Messwertnotiz';
}
