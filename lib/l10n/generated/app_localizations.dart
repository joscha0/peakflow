import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Peak Flow'**
  String get appTitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveUpper.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get saveUpper;

  /// No description provided for @updateUpper.
  ///
  /// In en, this message translates to:
  /// **'UPDATE'**
  String get updateUpper;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'delete'**
  String get delete;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsIntro.
  ///
  /// In en, this message translates to:
  /// **'Customize reminders, tracking preferences, and data tools.'**
  String get settingsIntro;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @appearanceDescription.
  ///
  /// In en, this message translates to:
  /// **'Control how Peak Flow looks while you record daily readings.'**
  String get appearanceDescription;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the language to use in the app.'**
  String get languageDescription;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// No description provided for @darkModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkModeTitle;

  /// No description provided for @darkModeEnabledDescription.
  ///
  /// In en, this message translates to:
  /// **'Dark mode is enabled.'**
  String get darkModeEnabledDescription;

  /// No description provided for @darkModeDisabledDescription.
  ///
  /// In en, this message translates to:
  /// **'Dark mode is disabled.'**
  String get darkModeDisabledDescription;

  /// No description provided for @primaryColorTitle.
  ///
  /// In en, this message translates to:
  /// **'Primary color'**
  String get primaryColorTitle;

  /// No description provided for @primaryColorDescription.
  ///
  /// In en, this message translates to:
  /// **'Pick the accent color used for buttons, highlights, and controls.'**
  String get primaryColorDescription;

  /// No description provided for @peakFlowSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Peak Flow Setup'**
  String get peakFlowSetupTitle;

  /// No description provided for @peakFlowSetupDescription.
  ///
  /// In en, this message translates to:
  /// **'Set the device limit separately from the max used to calculate your color zones.'**
  String get peakFlowSetupDescription;

  /// No description provided for @deviceMaxCapacityTitle.
  ///
  /// In en, this message translates to:
  /// **'Device max capacity'**
  String get deviceMaxCapacityTitle;

  /// No description provided for @deviceMaxCapacityDescription.
  ///
  /// In en, this message translates to:
  /// **'This is the maximum value your device can measure and the upper limit used for input and graphs.'**
  String get deviceMaxCapacityDescription;

  /// No description provided for @deviceMaxLabel.
  ///
  /// In en, this message translates to:
  /// **'device max L/min'**
  String get deviceMaxLabel;

  /// No description provided for @automaticMaxTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic max'**
  String get automaticMaxTitle;

  /// No description provided for @manualMaxTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual max'**
  String get manualMaxTitle;

  /// No description provided for @colorMaxDescription.
  ///
  /// In en, this message translates to:
  /// **'Auto uses your highest saved reading for the green, orange, and red zones. Turn it off to enter your own max.'**
  String get colorMaxDescription;

  /// No description provided for @currentAutomaticMax.
  ///
  /// In en, this message translates to:
  /// **'Current automatic max: {value} L/min'**
  String currentAutomaticMax(int value);

  /// No description provided for @automaticMaxFallback.
  ///
  /// In en, this message translates to:
  /// **'Automatic mode will use your best saved reading once you have one. Until then it falls back to {value} L/min.'**
  String automaticMaxFallback(int value);

  /// No description provided for @manualMaxDescription.
  ///
  /// In en, this message translates to:
  /// **'Manual mode uses the value below as the color reference.'**
  String get manualMaxDescription;

  /// No description provided for @manualColorMaxLabel.
  ///
  /// In en, this message translates to:
  /// **'manual color max L/min'**
  String get manualColorMaxLabel;

  /// No description provided for @reminderNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder Notification'**
  String get reminderNotificationTitle;

  /// No description provided for @reminderNotificationDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage the daily reminder message and the time it appears.'**
  String get reminderNotificationDescription;

  /// No description provided for @dailyReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get dailyReminderTitle;

  /// No description provided for @dailyReminderDescription.
  ///
  /// In en, this message translates to:
  /// **'Turn scheduled reminders on or off without leaving this screen.'**
  String get dailyReminderDescription;

  /// No description provided for @notificationTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'title'**
  String get notificationTitleLabel;

  /// No description provided for @notificationBodyLabel.
  ///
  /// In en, this message translates to:
  /// **'body'**
  String get notificationBodyLabel;

  /// No description provided for @notificationDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Test your Peakflow'**
  String get notificationDefaultTitle;

  /// No description provided for @notificationDefaultBody.
  ///
  /// In en, this message translates to:
  /// **'Take your peakflow record now!'**
  String get notificationDefaultBody;

  /// No description provided for @reminderTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTimeTitle;

  /// No description provided for @scheduledForEachDay.
  ///
  /// In en, this message translates to:
  /// **'Scheduled for {time} each day.'**
  String scheduledForEachDay(String time);

  /// No description provided for @scheduledRemindersSupported.
  ///
  /// In en, this message translates to:
  /// **'Daily scheduled reminders are available on Android, iPhone, and macOS.'**
  String get scheduledRemindersSupported;

  /// No description provided for @scheduledRemindersSupportedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Daily reminders are currently supported on Android, iPhone, and macOS.'**
  String get scheduledRemindersSupportedSnackbar;

  /// No description provided for @notificationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is required to enable daily reminders.'**
  String get notificationPermissionRequired;

  /// No description provided for @reminderUpdated.
  ///
  /// In en, this message translates to:
  /// **'Reminder updated.'**
  String get reminderUpdated;

  /// No description provided for @reminderUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update reminder because notification permission is not available.'**
  String get reminderUpdateFailed;

  /// No description provided for @dataTitle.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dataTitle;

  /// No description provided for @dataDescription.
  ///
  /// In en, this message translates to:
  /// **'Create or restore a portable backup of your readings and notes.'**
  String get dataDescription;

  /// No description provided for @jsonBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'JSON backup'**
  String get jsonBackupTitle;

  /// No description provided for @jsonBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Export a restorable backup, or import one to replace the local readings on this device.'**
  String get jsonBackupDescription;

  /// No description provided for @exportJson.
  ///
  /// In en, this message translates to:
  /// **'EXPORT JSON'**
  String get exportJson;

  /// No description provided for @importJson.
  ///
  /// In en, this message translates to:
  /// **'IMPORT JSON'**
  String get importJson;

  /// No description provided for @exportDownloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Export download started.'**
  String get exportDownloadStarted;

  /// No description provided for @exportJsonBackupDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Export JSON backup'**
  String get exportJsonBackupDialogTitle;

  /// No description provided for @jsonBackupSaved.
  ///
  /// In en, this message translates to:
  /// **'JSON backup saved.'**
  String get jsonBackupSaved;

  /// No description provided for @jsonFileEmpty.
  ///
  /// In en, this message translates to:
  /// **'That JSON file is empty.'**
  String get jsonFileEmpty;

  /// No description provided for @jsonFileInvalid.
  ///
  /// In en, this message translates to:
  /// **'That JSON file is not a valid Peak Flow backup.'**
  String get jsonFileInvalid;

  /// No description provided for @jsonFileReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read that JSON file.'**
  String get jsonFileReadFailed;

  /// No description provided for @jsonFileImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not import that JSON file.'**
  String get jsonFileImportFailed;

  /// No description provided for @backupMergedNoNewData.
  ///
  /// In en, this message translates to:
  /// **'Backup merged. No new data was found.'**
  String get backupMergedNoNewData;

  /// No description provided for @backupMerged.
  ///
  /// In en, this message translates to:
  /// **'Merged {days} days and added {readings} readings.'**
  String backupMerged(int days, int readings);

  /// No description provided for @importedOneDayFromJson.
  ///
  /// In en, this message translates to:
  /// **'Imported 1 day from JSON.'**
  String get importedOneDayFromJson;

  /// No description provided for @importedDaysFromJson.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} days from JSON.'**
  String importedDaysFromJson(int count);

  /// No description provided for @importJsonBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Import JSON backup'**
  String get importJsonBackupTitle;

  /// No description provided for @fileLabel.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get fileLabel;

  /// No description provided for @sizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get sizeLabel;

  /// No description provided for @currentDataLabel.
  ///
  /// In en, this message translates to:
  /// **'Current data'**
  String get currentDataLabel;

  /// No description provided for @backupDataLabel.
  ///
  /// In en, this message translates to:
  /// **'Backup data'**
  String get backupDataLabel;

  /// No description provided for @mergeResultLabel.
  ///
  /// In en, this message translates to:
  /// **'Merge result'**
  String get mergeResultLabel;

  /// No description provided for @daysTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} days total'**
  String daysTotal(int count);

  /// No description provided for @newFromBackupLabel.
  ///
  /// In en, this message translates to:
  /// **'New from backup'**
  String get newFromBackupLabel;

  /// No description provided for @daysReadings.
  ///
  /// In en, this message translates to:
  /// **'{days} days, {readings} readings'**
  String daysReadings(int days, int readings);

  /// No description provided for @duplicatesSkippedLabel.
  ///
  /// In en, this message translates to:
  /// **'Duplicates skipped'**
  String get duplicatesSkippedLabel;

  /// No description provided for @readingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} readings'**
  String readingsCount(int count);

  /// No description provided for @daysChangedByMergeLabel.
  ///
  /// In en, this message translates to:
  /// **'Days changed by merge'**
  String get daysChangedByMergeLabel;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysCount(int count);

  /// No description provided for @symptomsAddedLabel.
  ///
  /// In en, this message translates to:
  /// **'Symptoms added'**
  String get symptomsAddedLabel;

  /// No description provided for @dayNotesFilledLabel.
  ///
  /// In en, this message translates to:
  /// **'Day notes filled'**
  String get dayNotesFilledLabel;

  /// No description provided for @noteConflictsLabel.
  ///
  /// In en, this message translates to:
  /// **'Note conflicts'**
  String get noteConflictsLabel;

  /// No description provided for @localNotesKept.
  ///
  /// In en, this message translates to:
  /// **'{count} local notes kept'**
  String localNotesKept(int count);

  /// No description provided for @replaceWouldRemoveLabel.
  ///
  /// In en, this message translates to:
  /// **'Replace would remove'**
  String get replaceWouldRemoveLabel;

  /// No description provided for @localOnlyDays.
  ///
  /// In en, this message translates to:
  /// **'{count} local-only days'**
  String localOnlyDays(int count);

  /// No description provided for @cancelUpper.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancelUpper;

  /// No description provided for @importAndReplaceUpper.
  ///
  /// In en, this message translates to:
  /// **'IMPORT AND REPLACE'**
  String get importAndReplaceUpper;

  /// No description provided for @importAndMergeUpper.
  ///
  /// In en, this message translates to:
  /// **'IMPORT AND MERGE'**
  String get importAndMergeUpper;

  /// No description provided for @mergeConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to merge?'**
  String get mergeConfirmationTitle;

  /// No description provided for @replaceConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get replaceConfirmationTitle;

  /// No description provided for @mergeConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'This will keep your current data, add {newReadings} new readings, skip {duplicateReadings} duplicate readings, and keep local notes for {dayNoteConflicts} note conflicts.'**
  String mergeConfirmationMessage(
    int newReadings,
    int duplicateReadings,
    int dayNoteConflicts,
  );

  /// No description provided for @replaceConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'This will replace your current {currentData} with {backupData} from the backup. {currentOnlyDays} local-only days will be removed.'**
  String replaceConfirmationMessage(
    String currentData,
    String backupData,
    int currentOnlyDays,
  );

  /// No description provided for @mergeAndImportUpper.
  ///
  /// In en, this message translates to:
  /// **'MERGE AND IMPORT'**
  String get mergeAndImportUpper;

  /// No description provided for @formatDaysAndReadings.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}}, {readings, plural, =1{1 reading} other{{readings} readings}}'**
  String formatDaysAndReadings(int days, int readings);

  /// No description provided for @debugTitle.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get debugTitle;

  /// No description provided for @debugDescription.
  ///
  /// In en, this message translates to:
  /// **'Load sample readings for development or clear the local database again.'**
  String get debugDescription;

  /// No description provided for @mockDataToolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Mock data tools'**
  String get mockDataToolsTitle;

  /// No description provided for @mockDataToolsDescription.
  ///
  /// In en, this message translates to:
  /// **'These actions are only visible in debug builds and replace your current local dataset.'**
  String get mockDataToolsDescription;

  /// No description provided for @mockDaysToGenerateLabel.
  ///
  /// In en, this message translates to:
  /// **'mock days to generate'**
  String get mockDaysToGenerateLabel;

  /// No description provided for @allowedMockDaysRange.
  ///
  /// In en, this message translates to:
  /// **'Allowed range: {min} to {max} days.'**
  String allowedMockDaysRange(int min, int max);

  /// No description provided for @loadMockData.
  ///
  /// In en, this message translates to:
  /// **'LOAD MOCK DATA'**
  String get loadMockData;

  /// No description provided for @clearAllData.
  ///
  /// In en, this message translates to:
  /// **'CLEAR ALL DATA'**
  String get clearAllData;

  /// No description provided for @mockDataCountError.
  ///
  /// In en, this message translates to:
  /// **'Enter a mock data count between {min} and {max}.'**
  String mockDataCountError(int min, int max);

  /// No description provided for @loadedMockDays.
  ///
  /// In en, this message translates to:
  /// **'Loaded {count} mock days.'**
  String loadedMockDays(int count);

  /// No description provided for @allLocalDataCleared.
  ///
  /// In en, this message translates to:
  /// **'All local data cleared.'**
  String get allLocalDataCleared;

  /// No description provided for @madeWith.
  ///
  /// In en, this message translates to:
  /// **'Made with ❤️ by @joscha0'**
  String get madeWith;

  /// No description provided for @addReadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Reading'**
  String get addReadingTitle;

  /// No description provided for @addReadingInstruction.
  ///
  /// In en, this message translates to:
  /// **'Drag the center line to set the reading or tap the number to type it.'**
  String get addReadingInstruction;

  /// No description provided for @maximumReading.
  ///
  /// In en, this message translates to:
  /// **'Maximum reading: {value} L/min'**
  String maximumReading(int value);

  /// No description provided for @advancedTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advancedTitle;

  /// No description provided for @advancedDescription.
  ///
  /// In en, this message translates to:
  /// **'Add date, notes, and symptoms for this day.'**
  String get advancedDescription;

  /// No description provided for @whenTitle.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get whenTitle;

  /// No description provided for @addWhenDescription.
  ///
  /// In en, this message translates to:
  /// **'Set the date and time for this reading first.'**
  String get addWhenDescription;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @notesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesTitle;

  /// No description provided for @readingNotesDescription.
  ///
  /// In en, this message translates to:
  /// **'Add a note for this specific reading.'**
  String get readingNotesDescription;

  /// No description provided for @readingNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Reading notes'**
  String get readingNotesLabel;

  /// No description provided for @readingNotesHint.
  ///
  /// In en, this message translates to:
  /// **'How did the measurement feel?'**
  String get readingNotesHint;

  /// No description provided for @symptomsOfTheDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Symptoms of the Day'**
  String get symptomsOfTheDayTitle;

  /// No description provided for @addSymptomsDescription.
  ///
  /// In en, this message translates to:
  /// **'Tap every symptom that applies. These day symptoms and notes are shared across all readings for this date.'**
  String get addSymptomsDescription;

  /// No description provided for @dayNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Day Notes'**
  String get dayNotesTitle;

  /// No description provided for @dayNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Day notes'**
  String get dayNotesLabel;

  /// No description provided for @dayNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Weather, medication, exercise, triggers...'**
  String get dayNotesHint;

  /// No description provided for @editDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit day'**
  String get editDayTitle;

  /// No description provided for @editDayIntro.
  ///
  /// In en, this message translates to:
  /// **'Update the shared day context for {date}.'**
  String editDayIntro(String date);

  /// No description provided for @editDaySymptomsDescription.
  ///
  /// In en, this message translates to:
  /// **'These symptoms are shared across all readings saved on {date}.'**
  String editDaySymptomsDescription(String date);

  /// No description provided for @editDayNotesDescription.
  ///
  /// In en, this message translates to:
  /// **'This note is also shared across every reading for this date.'**
  String get editDayNotesDescription;

  /// No description provided for @editReadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit reading'**
  String get editReadingTitle;

  /// No description provided for @editReadingIntro.
  ///
  /// In en, this message translates to:
  /// **'Update the reading details for {date}.'**
  String editReadingIntro(String date);

  /// No description provided for @editReadingWhenDescription.
  ///
  /// In en, this message translates to:
  /// **'This reading belongs to {date}. You can adjust the time here.'**
  String editReadingWhenDescription(String date);

  /// No description provided for @peakFlowValueTitle.
  ///
  /// In en, this message translates to:
  /// **'Peak Flow Value'**
  String get peakFlowValueTitle;

  /// No description provided for @editReadingValueDescription.
  ///
  /// In en, this message translates to:
  /// **'Drag the center line to update the reading or type the value directly.'**
  String get editReadingValueDescription;

  /// No description provided for @deleteDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete day?'**
  String get deleteDayTitle;

  /// No description provided for @deleteDayMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the day and all readings saved for it.'**
  String get deleteDayMessage;

  /// No description provided for @deleteDayConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete day'**
  String get deleteDayConfirm;

  /// No description provided for @deleteReadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete reading?'**
  String get deleteReadingTitle;

  /// No description provided for @deleteReadingMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this reading.'**
  String get deleteReadingMessage;

  /// No description provided for @deleteReadingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete reading'**
  String get deleteReadingConfirm;

  /// No description provided for @symptomsTitle.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get symptomsTitle;

  /// No description provided for @readingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Readings'**
  String get readingsTitle;

  /// No description provided for @notesPrefix.
  ///
  /// In en, this message translates to:
  /// **'Notes: '**
  String get notesPrefix;

  /// No description provided for @addReadingButton.
  ///
  /// In en, this message translates to:
  /// **'Add reading'**
  String get addReadingButton;

  /// No description provided for @noValues.
  ///
  /// In en, this message translates to:
  /// **'No values'**
  String get noValues;

  /// No description provided for @timelineTab.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timelineTab;

  /// No description provided for @graphTab.
  ///
  /// In en, this message translates to:
  /// **'Graph'**
  String get graphTab;

  /// No description provided for @gapOneDay.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get gapOneDay;

  /// No description provided for @gapDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String gapDays(int count);

  /// No description provided for @gapBetween.
  ///
  /// In en, this message translates to:
  /// **'between'**
  String get gapBetween;

  /// No description provided for @gapMissing.
  ///
  /// In en, this message translates to:
  /// **'missing'**
  String get gapMissing;

  /// No description provided for @symptomCough.
  ///
  /// In en, this message translates to:
  /// **'Cough'**
  String get symptomCough;

  /// No description provided for @symptomCoughNight.
  ///
  /// In en, this message translates to:
  /// **'Cough night'**
  String get symptomCoughNight;

  /// No description provided for @symptomWheezingBreathing.
  ///
  /// In en, this message translates to:
  /// **'Wheezing breathing'**
  String get symptomWheezingBreathing;

  /// No description provided for @symptomShortnessOfBreath.
  ///
  /// In en, this message translates to:
  /// **'Shortness of breath'**
  String get symptomShortnessOfBreath;

  /// No description provided for @symptomDifficultBreathing.
  ///
  /// In en, this message translates to:
  /// **'Difficult breathing'**
  String get symptomDifficultBreathing;

  /// No description provided for @symptomChestTightnessOrPain.
  ///
  /// In en, this message translates to:
  /// **'Chest tightness or pain'**
  String get symptomChestTightnessOrPain;

  /// No description provided for @symptomUnableToWork.
  ///
  /// In en, this message translates to:
  /// **'Unable to work'**
  String get symptomUnableToWork;

  /// No description provided for @dataScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dataScreenTitle;

  /// No description provided for @dateRangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRangeTitle;

  /// No description provided for @rangeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get rangeAll;

  /// No description provided for @rangeLast3Months.
  ///
  /// In en, this message translates to:
  /// **'Last 3 Months'**
  String get rangeLast3Months;

  /// No description provided for @rangeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get rangeCustom;

  /// No description provided for @statAverage.
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get statAverage;

  /// No description provided for @statHighest.
  ///
  /// In en, this message translates to:
  /// **'Highest'**
  String get statHighest;

  /// No description provided for @statLowest.
  ///
  /// In en, this message translates to:
  /// **'Lowest'**
  String get statLowest;

  /// No description provided for @statMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get statMeasurements;

  /// No description provided for @timesUnit.
  ///
  /// In en, this message translates to:
  /// **'times'**
  String get timesUnit;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @exportReportFor.
  ///
  /// In en, this message translates to:
  /// **'Export Report for {range}'**
  String exportReportFor(String range);

  /// No description provided for @generatingPdf.
  ///
  /// In en, this message translates to:
  /// **'Generating PDF'**
  String get generatingPdf;

  /// No description provided for @pdfReport.
  ///
  /// In en, this message translates to:
  /// **'PDF Report'**
  String get pdfReport;

  /// No description provided for @generatingCsv.
  ///
  /// In en, this message translates to:
  /// **'Generating CSV'**
  String get generatingCsv;

  /// No description provided for @csvReport.
  ///
  /// In en, this message translates to:
  /// **'CSV Report'**
  String get csvReport;

  /// No description provided for @savePdfReportDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save PDF Report'**
  String get savePdfReportDialogTitle;

  /// No description provided for @pdfReportDownloadStarted.
  ///
  /// In en, this message translates to:
  /// **'PDF report download started.'**
  String get pdfReportDownloadStarted;

  /// No description provided for @pdfReportSaved.
  ///
  /// In en, this message translates to:
  /// **'PDF report saved.'**
  String get pdfReportSaved;

  /// No description provided for @pdfReportGenerateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not generate the PDF report.'**
  String get pdfReportGenerateFailed;

  /// No description provided for @saveCsvReportDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save CSV Report'**
  String get saveCsvReportDialogTitle;

  /// No description provided for @csvReportDownloadStarted.
  ///
  /// In en, this message translates to:
  /// **'CSV report download started.'**
  String get csvReportDownloadStarted;

  /// No description provided for @csvReportSaved.
  ///
  /// In en, this message translates to:
  /// **'CSV report saved.'**
  String get csvReportSaved;

  /// No description provided for @csvReportGenerateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not generate the CSV report.'**
  String get csvReportGenerateFailed;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available yet.'**
  String get noDataAvailable;

  /// No description provided for @customRangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Range'**
  String get customRangeTitle;

  /// No description provided for @customRangeDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose start and end dates for the chart.'**
  String get customRangeDescription;

  /// No description provided for @startLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startLabel;

  /// No description provided for @endLabel.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get endLabel;

  /// No description provided for @zoneStable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get zoneStable;

  /// No description provided for @zoneCaution.
  ///
  /// In en, this message translates to:
  /// **'Caution'**
  String get zoneCaution;

  /// No description provided for @zoneActionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Action Needed'**
  String get zoneActionNeeded;

  /// No description provided for @reportPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {pages}'**
  String reportPageOf(int page, int pages);

  /// No description provided for @peakFlowReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Peak Flow Report'**
  String get peakFlowReportTitle;

  /// No description provided for @reportRange.
  ///
  /// In en, this message translates to:
  /// **'Range: {range}'**
  String reportRange(String range);

  /// No description provided for @reportGenerated.
  ///
  /// In en, this message translates to:
  /// **'Generated: {date}'**
  String reportGenerated(String date);

  /// No description provided for @reportStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get reportStats;

  /// No description provided for @reportAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get reportAverage;

  /// No description provided for @reportReadingsByZone.
  ///
  /// In en, this message translates to:
  /// **'Readings By Zone'**
  String get reportReadingsByZone;

  /// No description provided for @reportReferenceMax.
  ///
  /// In en, this message translates to:
  /// **'Reference Max'**
  String get reportReferenceMax;

  /// No description provided for @reportActionNeededDates.
  ///
  /// In en, this message translates to:
  /// **'Action Needed Dates'**
  String get reportActionNeededDates;

  /// No description provided for @reportNoActionNeeded.
  ///
  /// In en, this message translates to:
  /// **'No readings were in the action needed zone.'**
  String get reportNoActionNeeded;

  /// No description provided for @reportNoSavedReadingsRange.
  ///
  /// In en, this message translates to:
  /// **'No saved readings in this date range.'**
  String get reportNoSavedReadingsRange;

  /// No description provided for @reportNoSavedReadingsMonth.
  ///
  /// In en, this message translates to:
  /// **'No readings saved this month.'**
  String get reportNoSavedReadingsMonth;

  /// No description provided for @reportNoGraphReadingsMonth.
  ///
  /// In en, this message translates to:
  /// **'No readings to graph for this month.'**
  String get reportNoGraphReadingsMonth;

  /// No description provided for @reportXAxisDescription.
  ///
  /// In en, this message translates to:
  /// **'X axis: day of month. Background bands match the app zones.'**
  String get reportXAxisDescription;

  /// No description provided for @reportDayNote.
  ///
  /// In en, this message translates to:
  /// **'Day note: {note}'**
  String reportDayNote(String note);

  /// No description provided for @reportSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Symptoms: {symptoms}'**
  String reportSymptoms(String symptoms);

  /// No description provided for @reportNoReadingsDay.
  ///
  /// In en, this message translates to:
  /// **'No readings saved for this day.'**
  String get reportNoReadingsDay;

  /// No description provided for @reportTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get reportTime;

  /// No description provided for @reportValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get reportValue;

  /// No description provided for @reportZone.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get reportZone;

  /// No description provided for @reportReadingNote.
  ///
  /// In en, this message translates to:
  /// **'Reading note'**
  String get reportReadingNote;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
