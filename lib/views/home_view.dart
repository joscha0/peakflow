import 'package:flutter/material.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peakflow/providers/day_entries_provider.dart';
import 'package:peakflow/views/add_view.dart';
import 'package:peakflow/views/graph_view.dart';
import 'package:peakflow/views/settings_view.dart';
import 'package:peakflow/widgets/date_widget.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  int referenceMaxValue = defaultMaxVolume;
  bool sortUp = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    final loadedReferenceMaxValue = await getColorReferenceMaxValue();
    final loadedSortUp = await getSortValue();
    if (!mounted) {
      return;
    }
    setState(() {
      referenceMaxValue = loadedReferenceMaxValue;
      sortUp = loadedSortUp;
    });
    ref.read(entryListProvider.notifier).loadEntries();
  }

  void changeSort() {
    ref.read(entryListProvider.notifier).changeSort();
    setState(() {
      sortUp = !sortUp;
    });
    setSortValue(sortUp);
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
            onPressed: changeSort,
            icon: Icon(sortUp ? Icons.arrow_upward : Icons.arrow_downward),
          ),
          IconButton(
            onPressed: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const GraphView()));
              await init();
            },
            icon: const Icon(Icons.bar_chart),
          ),
          IconButton(
            onPressed: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsView()));
              await init();
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.75,
        ),
        itemCount: entries.length,
        itemBuilder: (BuildContext ctx, index) {
          return DateWidget(
            dayEntry: entries[index],
            referenceMaxValue: referenceMaxValue,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddView()));
          await init();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
