import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:peakflow/db/day_entries_provider.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/views/add_view.dart';
import 'package:peakflow/widgets/date_widget.dart';

class HomeView extends StatefulHookConsumerWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  // late List<DayEntry> entries;
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
          IconButton(onPressed: () {}, icon: const Icon(Icons.bar_chart)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
        ],
      ),
      body: GridView(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.75,
          ),
          children: [
            for (var i = 0; i < entries.length; i++) ...[
              DateWidget(
                date: entries[i].date,
                morningValue: entries[i].morningValue,
                eveningValue: entries[i].eveningValue,
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
