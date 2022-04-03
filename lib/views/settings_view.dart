import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:peakflow/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
                    },
                    child: const Text(
                      "SAVE",
                      style: TextStyle(color: Colors.white),
                    )),
              )
            ],
          )
        ]),
      ),
    );
  }
}
