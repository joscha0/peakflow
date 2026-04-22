import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:peakflow/db/prefs.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/providers/day_entries_provider.dart';

class GraphView extends ConsumerStatefulWidget {
  const GraphView({super.key});

  @override
  ConsumerState<GraphView> createState() => _GraphViewState();
}

class _GraphViewState extends ConsumerState<GraphView> {
  int maxVolume = 850;
  int colorReferenceMaxVolume = 850;
  List<DayEntry> entries = [];
  List<DayEntry> entriesFiltered = [];
  DateTimeRange? range;

  List<FlSpot> spots = [];

  @override
  void initState() {
    super.initState();
    getData();
  }

  void loadSpots() {
    List<FlSpot> newSpots = [];
    int index = 0;
    for (int i = 0; i < entriesFiltered.length; i++) {
      if (i > 0) {
        index += daysBetween(
          entriesFiltered[i - 1].date,
          entriesFiltered[i].date,
        );
      }
      if (entriesFiltered[i].morningValue != -1) {
        newSpots.add(
          FlSpot(index.toDouble(), entriesFiltered[i].morningValue.toDouble()),
        );
      }
      if (entriesFiltered[i].eveningValue != -1) {
        newSpots.add(
          FlSpot(index + 0.5, entriesFiltered[i].eveningValue.toDouble()),
        );
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

  Future<void> getData() async {
    final loadedEntries = await ref
        .read(entryListProvider.notifier)
        .getEntries();
    final values = await Future.wait<int>([
      getDeviceMaxValue(),
      getColorReferenceMaxValue(),
    ]);
    if (!mounted) {
      return;
    }
    setState(() {
      entries = loadedEntries;
      entriesFiltered = loadedEntries;
      range = loadedEntries.isEmpty
          ? null
          : DateTimeRange(start: loadedEntries.first.date, end: DateTime.now());
      maxVolume = values[0];
      colorReferenceMaxVolume = values[1];
    });
    if (loadedEntries.isNotEmpty) {
      loadSpots();
    }
  }

  void filterEntries(DateTime start, DateTime end) {
    entriesFiltered = entries
        .where(
          (element) =>
              element.date.isAfter(start.subtract(const Duration(days: 1))) &&
              element.date.isBefore(end.add(const Duration(days: 1))),
        )
        .toList();
    loadSpots();
  }

  List<HorizontalRangeAnnotation> _buildZoneAnnotations(ThemeData theme) {
    final safeReferenceMax = colorReferenceMaxVolume.clamp(1, maxVolume);
    final redLimit = safeReferenceMax * 0.5;
    final orangeLimit = safeReferenceMax * 0.8;
    final zoneAlpha = theme.brightness == Brightness.dark ? 0.26 : 0.34;

    return [
      HorizontalRangeAnnotation(
        y1: 0,
        y2: redLimit,
        color: const Color(0xFFE64A19).withValues(alpha: zoneAlpha),
      ),
      HorizontalRangeAnnotation(
        y1: redLimit,
        y2: orangeLimit,
        color: const Color(0xFFFFB300).withValues(alpha: zoneAlpha),
      ),
      HorizontalRangeAnnotation(
        y1: orangeLimit,
        y2: safeReferenceMax.toDouble(),
        color: const Color(0xFF43A047).withValues(alpha: zoneAlpha),
      ),
    ];
  }

  DateTime? get _chartStartDate =>
      entriesFiltered.isEmpty ? null : entriesFiltered.first.date;

  int get _chartDaySpan {
    if (entriesFiltered.length < 2) {
      return 0;
    }
    return daysBetween(entriesFiltered.first.date, entriesFiltered.last.date);
  }

  double get _chartMaxX {
    if (entriesFiltered.isEmpty) {
      return 0;
    }

    final lastDayPosition = _chartDaySpan.toDouble();
    return entriesFiltered.last.eveningValue != -1
        ? lastDayPosition + 0.5
        : lastDayPosition;
  }

  double get _dateLabelInterval {
    final span = _chartDaySpan;

    if (span <= 7) {
      return 1;
    }
    if (span <= 14) {
      return 2;
    }
    if (span <= 21) {
      return 3;
    }
    if (span <= 42) {
      return 7;
    }
    if (span <= 84) {
      return 14;
    }
    return 30;
  }

  Widget _buildBottomDateTitle(
    BuildContext context,
    double value,
    TitleMeta meta,
  ) {
    final startDate = _chartStartDate;
    if (startDate == null || (value - value.roundToDouble()).abs() > 0.001) {
      return const SizedBox.shrink();
    }

    final dayOffset = value.round();
    if (dayOffset < 0 || dayOffset > _chartDaySpan) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final labelDate = startDate.add(Duration(days: dayOffset));

    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: Text(
        DateFormat('d.M.').format(labelDate),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Data")),
      body: Column(
        children: [
          if (entries.isEmpty)
            const Expanded(
              child: Center(child: Text("No data available yet.")),
            ),
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
                  "Range: ${DateFormat.yMMMMd().format(range!.start)} - ${DateFormat.yMMMMd().format(range!.end)}",
                ),
              ),
            ),
          ],
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              padding: const EdgeInsets.only(
                left: 16,
                top: 8,
                bottom: 24,
                right: 16,
              ),
              child: LineChart(
                LineChartData(
                  rangeAnnotations: RangeAnnotations(
                    horizontalRangeAnnotations: _buildZoneAnnotations(theme),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: _dateLabelInterval,
                        getTitlesWidget: (value, meta) =>
                            _buildBottomDateTitle(context, value, meta),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 50,
                        reservedSize: 42,
                      ),
                    ),
                  ),
                  minX: 0,
                  maxX: _chartMaxX,
                  minY: 0,
                  maxY: maxVolume.toDouble(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 50,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.dividerColor.withValues(
                        alpha: value % 100 == 0 ? 0.75 : 0.35,
                      ),
                      strokeWidth: value % 100 == 0 ? 1.4 : 0.8,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: theme.dividerColor.withValues(
                        alpha: value % 1 == 0 ? 0.5 : 0.22,
                      ),
                      strokeWidth: value % 1 == 0 ? 1 : 0.6,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.7),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipColor: (_) =>
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
                            .map(
                              (spot) => LineTooltipItem(
                                "",
                                const TextStyle(),
                                children: [
                                  TextSpan(
                                    text: data[spot.spotIndex]["isMorning"]
                                        ? "☀️"
                                        : "🌙",
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const TextSpan(text: "\n"),
                                  TextSpan(
                                    text: data[spot.spotIndex]["value"]
                                        .toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const TextSpan(text: "\n"),
                                  TextSpan(
                                    text: DateFormat(
                                      "dd.MM.yyyy",
                                    ).format(data[spot.spotIndex]["date"]),
                                  ),
                                ],
                              ),
                            )
                            .toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      color: theme.colorScheme.primary,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      preventCurveOverShooting: true,
                      barWidth: 2.2,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCrossPainter(
                              color: theme.colorScheme.primary,
                              size: 9,
                              width: 2,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
