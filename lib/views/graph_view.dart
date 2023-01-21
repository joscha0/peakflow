import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/providers/day_entries_provider.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GraphView extends StatefulHookConsumerWidget {
  const GraphView({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _GraphViewState();
}

class _GraphViewState extends ConsumerState<GraphView> {
  late int bestValue;
  int maxVolume = 850;
  List<DayEntry> entries = [];
  List<DayEntry> entriesFiltered = [];
  DateTimeRange? range;

  List<FlSpot> spots = [];

  @override
  void initState() {
    getData();
    super.initState();
  }

  void loadSpots() {
    List<FlSpot> newSpots = [];
    int index = 0;
    for (int i = 0; i < entriesFiltered.length; i++) {
      if (i > 0) {
        index +=
            daysBetween(entriesFiltered[i - 1].date, entriesFiltered[i].date);
      }
      if (entriesFiltered[i].morningValue != -1) {
        newSpots.add(
            FlSpot(index - 0.5, entriesFiltered[i].morningValue.toDouble()));
      }
      if (entriesFiltered[i].eveningValue != -1) {
        newSpots.add(FlSpot(
            index.toDouble(), entriesFiltered[i].eveningValue.toDouble()));
      }
    }

    setState(() {
      spots = newSpots;
    });
  }

  int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  void getData() async {
    bestValue = await getBestValue();
    entries = await ref.read(entryListProvider.notifier).getEntries();
    entriesFiltered = entries;
    range = DateTimeRange(start: entries.first.date, end: DateTime.now());
    loadSpots();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      maxVolume = prefs.getInt("maxVolume") ?? 850;
    });
  }

  void filterEntries(DateTime start, DateTime end) {
    entriesFiltered = entries
        .where((element) =>
            element.date.isAfter(start.subtract(const Duration(days: 1))) &&
            element.date.isBefore(end.add(const Duration(days: 1))))
        .toList();
    loadSpots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Data"),
      ),
      body: Column(children: [
        if (range != null) ...[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  lastDate: DateTime.now(),
                  firstDate: entries.first.date,
                );
                if (picked != null) {
                  filterEntries(picked.start, picked.end);
                  setState(() {
                    range = picked;
                  });
                }
              },
              child: Text(
                  "Range: ${DateFormat.yMMMMd().format(range!.start)} - ${DateFormat.yMMMMd().format(range!.end)}"),
            ),
          ),
        ],
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding:
                const EdgeInsets.only(left: 16, top: 8, bottom: 24, right: 16),
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
                          for (int i = 0; i < entriesFiltered.length; i++) {
                            if (entriesFiltered[i].morningValue != -1) {
                              data.add({
                                "value": entriesFiltered[i].morningValue,
                                "date": entriesFiltered[i].date,
                                "isMorning": true,
                              });
                            }
                            if (entriesFiltered[i].eveningValue != -1) {
                              data.add({
                                "value": entriesFiltered[i].eveningValue,
                                "date": entriesFiltered[i].date,
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
                    spots: spots,
                    color: Colors.blueAccent.shade700,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    preventCurveOverShooting: true,
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
