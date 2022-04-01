import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:peakflow/widgets/date_widget.dart';

class HomeView extends HookConsumerWidget {
  const HomeView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.black,
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
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
