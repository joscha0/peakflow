import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:peakflow/global/consts.dart';
import 'package:peakflow/providers/theme_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsView extends StatefulHookConsumerWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final maxController = TextEditingController();
  bool isDarkMode = true;

  @override
  void initState() {
    loadSettings();
    super.initState();
  }

  void loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    maxController.text = (prefs.getInt("maxVolume") ?? 850).toString();
    isDarkMode = prefs.getBool("isDarkMode") ?? true;
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

  Future<void> setNotification() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('peakflow daily', 'Peakflow daily reminder',
            channelDescription: 'Peakflow daily reminder to take record');
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    flutterLocalNotificationsPlugin.periodicallyShow(
        0,
        'Test your Peakflow',
        'Take your peakflow record now!',
        RepeatInterval.daily,
        notificationDetails,
        androidAllowWhileIdle: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: [
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
          const SizedBox(
            height: 8,
          ),
          Row(
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
                    FilteringTextInputFormatter(RegExp(r'[0-9]'), allow: true),
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
          const Padding(
            padding: EdgeInsets.only(top: 24.0),
            child: Text('Export Data',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
                onPressed: exportCSV,
                child: const Text("Export CSV",
                    style: TextStyle(color: Colors.white))),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 24.0),
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
    );
  }
}
