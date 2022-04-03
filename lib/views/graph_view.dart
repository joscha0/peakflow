import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:peakflow/providers/day_entries_provider.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GraphView extends StatefulHookConsumerWidget {
  const GraphView({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _GraphViewState();
}

class _GraphViewState extends ConsumerState<GraphView> {
  late int bestValue;
  int maxVolume = 850;

  @override
  void initState() {
    getData();
    super.initState();
  }

  void getData() async {
    bestValue = await getBestValue();
    ref.read(entryListProvider.notifier).getEntries();
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      maxVolume = prefs.getInt("maxVolume") ?? 850;
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(entryListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Data"),
      ),
      body: Column(children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding:
                const EdgeInsets.only(left: 16, top: 32, bottom: 24, right: 16),
            child: LineChart(
              LineChartData(
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 50,
                      reservedSize: 42,
                    ),
                  ),
                ),
                minY: 0,
                maxY: maxVolume.toDouble(),
                lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        tooltipBgColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade900
                                : Colors.white,
                        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                          List data = [];
                          for (int i = 0; i < entries.length; i++) {
                            if (entries[i].morningValue != -1) {
                              data.add({
                                "value": entries[i].morningValue,
                                "date": entries[i].date,
                                "isMorning": true,
                              });
                            }
                            if (entries[i].eveningValue != -1) {
                              data.add({
                                "value": entries[i].eveningValue,
                                "date": entries[i].date,
                                "isMorning": false,
                              });
                            }
                          }
                          return touchedBarSpots
                              .map((spot) => LineTooltipItem(
                                      "", const TextStyle(),
                                      children: [
                                        TextSpan(
                                            text: data[spot.spotIndex]
                                                    ["isMorning"]
                                                ? "☀️"
                                                : "🌙",
                                            style:
                                                const TextStyle(fontSize: 24)),
                                        const TextSpan(text: "\n"),
                                        TextSpan(
                                            text: data[spot.spotIndex]["value"]
                                                .toString(),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                        const TextSpan(text: "\n"),
                                        TextSpan(
                                            text: DateFormat("dd.MM.yyyy")
                                                .format(data[spot.spotIndex]
                                                    ["date"]))
                                      ]))
                              .toList();
                        })),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < entries.length; i++) ...[
                        if (entries[i].morningValue != -1) ...[
                          FlSpot(i - 0.5, entries[i].morningValue.toDouble()),
                        ],
                        if (entries[i].eveningValue != -1) ...[
                          FlSpot(
                              i.toDouble(), entries[i].eveningValue.toDouble()),
                        ],
                      ]
                    ],
                    color: Colors.blueAccent.shade700,
                    isCurved: true,
                  ),
                ],
              ),
            ),
          ),
        )
      ]),
    );
  }
}
