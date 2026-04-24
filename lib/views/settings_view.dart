import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:peakflow/debug/mock_data.dart';
import 'package:peakflow/global/consts.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/providers/day_entries_provider.dart';
import 'package:peakflow/providers/theme_provider.dart';
import 'package:peakflow/services/notification_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

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
  bool isNotificationOperationInProgress = false;
  bool isDebugDataOperationInProgress = false;
  bool useAutomaticMaxValue = true;
  int notificationHour = 0;
  int notificationMinute = 0;
  int recordedBestValue = 0;
  Color selectedPrimaryColor = defaultAccent;

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
      useAutomaticMaxValue = prefs.getBool(useAutomaticMaxValueKey) ?? true;
      recordedBestValue = prefs.getInt(bestValueKey) ?? 0;
      titleController.text =
          prefs.getString("notificationTitle") ??
          _notificationService.defaultTitle;
      bodyController.text =
          prefs.getString("notificationBody") ??
          _notificationService.defaultBody;
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

  List<List<String>> dayEntryToCsvList(DayEntry entry) {
    final listItems = <List<String>>[];
    final date = entry.date.toIso8601String().split('T').first;

    final checkboxes = <String>[];
    for (final checkbox in entry.checkboxValues.keys) {
      if (entry.checkboxValues[checkbox] ?? false) {
        checkboxes.add(checkbox);
      }
    }

    for (final reading in entry.readings) {
      listItems.add([
        date,
        "${reading.time.hour}:${reading.time.minute}",
        reading.value.toString(),
        reading.note,
        entry.note,
        checkboxes.join(', '),
      ]);
    }

    return listItems;
  }

  Future<void> exportCSV() async {
    final box = context.findRenderObject() as RenderBox?;
    final listItems = <List<String>>[
      ['date', 'time', 'reading', 'noteReading', 'noteDay', 'symptoms'],
    ];
    final entries = await getDayEntries();

    for (final entry in entries) {
      listItems.addAll(dayEntryToCsvList(entry));
    }

    final csv = const ListToCsvConverter().convert(listItems);

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(utf8.encode(csv)),
            mimeType: 'text/csv',
          ),
        ],
        fileNameOverrides: const ['peakflow-export.csv'],
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      ),
    );
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
        'Daily reminders are currently supported on Android, iPhone, and macOS.',
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
        _showNotificationMessage(
          'Notification permission is required to enable daily reminders.',
        );
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
          ? 'Reminder updated.'
          : 'Could not update reminder because notification permission is not available.',
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
        'Enter a mock data count between $minMockEntryCount and $maxMockEntryCount.',
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      isDebugDataOperationInProgress = true;
    });

    try {
      await debugLoadMockData(count: count);
      await ref.read(entryListProvider.notifier).loadEntries();
      await loadSettings();
      _showNotificationMessage('Loaded $count mock days.');
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

    try {
      await debugClearAllData();
      await ref.read(entryListProvider.notifier).loadEntries();
      await loadSettings();
      _showNotificationMessage('All local data cleared.');
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
                  label: const Text("SAVE"),
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
                  label: const Text("SAVE"),
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
    final mutedTextColor = theme.colorScheme.onSurface.withValues(alpha: 0.72);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings"), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customize reminders, tracking preferences, and data tools.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: mutedTextColor,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionLabel(
                context,
                'Appearance',
                'Control how Peak Flow looks while you record daily readings.',
              ),
              _buildSectionContent([
                _buildInfoRow(
                  context,
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark mode',
                  description:
                      'Dark mode ${isDarkMode ? 'is enabled' : 'is disabled'}.',
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
                  title: 'Primary color',
                  description:
                      'Pick the accent color used for buttons, highlights, and controls.',
                ),
                _buildPrimaryColorPicker(context),
              ]),
              _buildSectionDivider(context),
              _buildSectionLabel(
                context,
                'Peak Flow Setup',
                'Set the device limit separately from the max used to calculate your color zones.',
              ),
              _buildSectionContent([
                _buildInfoRow(
                  context,
                  icon: Icons.speed_outlined,
                  title: 'Device max capacity',
                  description:
                      'This is the maximum value your device can measure and the upper limit used for input and graphs.',
                ),
                _buildValueEditor(
                  context,
                  controller: deviceMaxController,
                  labelText: 'device max L/min',
                  onSave: _saveDeviceMaxValue,
                ),
                _buildInfoRow(
                  context,
                  icon: Icons.monitor_heart_outlined,
                  title: useAutomaticMaxValue ? 'Automatic max' : 'Manual max',
                  description:
                      'Auto uses your highest saved reading for the green, orange, and red zones. Turn it off to enter your own max.',
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
                              ? 'Current automatic max: $automaticReferenceMaxValue L/min'
                              : 'Automatic mode will use your best saved reading once you have one. Until then it falls back to $automaticReferenceMaxValue L/min.'
                        : 'Manual mode uses the value below as the color reference.',
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
                    labelText: 'manual color max L/min',
                    onSave: _saveManualColorMaxValue,
                  ),
              ]),
              _buildSectionDivider(context),
              _buildSectionLabel(
                context,
                'Reminder Notification',
                'Manage the daily reminder message and the time it appears.',
              ),
              _buildSectionContent([
                _buildInfoRow(
                  context,
                  icon: Icons.notifications_active_outlined,
                  title: 'Daily reminder',
                  description:
                      'Turn scheduled reminders on or off without leaving this screen.',
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
                        decoration: const InputDecoration(
                          labelText: "title",
                          hintText: "Test your Peakflow",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: bodyController,
                        decoration: const InputDecoration(
                          labelText: "body",
                          hintText: "Take your peakflow record now!",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Reminder time',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scheduled for ${notificationHour.toString().padLeft(2, '0')}:${notificationMinute.toString().padLeft(2, '0')} each day.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: mutedTextColor,
                        ),
                      ),
                      if (!notificationsSupported) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Daily scheduled reminders are available on Android, iPhone, and macOS.',
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
                            label: Text(hasNotifications ? 'UPDATE' : 'SAVE'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ]),
              _buildSectionDivider(context),
              _buildSectionLabel(
                context,
                'Data',
                'Create a portable backup of your readings and notes.',
              ),
              _buildSectionContent([
                _buildInfoRow(
                  context,
                  icon: Icons.file_download_outlined,
                  title: 'Export as CSV',
                  description:
                      'Share a spreadsheet-friendly export of your peak flow history.',
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: exportCSV,
                      icon: const Icon(Icons.ios_share_outlined),
                      label: const Text("EXPORT CSV"),
                    ),
                  ),
                ),
              ]),
              if (kDebugMode) ...[
                _buildSectionDivider(context),
                _buildSectionLabel(
                  context,
                  'Debug',
                  'Load sample readings for development or clear the local database again.',
                ),
                _buildSectionContent([
                  _buildInfoRow(
                    context,
                    icon: Icons.developer_mode_outlined,
                    title: 'Mock data tools',
                    description:
                        'These actions are only visible in debug builds and replace your current local dataset.',
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextFormField(
                      controller: debugMockCountController,
                      enabled: !isDebugDataOperationInProgress,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'mock days to generate',
                        hintText: '120',
                        border: OutlineInputBorder(),
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
                      'Allowed range: $minMockEntryCount to $maxMockEntryCount days.',
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
                          label: const Text('LOAD MOCK DATA'),
                        ),
                        OutlinedButton.icon(
                          onPressed: isDebugDataOperationInProgress
                              ? null
                              : _clearDebugData,
                          icon: const Icon(Icons.delete_sweep_outlined),
                          label: const Text('CLEAR ALL DATA'),
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
                  'Made with ❤️ by @joscha0',
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
