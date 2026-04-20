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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 24.0),
                child: Text(
                  'Theme',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              SwitchListTile(
                value: isDarkMode,
                onChanged: (value) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool("isDarkMode", value);
                  ref.read(themeStateNotifier).setIsDarkMode(value);
                  setState(() {
                    isDarkMode = value;
                  });
                },
                title: const Text("Dark mode"),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 24.0),
                child: Text(
                  'Device max capacity',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
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
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          final value = int.tryParse(maxController.text);
                          if (value == null) {
                            return;
                          }
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setInt("maxVolume", value);
                          if (!context.mounted) {
                            return;
                          }
                          FocusScope.of(context).unfocus();
                        },
                        child: const Text(
                          "SAVE",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 24.0),
                child: Text(
                  'Reminder Notification',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: "title",
                    hintText: "Test your Peakflow",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: bodyController,
                  decoration: const InputDecoration(
                    labelText: "body",
                    hintText: "Take your peakflow record now!",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        displayTimePicker(context);
                      },
                      child: Text(
                        "Time: ${notificationHour.toString().padLeft(2, '0')}:${notificationMinute.toString().padLeft(2, '0')}",
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
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
                      child: Text(
                        hasNotifications ? 'UPDATE' : 'SAVE',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              SwitchListTile(
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
                title: const Text("Reminder Notification"),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 24.0),
                child: Text(
                  'Export Data',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: exportCSV,
                  child: const Text(
                    "EXPORT CSV",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 44.0),
                child: Text(
                  'Github',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              IconButton(
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
              const SizedBox(height: 10),
              const Text('Made with ❤️ by @joscha0'),
            ],
          ),
        ),
      ),
    );
  }
}
