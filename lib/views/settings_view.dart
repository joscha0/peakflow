import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:peakflow/debug/mock_data.dart';
import 'package:peakflow/global/consts.dart';
import 'package:peakflow/l10n/l10n.dart';
import 'package:peakflow/providers/day_entries_provider.dart';
import 'package:peakflow/providers/locale_provider.dart';
import 'package:peakflow/providers/locale_state.dart';
import 'package:peakflow/providers/theme_provider.dart';
import 'package:peakflow/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

enum _JsonImportAction { merge, replace }

class _SettingsViewState extends ConsumerState<SettingsView> {
  final deviceMaxController = TextEditingController();
  final colorMaxController = TextEditingController();
  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  final debugMockCountController = TextEditingController(
    text: defaultMockEntryCount.toString(),
  );
  final NotificationService _notificationService = NotificationService();

  bool isDarkMode = true;
  bool hasNotifications = false;
  bool notificationsSupported = true;
  bool isDataTransferInProgress = false;
  bool isNotificationOperationInProgress = false;
  bool isDebugDataOperationInProgress = false;
  bool useAutomaticMaxValue = true;
  int notificationHour = 0;
  int notificationMinute = 0;
  int recordedBestValue = 0;
  Color selectedPrimaryColor = defaultAccent;
  AppLocaleChoice localeChoice = AppLocaleChoice.english;

  @override
  void initState() {
    super.initState();
    final themeState = ref.read(themeStateNotifier);
    isDarkMode = themeState.isDarkMode;
    selectedPrimaryColor = themeState.primaryColor;
    loadSettings();
  }

  @override
  void dispose() {
    deviceMaxController.dispose();
    colorMaxController.dispose();
    titleController.dispose();
    bodyController.dispose();
    debugMockCountController.dispose();
    super.dispose();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = await checkHasNotifications();
    if (!mounted) {
      return;
    }

    setState(() {
      deviceMaxController.text =
          (prefs.getInt(maxVolumeKey) ?? defaultMaxVolume).toString();
      colorMaxController.text =
          (prefs.getInt(manualColorReferenceMaxValueKey) ??
                  prefs.getInt(maxVolumeKey) ??
                  defaultMaxVolume)
              .toString();
      isDarkMode =
          prefs.getBool("isDarkMode") ??
          ref.read(themeStateNotifier).isDarkMode;
      selectedPrimaryColor = _resolvePrimaryColor(
        prefs.getInt(primaryColorPreferenceKey) ?? defaultAccent.toARGB32(),
      );
      localeChoice = AppLocaleChoice.fromPreferenceValue(
        prefs.getString(localePreferenceKey) ??
            ref.read(localeStateNotifier).choice.preferenceValue,
      );
      useAutomaticMaxValue = prefs.getBool(useAutomaticMaxValueKey) ?? true;
      recordedBestValue = prefs.getInt(bestValueKey) ?? 0;
      titleController.text =
          prefs.getString("notificationTitle") ??
          context.l10n.notificationDefaultTitle;
      bodyController.text =
          prefs.getString("notificationBody") ??
          context.l10n.notificationDefaultBody;
      notificationHour = prefs.getInt('notificationHour') ?? 0;
      notificationMinute = prefs.getInt('notificationMinute') ?? 0;
      hasNotifications = notificationsEnabled;
      notificationsSupported =
          _notificationService.supportsScheduledNotifications;
    });
  }

  Color _resolvePrimaryColor(int colorValue) {
    for (final color in primaryColorOptions) {
      if (color.toARGB32() == colorValue) {
        return color;
      }
    }
    return defaultAccent;
  }

  int get automaticReferenceMaxValue {
    final deviceMaxValue =
        int.tryParse(deviceMaxController.text.trim()) ?? defaultMaxVolume;
    return recordedBestValue > 0 ? recordedBestValue : deviceMaxValue;
  }

  Future<void> _saveDeviceMaxValue() async {
    final value = int.tryParse(deviceMaxController.text.trim());
    if (value == null || value <= 0) {
      return;
    }

    await setDeviceMaxValue(value);
    if (!mounted) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      deviceMaxController.text = value.toString();
    });
  }

  Future<void> _saveManualColorMaxValue() async {
    final value = int.tryParse(colorMaxController.text.trim());
    if (value == null || value <= 0) {
      return;
    }

    await setManualColorReferenceMaxValue(value);
    if (!mounted) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      colorMaxController.text = value.toString();
    });
  }

  Future<void> _saveExportFile({
    required String dialogTitle,
    required String fileName,
    required String extension,
    required Uint8List bytes,
    required String successMessage,
  }) async {
    final webSuccessMessage = context.l10n.exportDownloadStarted;
    final outputPath = await FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: [extension],
      bytes: bytes,
    );

    if (!mounted) {
      return;
    }

    if (outputPath != null || kIsWeb) {
      _showNotificationMessage(kIsWeb ? webSuccessMessage : successMessage);
    }
  }

  Future<void> _exportJSON() async {
    if (isDataTransferInProgress) {
      return;
    }

    setState(() {
      isDataTransferInProgress = true;
    });

    final dialogTitle = context.l10n.exportJsonBackupDialogTitle;
    final successMessage = context.l10n.jsonBackupSaved;
    try {
      final json = await exportDayEntriesJson();
      await _saveExportFile(
        dialogTitle: dialogTitle,
        fileName: 'peakflow-backup.json',
        extension: 'json',
        bytes: Uint8List.fromList(utf8.encode(json)),
        successMessage: successMessage,
      );
    } finally {
      if (mounted) {
        setState(() {
          isDataTransferInProgress = false;
        });
      }
    }
  }

  Future<void> _importJSON() async {
    if (isDataTransferInProgress) {
      return;
    }

    final l10n = context.l10n;
    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) {
      return;
    }

    final selectedFile = result.files.single;
    final jsonData = selectedFile.bytes == null
        ? await selectedFile.xFile.readAsString()
        : utf8.decode(selectedFile.bytes!);
    if (jsonData.trim().isEmpty || !mounted) {
      _showNotificationMessage(l10n.jsonFileEmpty);
      return;
    }

    final JsonBackupImportPreview preview;
    try {
      preview = await previewDayEntriesJsonImport(jsonData);
    } on FormatException {
      _showNotificationMessage(l10n.jsonFileInvalid);
      return;
    } catch (_) {
      _showNotificationMessage(l10n.jsonFileReadFailed);
      return;
    }

    if (!mounted) {
      return;
    }

    final action = await _showJsonImportPreviewDialog(selectedFile, preview);
    if (action == null || !mounted) {
      return;
    }

    final confirmed = await _showJsonImportConfirmationDialog(action, preview);
    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      isDataTransferInProgress = true;
    });

    try {
      final message = action == _JsonImportAction.merge
          ? await _mergeJsonBackup(jsonData, l10n)
          : await _replaceJsonBackup(jsonData, l10n);
      await ref.read(entryListProvider.notifier).loadEntries();
      ref.invalidate(colorReferenceMaxValueProvider);
      await loadSettings();
      _showNotificationMessage(message);
    } on FormatException {
      _showNotificationMessage(l10n.jsonFileInvalid);
    } catch (_) {
      _showNotificationMessage(l10n.jsonFileImportFailed);
    } finally {
      if (mounted) {
        setState(() {
          isDataTransferInProgress = false;
        });
      }
    }
  }

  Future<String> _mergeJsonBackup(
    String jsonData,
    AppLocalizations l10n,
  ) async {
    final result = await mergeDayEntriesJson(jsonData);
    if (result.daysChangedByMerge == 0 && result.newReadings == 0) {
      return l10n.backupMergedNoNewData;
    }

    return l10n.backupMerged(result.daysChangedByMerge, result.newReadings);
  }

  Future<String> _replaceJsonBackup(
    String jsonData,
    AppLocalizations l10n,
  ) async {
    final importedCount = await importDayEntriesJson(jsonData);
    return importedCount == 1
        ? l10n.importedOneDayFromJson
        : l10n.importedDaysFromJson(importedCount);
  }

  Future<_JsonImportAction?> _showJsonImportPreviewDialog(
    PlatformFile file,
    JsonBackupImportPreview preview,
  ) {
    final l10n = context.l10n;
    return showDialog<_JsonImportAction>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.importJsonBackupTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImportSummaryRow(l10n.fileLabel, file.name),
                _buildImportSummaryRow(
                  l10n.sizeLabel,
                  _formatFileSize(file.size),
                ),
                const SizedBox(height: 12),
                _buildImportSummaryRow(
                  l10n.currentDataLabel,
                  _formatDaysAndReadings(
                    preview.currentDays,
                    preview.currentReadings,
                  ),
                ),
                _buildImportSummaryRow(
                  l10n.backupDataLabel,
                  _formatDaysAndReadings(
                    preview.backupDays,
                    preview.backupReadings,
                  ),
                ),
                const SizedBox(height: 12),
                _buildImportSummaryRow(
                  l10n.mergeResultLabel,
                  l10n.daysTotal(preview.daysAfterMerge),
                ),
                _buildImportSummaryRow(
                  l10n.newFromBackupLabel,
                  l10n.daysReadings(
                    preview.backupOnlyDays,
                    preview.newReadings,
                  ),
                ),
                _buildImportSummaryRow(
                  l10n.duplicatesSkippedLabel,
                  l10n.readingsCount(preview.duplicateReadings),
                ),
                _buildImportSummaryRow(
                  l10n.daysChangedByMergeLabel,
                  l10n.daysCount(preview.daysChangedByMerge),
                ),
                _buildImportSummaryRow(
                  l10n.symptomsAddedLabel,
                  '${preview.newSymptomValues}',
                ),
                _buildImportSummaryRow(
                  l10n.dayNotesFilledLabel,
                  '${preview.newDayNotes}',
                ),
                if (preview.dayNoteConflicts > 0)
                  _buildImportSummaryRow(
                    l10n.noteConflictsLabel,
                    l10n.localNotesKept(preview.dayNoteConflicts),
                  ),
                const SizedBox(height: 12),
                _buildImportSummaryRow(
                  l10n.replaceWouldRemoveLabel,
                  l10n.localOnlyDays(preview.currentOnlyDays),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancelUpper),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_JsonImportAction.replace),
              child: Text(l10n.importAndReplaceUpper),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(_JsonImportAction.merge),
              child: Text(l10n.importAndMergeUpper),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showJsonImportConfirmationDialog(
    _JsonImportAction action,
    JsonBackupImportPreview preview,
  ) async {
    final isMerge = action == _JsonImportAction.merge;
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            isMerge
                ? l10n.mergeConfirmationTitle
                : l10n.replaceConfirmationTitle,
          ),
          content: Text(
            isMerge
                ? l10n.mergeConfirmationMessage(
                    preview.newReadings,
                    preview.duplicateReadings,
                    preview.dayNoteConflicts,
                  )
                : l10n.replaceConfirmationMessage(
                    _formatDaysAndReadings(
                      preview.currentDays,
                      preview.currentReadings,
                    ),
                    _formatDaysAndReadings(
                      preview.backupDays,
                      preview.backupReadings,
                    ),
                    preview.currentOnlyDays,
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancelUpper),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                isMerge ? l10n.mergeAndImportUpper : l10n.importAndReplaceUpper,
              ),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  Widget _buildImportSummaryRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  String _formatDaysAndReadings(int days, int readings) {
    return context.l10n.formatDaysAndReadings(days, readings);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    final kilobytes = bytes / 1024;
    if (kilobytes < 1024) {
      return '${kilobytes.toStringAsFixed(1)} KB';
    }

    final megabytes = kilobytes / 1024;
    return '${megabytes.toStringAsFixed(1)} MB';
  }

  bool get _supportsScheduledNotifications =>
      _notificationService.supportsScheduledNotifications;

  Future<void> _persistNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("notificationHour", notificationHour);
    await prefs.setInt("notificationMinute", notificationMinute);
    await prefs.setString('notificationTitle', titleController.text);
    await prefs.setString('notificationBody', bodyController.text);
  }

  void _showNotificationMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> setNotification() async {
    return _notificationService.scheduleDailyReminder(
      title: titleController.text,
      body: bodyController.text,
      hour: notificationHour,
      minute: notificationMinute,
    );
  }

  Future<bool> checkHasNotifications() async {
    return _notificationService.hasScheduledReminder();
  }

  Future<void> cancelNotifications() async {
    await _notificationService.cancelReminder();
  }

  Future<void> _toggleNotifications(bool value) async {
    if (isNotificationOperationInProgress) {
      return;
    }

    if (!_supportsScheduledNotifications) {
      _showNotificationMessage(
        context.l10n.scheduledRemindersSupportedSnackbar,
      );
      return;
    }

    setState(() {
      isNotificationOperationInProgress = true;
    });

    try {
      await _persistNotificationPreferences();

      final bool enabled;
      if (value) {
        enabled = await setNotification();
      } else {
        await cancelNotifications();
        enabled = false;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        hasNotifications = value ? enabled : false;
      });

      if (value && !enabled) {
        _showNotificationMessage(context.l10n.notificationPermissionRequired);
      }
    } finally {
      if (mounted) {
        setState(() {
          isNotificationOperationInProgress = false;
        });
      }
    }
  }

  Future<void> _saveNotificationSettings() async {
    await _persistNotificationPreferences();

    if (!hasNotifications) {
      return;
    }

    final scheduled = await setNotification();
    if (!mounted) {
      return;
    }

    setState(() {
      hasNotifications = scheduled;
    });

    _showNotificationMessage(
      scheduled
          ? context.l10n.reminderUpdated
          : context.l10n.reminderUpdateFailed,
    );
  }

  Future<void> _loadMockData() async {
    if (!kDebugMode || isDebugDataOperationInProgress) {
      return;
    }

    final count = int.tryParse(debugMockCountController.text.trim());
    if (count == null ||
        count < minMockEntryCount ||
        count > maxMockEntryCount) {
      _showNotificationMessage(
        context.l10n.mockDataCountError(minMockEntryCount, maxMockEntryCount),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      isDebugDataOperationInProgress = true;
    });

    final successMessage = context.l10n.loadedMockDays(count);
    try {
      await debugLoadMockData(count: count);
      await ref.read(entryListProvider.notifier).loadEntries();
      await loadSettings();
      _showNotificationMessage(successMessage);
    } finally {
      if (mounted) {
        setState(() {
          isDebugDataOperationInProgress = false;
        });
      }
    }
  }

  Future<void> _clearDebugData() async {
    if (!kDebugMode || isDebugDataOperationInProgress) {
      return;
    }

    setState(() {
      isDebugDataOperationInProgress = true;
    });

    final successMessage = context.l10n.allLocalDataCleared;
    try {
      await debugClearAllData();
      await ref.read(entryListProvider.notifier).loadEntries();
      await loadSettings();
      _showNotificationMessage(successMessage);
    } finally {
      if (mounted) {
        setState(() {
          isDebugDataOperationInProgress = false;
        });
      }
    }
  }

  Future<void> displayTimePicker(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: notificationHour,
        minute: notificationMinute,
      ),
    );

    if (pickedTime != null) {
      setState(() {
        notificationHour = pickedTime.hour;
        notificationMinute = pickedTime.minute;
      });
    }
  }

  Widget _buildSectionLabel(
    BuildContext context,
    String title,
    String description,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent(List<Widget> children) {
    return Column(children: children);
  }

  Widget _buildSectionDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).dividerColor.withValues(alpha: 0.55),
      ),
    );
  }

  Widget _buildIconBadge(BuildContext context, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: colorScheme.primary),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIconBadge(context, icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing],
        ],
      ),
    );
  }

  Widget _buildMaterial3Switch(
    BuildContext context, {
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final theme = Theme.of(context);

    return Theme(
      data: ThemeData.from(
        colorScheme: theme.colorScheme,
        textTheme: theme.textTheme,
        useMaterial3: true,
      ),
      child: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Theme(
        data: ThemeData.from(
          colorScheme: theme.colorScheme,
          textTheme: theme.textTheme,
          useMaterial3: true,
        ),
        child: SegmentedButton<AppLocaleChoice>(
          segments: [
            ButtonSegment<AppLocaleChoice>(
              value: AppLocaleChoice.english,
              label: Text(l10n.languageEnglish),
            ),
            ButtonSegment<AppLocaleChoice>(
              value: AppLocaleChoice.german,
              label: Text(l10n.languageGerman),
            ),
          ],
          selected: {localeChoice},
          showSelectedIcon: false,
          onSelectionChanged: (selection) async {
            final nextChoice = selection.single;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              localePreferenceKey,
              nextChoice.preferenceValue,
            );
            ref.read(localeStateNotifier).setChoice(nextChoice);
            if (!mounted) {
              return;
            }
            setState(() {
              localeChoice = nextChoice;
            });
          },
        ),
      ),
    );
  }

  Widget _buildValueEditor(
    BuildContext context, {
    required TextEditingController controller,
    required String labelText,
    required VoidCallback onSave,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackVertically = constraints.maxWidth < 390;

          if (stackVertically) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: labelText,
                    hintText: "$defaultMaxVolume",
                    border: OutlineInputBorder(),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter(RegExp(r'[0-9]'), allow: true),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(context.l10n.saveUpper),
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: labelText,
                    hintText: "$defaultMaxVolume",
                    border: OutlineInputBorder(),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter(RegExp(r'[0-9]'), allow: true),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(context.l10n.saveUpper),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPrimaryColorPicker(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          for (final color in primaryColorOptions)
            GestureDetector(
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt(primaryColorPreferenceKey, color.toARGB32());
                ref.read(themeStateNotifier).setPrimaryColor(color);
                if (!mounted) {
                  return;
                }
                setState(() {
                  selectedPrimaryColor = color;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(
                    color: selectedPrimaryColor.toARGB32() == color.toARGB32()
                        ? theme.colorScheme.onSurface
                        : color.withValues(alpha: 0.18),
                    width: selectedPrimaryColor.toARGB32() == color.toARGB32()
                        ? 3
                        : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.26),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: selectedPrimaryColor.toARGB32() == color.toARGB32()
                    ? Icon(
                        Icons.check,
                        size: 18,
                        color: color.computeLuminance() > 0.45
                            ? Colors.black
                            : Colors.white,
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final mutedTextColor = theme.colorScheme.onSurface.withValues(alpha: 0.72);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settingsIntro,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: mutedTextColor,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionLabel(
                context,
                l10n.appearanceTitle,
                l10n.appearanceDescription,
              ),
              _buildSectionContent([
                _buildInfoRow(
                  context,
                  icon: Icons.translate_outlined,
                  title: l10n.languageTitle,
                  description: l10n.languageDescription,
                ),
                _buildLanguageSelector(context),
                _buildInfoRow(
                  context,
                  icon: Icons.dark_mode_outlined,
                  title: l10n.darkModeTitle,
                  description: isDarkMode
                      ? l10n.darkModeEnabledDescription
                      : l10n.darkModeDisabledDescription,
                  trailing: _buildMaterial3Switch(
                    context,
                    value: isDarkMode,
                    onChanged: (value) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool("isDarkMode", value);
                      ref.read(themeStateNotifier).setIsDarkMode(value);
                      setState(() {
                        isDarkMode = value;
                      });
                    },
                  ),
                ),
                _buildInfoRow(
                  context,
                  icon: Icons.palette_outlined,
                  title: l10n.primaryColorTitle,
                  description: l10n.primaryColorDescription,
                ),
                _buildPrimaryColorPicker(context),
              ]),
              _buildSectionDivider(context),
              _buildSectionLabel(
                context,
                l10n.peakFlowSetupTitle,
                l10n.peakFlowSetupDescription,
              ),
              _buildSectionContent([
                _buildInfoRow(
                  context,
                  icon: Icons.speed_outlined,
                  title: l10n.deviceMaxCapacityTitle,
                  description: l10n.deviceMaxCapacityDescription,
                ),
                _buildValueEditor(
                  context,
                  controller: deviceMaxController,
                  labelText: l10n.deviceMaxLabel,
                  onSave: _saveDeviceMaxValue,
                ),
                _buildInfoRow(
                  context,
                  icon: Icons.monitor_heart_outlined,
                  title: useAutomaticMaxValue
                      ? l10n.automaticMaxTitle
                      : l10n.manualMaxTitle,
                  description: l10n.colorMaxDescription,
                  trailing: _buildMaterial3Switch(
                    context,
                    value: useAutomaticMaxValue,
                    onChanged: (value) async {
                      await setUseAutomaticMaxValue(value);
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        useAutomaticMaxValue = value;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    useAutomaticMaxValue
                        ? recordedBestValue > 0
                              ? l10n.currentAutomaticMax(
                                  automaticReferenceMaxValue,
                                )
                              : l10n.automaticMaxFallback(
                                  automaticReferenceMaxValue,
                                )
                        : l10n.manualMaxDescription,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.68,
                      ),
                      height: 1.35,
                    ),
                  ),
                ),
                if (!useAutomaticMaxValue)
                  _buildValueEditor(
                    context,
                    controller: colorMaxController,
                    labelText: l10n.manualColorMaxLabel,
                    onSave: _saveManualColorMaxValue,
                  ),
              ]),
              _buildSectionDivider(context),
              _buildSectionLabel(
                context,
                l10n.reminderNotificationTitle,
                l10n.reminderNotificationDescription,
              ),
              _buildSectionContent([
                _buildInfoRow(
                  context,
                  icon: Icons.notifications_active_outlined,
                  title: l10n.dailyReminderTitle,
                  description: l10n.dailyReminderDescription,
                  trailing: _buildMaterial3Switch(
                    context,
                    value: hasNotifications,
                    onChanged:
                        notificationsSupported &&
                            !isNotificationOperationInProgress
                        ? _toggleNotifications
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: l10n.notificationTitleLabel,
                          hintText: l10n.notificationDefaultTitle,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: bodyController,
                        decoration: InputDecoration(
                          labelText: l10n.notificationBodyLabel,
                          hintText: l10n.notificationDefaultBody,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        l10n.reminderTimeTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.scheduledForEachDay(
                          '${notificationHour.toString().padLeft(2, '0')}:${notificationMinute.toString().padLeft(2, '0')}',
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: mutedTextColor,
                        ),
                      ),
                      if (!notificationsSupported) ...[
                        const SizedBox(height: 6),
                        Text(
                          l10n.scheduledRemindersSupported,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              displayTimePicker(context);
                            },
                            icon: const Icon(Icons.schedule_outlined),
                            label: Text(
                              '${notificationHour.toString().padLeft(2, '0')}:${notificationMinute.toString().padLeft(2, '0')}',
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: notificationsSupported
                                ? _saveNotificationSettings
                                : null,
                            icon: const Icon(Icons.save_outlined),
                            label: Text(
                              hasNotifications
                                  ? l10n.updateUpper
                                  : l10n.saveUpper,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ]),
              _buildSectionDivider(context),
              _buildSectionLabel(context, l10n.dataTitle, l10n.dataDescription),
              _buildSectionContent([
                _buildInfoRow(
                  context,
                  icon: Icons.data_object_outlined,
                  title: l10n.jsonBackupTitle,
                  description: l10n.jsonBackupDescription,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: isDataTransferInProgress
                            ? null
                            : _exportJSON,
                        icon: const Icon(Icons.file_upload_outlined),
                        label: Text(l10n.exportJson),
                      ),
                      OutlinedButton.icon(
                        onPressed: isDataTransferInProgress
                            ? null
                            : _importJSON,
                        icon: const Icon(Icons.file_download_outlined),
                        label: Text(l10n.importJson),
                      ),
                    ],
                  ),
                ),
              ]),
              if (kDebugMode) ...[
                _buildSectionDivider(context),
                _buildSectionLabel(
                  context,
                  l10n.debugTitle,
                  l10n.debugDescription,
                ),
                _buildSectionContent([
                  _buildInfoRow(
                    context,
                    icon: Icons.developer_mode_outlined,
                    title: l10n.mockDataToolsTitle,
                    description: l10n.mockDataToolsDescription,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextFormField(
                      controller: debugMockCountController,
                      enabled: !isDebugDataOperationInProgress,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.mockDaysToGenerateLabel,
                        hintText: '120',
                        border: const OutlineInputBorder(),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter(
                          RegExp(r'[0-9]'),
                          allow: true,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Text(
                      l10n.allowedMockDaysRange(
                        minMockEntryCount,
                        maxMockEntryCount,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: mutedTextColor,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ElevatedButton.icon(
                          onPressed: isDebugDataOperationInProgress
                              ? null
                              : _loadMockData,
                          icon: const Icon(Icons.data_array_outlined),
                          label: Text(l10n.loadMockData),
                        ),
                        OutlinedButton.icon(
                          onPressed: isDebugDataOperationInProgress
                              ? null
                              : _clearDebugData,
                          icon: const Icon(Icons.delete_sweep_outlined),
                          label: Text(l10n.clearAllData),
                        ),
                      ],
                    ),
                  ),
                ]),
              ],
              _buildSectionDivider(context),

              Center(
                child: IconButton(
                  icon: Image.asset(
                    isDarkMode ? 'assets/github.png' : 'assets/github2.png',
                  ),
                  onPressed: () async {
                    await launchUrl(
                      Uri.parse('https://github.com/joscha0/peakflow'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  l10n.madeWith,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: mutedTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
