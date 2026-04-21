import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:peakflow/global/consts.dart';
import 'package:peakflow/providers/theme_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final maxController = TextEditingController();
  final titleController = TextEditingController();
  final bodyController = TextEditingController();

  bool isDarkMode = true;
  bool hasNotifications = false;
  int notificationHour = 0;
  int notificationMinute = 0;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  @override
  void dispose() {
    maxController.dispose();
    titleController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = await checkHasNotifications();
    if (!mounted) {
      return;
    }

    setState(() {
      maxController.text = (prefs.getInt("maxVolume") ?? 850).toString();
      isDarkMode = prefs.getBool("isDarkMode") ?? true;
      titleController.text =
          prefs.getString("notificationTitle") ?? "Test your Peakflow";
      bodyController.text =
          prefs.getString("notificationBody") ??
          "Take your peakflow record now!";
      notificationHour = prefs.getInt('notificationHour') ?? 0;
      notificationMinute = prefs.getInt('notificationMinute') ?? 0;
      hasNotifications = notificationsEnabled;
    });
  }

  List<List<String>> jsonToCsvList(Map<String, dynamic> json) {
    final listItems = <List<String>>[];
    final date = DateTime.parse(
      json['date'] as String,
    ).toIso8601String().split('T').first;

    final checkboxes = <String>[];
    final checkboxValues = Map<String, bool>.from(
      json['checkboxValues'] ?? Map<String, bool>.from(defaultCheckboxValues),
    );
    for (final checkbox in checkboxValues.keys) {
      if (checkboxValues[checkbox] ?? false) {
        checkboxes.add(checkbox);
      }
    }

    for (final reading in List<Map<String, dynamic>>.from(
      json['readings'] as List,
    )) {
      listItems.add([
        date,
        reading['time'] as String,
        reading['value'].toString(),
        reading['note'] as String? ?? '',
        json['note'] as String? ?? '',
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
    final prefs = await SharedPreferences.getInstance();
    final dateList = prefs.getStringList("dates") ?? <String>[];
    dateList.sort();

    for (final date in dateList) {
      final rawValue = prefs.getString(date);
      if (rawValue == null) {
        continue;
      }
      final values = json.decode(rawValue) as Map<String, dynamic>;
      listItems.addAll(jsonToCsvList(values));
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

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final timeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZone.identifier));
  }

  tz.TZDateTime _convertTime(int hour, int minutes) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduleDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minutes,
    );

    if (scheduleDate.isBefore(now)) {
      scheduleDate = scheduleDate.add(const Duration(days: 1));
    }
    return scheduleDate;
  }

  Future<FlutterLocalNotificationsPlugin> initializeNotifications() async {
    await _configureLocalTimeZone();
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    return flutterLocalNotificationsPlugin;
  }

  Future<void> setNotification() async {
    final flutterLocalNotificationsPlugin = await initializeNotifications();
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'peakflow_daily',
        'Peakflow daily reminder',
        channelDescription: 'Peakflow daily reminder to take record',
      ),
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      titleController.text,
      bodyController.text,
      _convertTime(notificationHour, notificationMinute),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<bool> checkHasNotifications() async {
    final flutterLocalNotificationsPlugin = await initializeNotifications();
    final pendingNotificationRequests = await flutterLocalNotificationsPlugin
        .pendingNotificationRequests();
    return pendingNotificationRequests.isNotEmpty;
  }

  Future<void> cancelNotifications() async {
    final flutterLocalNotificationsPlugin = await initializeNotifications();
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> displayTimePicker(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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
                      'Use the darker theme for lower glare and stronger contrast.',
                  trailing: Switch.adaptive(
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
              ]),
              _buildSectionDivider(context),
              _buildSectionLabel(
                context,
                'Peak Flow Setup',
                'Keep your personal max value close at hand for daily tracking.',
              ),
              _buildSectionContent([
                _buildInfoRow(
                  context,
                  icon: Icons.speed_outlined,
                  title: 'Device max capacity',
                  description:
                      'Set the maximum value in liters per minute used throughout the app.',
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final stackVertically = constraints.maxWidth < 390;

                      if (stackVertically) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: maxController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "max L/min",
                                hintText: "850",
                                border: OutlineInputBorder(),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter(
                                  RegExp(r'[0-9]'),
                                  allow: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final value = int.tryParse(maxController.text);
                                if (value == null) {
                                  return;
                                }
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setInt("maxVolume", value);
                                if (!context.mounted) {
                                  return;
                                }
                                FocusScope.of(context).unfocus();
                              },
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
                              controller: maxController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "max L/min",
                                hintText: "850",
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
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final value = int.tryParse(maxController.text);
                                if (value == null) {
                                  return;
                                }
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setInt("maxVolume", value);
                                if (!context.mounted) {
                                  return;
                                }
                                FocusScope.of(context).unfocus();
                              },
                              icon: const Icon(Icons.save_outlined),
                              label: const Text("SAVE"),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
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
                  trailing: Switch.adaptive(
                    value: hasNotifications,
                    onChanged: (value) async {
                      if (hasNotifications) {
                        await cancelNotifications();
                      } else {
                        await setNotification();
                      }
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        hasNotifications = value;
                      });
                    },
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
                            onPressed: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setInt(
                                "notificationHour",
                                notificationHour,
                              );
                              await prefs.setInt(
                                "notificationMinute",
                                notificationMinute,
                              );
                              await prefs.setString(
                                'notificationTitle',
                                titleController.text,
                              );
                              await prefs.setString(
                                'notificationBody',
                                bodyController.text,
                              );

                              if (hasNotifications) {
                                await setNotification();
                              }
                            },
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
