import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:peakflow/global/consts.dart';
import 'package:peakflow/providers/theme_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class SettingsView extends StatefulHookConsumerWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingsViewState();
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
    loadSettings();
    super.initState();
  }

  void loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    maxController.text = (prefs.getInt("maxVolume") ?? 850).toString();
    isDarkMode = prefs.getBool("isDarkMode") ?? true;
    titleController.text =
        prefs.getString("notificationTitle") ?? "Test your Peakflow";
    bodyController.text =
        prefs.getString("notificationBody") ?? "Take your peakflow record now!";
    notificationHour = prefs.getInt('notificationHour') ?? 0;
    notificationMinute = prefs.getInt('notificationMinute') ?? 0;
    hasNotifications = await checkHasNotifications();
    setState(() {});
  }

  List<List<String>> jsonToCsvList(Map<String, dynamic> json) {
    List<List<String>> listItems = [];
    String date =
        DateTime.parse(json['date']).toIso8601String().split('T').first;

    List<String> checkboxes = [];
    Map checkboxValues = Map<String, bool>.from(json['checkboxValues'] ??
        Map<String, bool>.from(defaultCheckboxValues));
    for (String checkbox in checkboxValues.keys) {
      if (checkboxValues[checkbox]) {
        checkboxes.add(checkbox);
      }
    }

    for (Map reading in json['readings'] as List) {
      listItems.add([
        date,
        reading['time'],
        reading['value'].toString(),
        reading['note'],
        json['note'],
        checkboxes.join(', ')
      ]);
    }
    return listItems;
  }

  void exportCSV() async {
    List<List<String>> listItems = [];
    listItems
        .add(['date', 'time', 'reading', 'noteReading', 'noteDay', 'symptoms']);
    final prefs = await SharedPreferences.getInstance();
    final List<String> dateList = prefs.getStringList("dates") ?? [];
    dateList.sort();
    for (String date in dateList) {
      Map<String, dynamic> values = json.decode(prefs.getString(date) ?? "");
      listItems += jsonToCsvList(values);
    }
    String csv = const ListToCsvConverter().convert(listItems);

    final box = context.findRenderObject() as RenderBox?;
    Share.shareXFiles(
      [
        XFile.fromData(Uint8List.fromList(utf8.encode(csv)),
            mimeType: 'text/csv')
      ],
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String timeZone = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZone));
  }

  tz.TZDateTime _convertTime(int hour, int minutes) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduleDate = tz.TZDateTime(
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
    _configureLocalTimeZone();
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    return flutterLocalNotificationsPlugin;
  }

  Future<void> setNotification() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        await initializeNotifications();
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('peakflow daily', 'Peakflow daily reminder',
            channelDescription: 'Peakflow daily reminder to take record');
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      titleController.text,
      bodyController.text,
      _convertTime(notificationHour, notificationMinute),
      notificationDetails,
      androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<bool> checkHasNotifications() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        await initializeNotifications();
    final List<PendingNotificationRequest> pendingNotificationRequests =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    print(pendingNotificationRequests);
    return pendingNotificationRequests.isNotEmpty;
  }

  Future<void> cancelNotifications() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        await initializeNotifications();
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future displayTimePicker(BuildContext context) async {
    var time =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());

    if (time != null) {
      setState(() {
        notificationHour = time.hour;
        notificationMinute = time.minute;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(children: [
            const Padding(
              padding: EdgeInsets.only(top: 24.0),
              child: Text('Theme',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
              child: Text('Device max capacity',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                        FilteringTextInputFormatter(RegExp(r'[0-9]'),
                            allow: true),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setInt(
                              "maxVolume", int.parse(maxController.text));
                          FocusScope.of(context).unfocus();
                        },
                        child: const Text(
                          "SAVE",
                          style: TextStyle(color: Colors.white),
                        )),
                  )
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 24.0),
              child: Text('Reminder Notification',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                          "Time: ${notificationHour.toString().padLeft(2, '0')}:${notificationMinute.toString().padLeft(2, '0')}")),
                  ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt(
                            "notificationHour", notificationHour);
                        await prefs.setInt(
                            "notificationMinute", notificationMinute);
                        await prefs.setString(
                            'notificationTitle', titleController.text);
                        await prefs.setString(
                            'notificationBody', bodyController.text);

                        if (hasNotifications) {
                          setNotification();
                        }
                      },
                      child: Text(
                        hasNotifications ? 'UPDATE' : 'SAVE',
                        style: const TextStyle(color: Colors.white),
                      ))
                ],
              ),
            ),
            SwitchListTile(
              value: hasNotifications,
              onChanged: (value) {
                if (hasNotifications) {
                  cancelNotifications();
                } else {
                  setNotification();
                }
                setState(() {
                  hasNotifications = value;
                });
              },
              title: const Text("Reminder Notification"),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 24.0),
              child: Text('Export Data',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                  onPressed: exportCSV,
                  child: const Text("EXPORT CSV",
                      style: TextStyle(color: Colors.white))),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 44.0),
              child: Text('Github',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            IconButton(
              icon: Image.asset(
                  isDarkMode ? 'assets/github.png' : 'assets/github2.png'),
              onPressed: () async => launchUrl(
                  Uri.parse('https://github.com/joscha0/peakflow'),
                  mode: LaunchMode.externalApplication),
            ),
            const SizedBox(height: 10),
            const Text('Made with ❤️ by @joscha0')
          ]),
        ),
      ),
    );
  }
}
