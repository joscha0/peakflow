// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Peak Flow';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get saveUpper => 'SAVE';

  @override
  String get updateUpper => 'UPDATE';

  @override
  String get apply => 'Apply';

  @override
  String get edit => 'edit';

  @override
  String get delete => 'delete';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsIntro =>
      'Customize reminders, tracking preferences, and data tools.';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceDescription =>
      'Control how Peak Flow looks while you record daily readings.';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageDescription => 'Choose the language to use in the app.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get darkModeTitle => 'Dark mode';

  @override
  String get darkModeEnabledDescription => 'Dark mode is enabled.';

  @override
  String get darkModeDisabledDescription => 'Dark mode is disabled.';

  @override
  String get primaryColorTitle => 'Primary color';

  @override
  String get primaryColorDescription =>
      'Pick the accent color used for buttons, highlights, and controls.';

  @override
  String get peakFlowSetupTitle => 'Peak Flow Setup';

  @override
  String get peakFlowSetupDescription =>
      'Set the device limit separately from the max used to calculate your color zones.';

  @override
  String get deviceMaxCapacityTitle => 'Device max capacity';

  @override
  String get deviceMaxCapacityDescription =>
      'This is the maximum value your device can measure and the upper limit used for input and graphs.';

  @override
  String get deviceMaxLabel => 'device max L/min';

  @override
  String get automaticMaxTitle => 'Automatic max';

  @override
  String get manualMaxTitle => 'Manual max';

  @override
  String get colorMaxDescription =>
      'Auto uses your highest saved reading for the green, orange, and red zones. Turn it off to enter your own max.';

  @override
  String currentAutomaticMax(int value) {
    return 'Current automatic max: $value L/min';
  }

  @override
  String automaticMaxFallback(int value) {
    return 'Automatic mode will use your best saved reading once you have one. Until then it falls back to $value L/min.';
  }

  @override
  String get manualMaxDescription =>
      'Manual mode uses the value below as the color reference.';

  @override
  String get manualColorMaxLabel => 'manual color max L/min';

  @override
  String get reminderNotificationTitle => 'Reminder Notification';

  @override
  String get reminderNotificationDescription =>
      'Manage the daily reminder message and the time it appears.';

  @override
  String get dailyReminderTitle => 'Daily reminder';

  @override
  String get dailyReminderDescription =>
      'Turn scheduled reminders on or off without leaving this screen.';

  @override
  String get notificationTitleLabel => 'title';

  @override
  String get notificationBodyLabel => 'body';

  @override
  String get notificationDefaultTitle => 'Test your Peakflow';

  @override
  String get notificationDefaultBody => 'Take your peakflow record now!';

  @override
  String get reminderTimeTitle => 'Reminder time';

  @override
  String scheduledForEachDay(String time) {
    return 'Scheduled for $time each day.';
  }

  @override
  String get scheduledRemindersSupported =>
      'Daily scheduled reminders are available on Android, iPhone, and macOS.';

  @override
  String get scheduledRemindersSupportedSnackbar =>
      'Daily reminders are currently supported on Android, iPhone, and macOS.';

  @override
  String get notificationPermissionRequired =>
      'Notification permission is required to enable daily reminders.';

  @override
  String get reminderUpdated => 'Reminder updated.';

  @override
  String get reminderUpdateFailed =>
      'Could not update reminder because notification permission is not available.';

  @override
  String get dataTitle => 'Data';

  @override
  String get dataDescription =>
      'Create or restore a portable backup of your readings and notes.';

  @override
  String get jsonBackupTitle => 'JSON backup';

  @override
  String get jsonBackupDescription =>
      'Export a restorable backup, or import one to replace the local readings on this device.';

  @override
  String get exportJson => 'EXPORT JSON';

  @override
  String get importJson => 'IMPORT JSON';

  @override
  String get exportDownloadStarted => 'Export download started.';

  @override
  String get exportJsonBackupDialogTitle => 'Export JSON backup';

  @override
  String get jsonBackupSaved => 'JSON backup saved.';

  @override
  String get jsonFileEmpty => 'That JSON file is empty.';

  @override
  String get jsonFileInvalid =>
      'That JSON file is not a valid Peak Flow backup.';

  @override
  String get jsonFileReadFailed => 'Could not read that JSON file.';

  @override
  String get jsonFileImportFailed => 'Could not import that JSON file.';

  @override
  String get backupMergedNoNewData => 'Backup merged. No new data was found.';

  @override
  String backupMerged(int days, int readings) {
    return 'Merged $days days and added $readings readings.';
  }

  @override
  String get importedOneDayFromJson => 'Imported 1 day from JSON.';

  @override
  String importedDaysFromJson(int count) {
    return 'Imported $count days from JSON.';
  }

  @override
  String get importJsonBackupTitle => 'Import JSON backup';

  @override
  String get fileLabel => 'File';

  @override
  String get sizeLabel => 'Size';

  @override
  String get currentDataLabel => 'Current data';

  @override
  String get backupDataLabel => 'Backup data';

  @override
  String get mergeResultLabel => 'Merge result';

  @override
  String daysTotal(int count) {
    return '$count days total';
  }

  @override
  String get newFromBackupLabel => 'New from backup';

  @override
  String daysReadings(int days, int readings) {
    return '$days days, $readings readings';
  }

  @override
  String get duplicatesSkippedLabel => 'Duplicates skipped';

  @override
  String readingsCount(int count) {
    return '$count readings';
  }

  @override
  String get daysChangedByMergeLabel => 'Days changed by merge';

  @override
  String daysCount(int count) {
    return '$count days';
  }

  @override
  String get symptomsAddedLabel => 'Symptoms added';

  @override
  String get dayNotesFilledLabel => 'Day notes filled';

  @override
  String get noteConflictsLabel => 'Note conflicts';

  @override
  String localNotesKept(int count) {
    return '$count local notes kept';
  }

  @override
  String get replaceWouldRemoveLabel => 'Replace would remove';

  @override
  String localOnlyDays(int count) {
    return '$count local-only days';
  }

  @override
  String get cancelUpper => 'CANCEL';

  @override
  String get importAndReplaceUpper => 'IMPORT AND REPLACE';

  @override
  String get importAndMergeUpper => 'IMPORT AND MERGE';

  @override
  String get mergeConfirmationTitle => 'Are you sure you want to merge?';

  @override
  String get replaceConfirmationTitle => 'Are you sure?';

  @override
  String mergeConfirmationMessage(
    int newReadings,
    int duplicateReadings,
    int dayNoteConflicts,
  ) {
    return 'This will keep your current data, add $newReadings new readings, skip $duplicateReadings duplicate readings, and keep local notes for $dayNoteConflicts note conflicts.';
  }

  @override
  String replaceConfirmationMessage(
    String currentData,
    String backupData,
    int currentOnlyDays,
  ) {
    return 'This will replace your current $currentData with $backupData from the backup. $currentOnlyDays local-only days will be removed.';
  }

  @override
  String get mergeAndImportUpper => 'MERGE AND IMPORT';

  @override
  String formatDaysAndReadings(int days, int readings) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    String _temp1 = intl.Intl.pluralLogic(
      readings,
      locale: localeName,
      other: '$readings readings',
      one: '1 reading',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String get debugTitle => 'Debug';

  @override
  String get debugDescription =>
      'Load sample readings for development or clear the local database again.';

  @override
  String get mockDataToolsTitle => 'Mock data tools';

  @override
  String get mockDataToolsDescription =>
      'These actions are only visible in debug builds and replace your current local dataset.';

  @override
  String get mockDaysToGenerateLabel => 'mock days to generate';

  @override
  String allowedMockDaysRange(int min, int max) {
    return 'Allowed range: $min to $max days.';
  }

  @override
  String get loadMockData => 'LOAD MOCK DATA';

  @override
  String get clearAllData => 'CLEAR ALL DATA';

  @override
  String mockDataCountError(int min, int max) {
    return 'Enter a mock data count between $min and $max.';
  }

  @override
  String loadedMockDays(int count) {
    return 'Loaded $count mock days.';
  }

  @override
  String get allLocalDataCleared => 'All local data cleared.';

  @override
  String get madeWith => 'Made with ❤️ by @joscha0';

  @override
  String get addReadingTitle => 'Add Reading';

  @override
  String get addReadingInstruction =>
      'Drag the center line to set the reading or tap the number to type it.';

  @override
  String maximumReading(int value) {
    return 'Maximum reading: $value L/min';
  }

  @override
  String get advancedTitle => 'Advanced';

  @override
  String get advancedDescription =>
      'Add date, notes, and symptoms for this day.';

  @override
  String get whenTitle => 'When';

  @override
  String get addWhenDescription =>
      'Set the date and time for this reading first.';

  @override
  String get dateLabel => 'Date';

  @override
  String get timeLabel => 'Time';

  @override
  String get notesTitle => 'Notes';

  @override
  String get readingNotesDescription => 'Add a note for this specific reading.';

  @override
  String get readingNotesLabel => 'Reading notes';

  @override
  String get readingNotesHint => 'How did the measurement feel?';

  @override
  String get symptomsOfTheDayTitle => 'Symptoms of the Day';

  @override
  String get addSymptomsDescription =>
      'Tap every symptom that applies. These day symptoms and notes are shared across all readings for this date.';

  @override
  String get dayNotesTitle => 'Day Notes';

  @override
  String get dayNotesLabel => 'Day notes';

  @override
  String get dayNotesHint => 'Weather, medication, exercise, triggers...';

  @override
  String get editDayTitle => 'Edit day';

  @override
  String editDayIntro(String date) {
    return 'Update the shared day context for $date.';
  }

  @override
  String editDaySymptomsDescription(String date) {
    return 'These symptoms are shared across all readings saved on $date.';
  }

  @override
  String get editDayNotesDescription =>
      'This note is also shared across every reading for this date.';

  @override
  String get editReadingTitle => 'Edit reading';

  @override
  String editReadingIntro(String date) {
    return 'Update the reading details for $date.';
  }

  @override
  String editReadingWhenDescription(String date) {
    return 'This reading belongs to $date. You can adjust the time here.';
  }

  @override
  String get peakFlowValueTitle => 'Peak Flow Value';

  @override
  String get editReadingValueDescription =>
      'Drag the center line to update the reading or type the value directly.';

  @override
  String get deleteDayTitle => 'Delete day?';

  @override
  String get deleteDayMessage =>
      'This will permanently delete the day and all readings saved for it.';

  @override
  String get deleteDayConfirm => 'Delete day';

  @override
  String get deleteReadingTitle => 'Delete reading?';

  @override
  String get deleteReadingMessage =>
      'This will permanently delete this reading.';

  @override
  String get deleteReadingConfirm => 'Delete reading';

  @override
  String get symptomsTitle => 'Symptoms';

  @override
  String get readingsTitle => 'Readings';

  @override
  String get notesPrefix => 'Notes: ';

  @override
  String get addReadingButton => 'Add reading';

  @override
  String get noValues => 'No values';

  @override
  String get timelineTab => 'Timeline';

  @override
  String get graphTab => 'Graph';

  @override
  String get gapOneDay => '1 day';

  @override
  String gapDays(int count) {
    return '$count days';
  }

  @override
  String get gapBetween => 'between';

  @override
  String get gapMissing => 'missing';

  @override
  String get symptomCough => 'Cough';

  @override
  String get symptomCoughNight => 'Cough night';

  @override
  String get symptomWheezingBreathing => 'Wheezing breathing';

  @override
  String get symptomShortnessOfBreath => 'Shortness of breath';

  @override
  String get symptomDifficultBreathing => 'Difficult breathing';

  @override
  String get symptomChestTightnessOrPain => 'Chest tightness or pain';

  @override
  String get symptomUnableToWork => 'Unable to work';

  @override
  String get dataScreenTitle => 'Data';

  @override
  String get dateRangeTitle => 'Date Range';

  @override
  String get rangeAll => 'All';

  @override
  String get rangeLast3Months => 'Last 3 Months';

  @override
  String get rangeCustom => 'Custom';

  @override
  String get statAverage => 'Avg';

  @override
  String get statHighest => 'Highest';

  @override
  String get statLowest => 'Lowest';

  @override
  String get statMeasurements => 'Measurements';

  @override
  String get timesUnit => 'times';

  @override
  String get reportsTitle => 'Reports';

  @override
  String exportReportFor(String range) {
    return 'Export Report for $range';
  }

  @override
  String get generatingPdf => 'Generating PDF';

  @override
  String get pdfReport => 'PDF Report';

  @override
  String get generatingCsv => 'Generating CSV';

  @override
  String get csvReport => 'CSV Report';

  @override
  String get savePdfReportDialogTitle => 'Save PDF Report';

  @override
  String get pdfReportDownloadStarted => 'PDF report download started.';

  @override
  String get pdfReportSaved => 'PDF report saved.';

  @override
  String get pdfReportGenerateFailed => 'Could not generate the PDF report.';

  @override
  String get saveCsvReportDialogTitle => 'Save CSV Report';

  @override
  String get csvReportDownloadStarted => 'CSV report download started.';

  @override
  String get csvReportSaved => 'CSV report saved.';

  @override
  String get csvReportGenerateFailed => 'Could not generate the CSV report.';

  @override
  String get noDataAvailable => 'No data available yet.';

  @override
  String get customRangeTitle => 'Custom Range';

  @override
  String get customRangeDescription =>
      'Choose start and end dates for the chart.';

  @override
  String get startLabel => 'Start';

  @override
  String get endLabel => 'End';

  @override
  String get zoneStable => 'Stable';

  @override
  String get zoneCaution => 'Caution';

  @override
  String get zoneActionNeeded => 'Action Needed';

  @override
  String reportPageOf(int page, int pages) {
    return 'Page $page of $pages';
  }

  @override
  String get peakFlowReportTitle => 'Peak Flow Report';

  @override
  String reportRange(String range) {
    return 'Range: $range';
  }

  @override
  String reportGenerated(String date) {
    return 'Generated: $date';
  }

  @override
  String get reportStats => 'Stats';

  @override
  String get reportAverage => 'Average';

  @override
  String get reportReadingsByZone => 'Readings By Zone';

  @override
  String get reportReferenceMax => 'Reference Max';

  @override
  String get reportActionNeededDates => 'Action Needed Dates';

  @override
  String get reportNoActionNeeded =>
      'No readings were in the action needed zone.';

  @override
  String get reportNoSavedReadingsRange =>
      'No saved readings in this date range.';

  @override
  String get reportNoSavedReadingsMonth => 'No readings saved this month.';

  @override
  String get reportNoGraphReadingsMonth =>
      'No readings to graph for this month.';

  @override
  String get reportXAxisDescription =>
      'X axis: day of month. Background bands match the app zones.';

  @override
  String reportDayNote(String note) {
    return 'Day note: $note';
  }

  @override
  String reportSymptoms(String symptoms) {
    return 'Symptoms: $symptoms';
  }

  @override
  String get reportNoReadingsDay => 'No readings saved for this day.';

  @override
  String get reportTime => 'Time';

  @override
  String get reportValue => 'Value';

  @override
  String get reportZone => 'Zone';

  @override
  String get reportReadingNote => 'Reading note';
}
