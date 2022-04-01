import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:peakflow/db/day_entries_provider.dart';
import 'package:peakflow/views/add_view.dart';
import 'package:peakflow/widgets/date_widget.dart';

class HomeView extends HookConsumerWidget {
  const HomeView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            DateWidget(
              date: DateTime.now().add(Duration(days: -2)),
              morningValue: 20,
              bestValue: 200,
            ),
            DateWidget(
              date: DateTime.now().add(Duration(days: -1)),
              morningValue: 100,
              eveningValue: 200,
              bestValue: 200,
            ),
            DateWidget(
              date: DateTime.now().add(Duration(days: -0)),
              morningValue: 100,
              eveningValue: 200,
              bestValue: 200,
            ),
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
