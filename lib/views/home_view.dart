import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:peakflow/providers/day_entries_provider.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:peakflow/views/add_view.dart';
import 'package:peakflow/views/graph_view.dart';
import 'package:peakflow/views/settings_view.dart';
import 'package:peakflow/widgets/date_widget.dart';

class HomeView extends StatefulHookConsumerWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  late int bestValue;

  @override
  void initState() {
    init();
    super.initState();
  }

  void init() async {
    bestValue = await getBestValue();
    ref.read(entryListProvider.notifier).getEntries();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(entryListProvider);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("PEAK FLOW"),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const GraphView()));
              },
              icon: const Icon(Icons.bar_chart)),
          IconButton(
              onPressed: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsView()));
              },
              icon: const Icon(Icons.settings)),
        ],
      ),
      body: GridView(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.75,
          ),
          children: [
            for (var i = 0; i < entries.length; i++) ...[
              DateWidget(
                dayEntry: entries[i],
                bestValue: bestValue,
              ),
            ],
          ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const AddView()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
