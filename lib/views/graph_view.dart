import 'dart:math' as math;

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
  static const double _minDayWidth = 48;
  static const double _chartRightPadding = 16;
  static const double _yAxisWidth = 42;
  static const double _yAxisGap = 0;
  static const double _bottomTitleReservedSize = 30;
  static const double _scrollbarThickness = 12;
  static const double _scrollbarDragClearance = 18;
  static const double _dragScrollMultiplier = 1;

  int maxVolume = 850;
  int colorReferenceMaxVolume = 850;
  List<DayEntry> entries = [];
  List<DayEntry> entriesFiltered = [];
  DateTimeRange? range;

  List<FlSpot> spots = [];
  final ScrollController _chartScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  void dispose() {
    _chartScrollController.dispose();
    super.dispose();
  }

  void _scheduleScrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chartScrollController.hasClients) {
        return;
      }

      final position = _chartScrollController.position;
      _chartScrollController.jumpTo(position.maxScrollExtent);
    });
  }

  void _dragChartBy(double delta) {
    if (!_chartScrollController.hasClients) {
      return;
    }

    final position = _chartScrollController.position;
    final nextOffset =
        (_chartScrollController.offset - (delta * _dragScrollMultiplier)).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
    _chartScrollController.jumpTo(nextOffset);
  }

  List<FlSpot> _buildSpots(List<DayEntry> filteredEntries) {
    final startDate = _chartStartDate;
    if (startDate == null) {
      return const [];
    }

    List<FlSpot> newSpots = [];
    for (final entry in filteredEntries) {
      final index = daysBetween(startDate, entry.date).toDouble();
      if (entry.morningValue != -1) {
        newSpots.add(FlSpot(index, entry.morningValue.toDouble()));
      }
      if (entry.eveningValue != -1) {
        newSpots.add(FlSpot(index + 0.5, entry.eveningValue.toDouble()));
      }
    }
    return newSpots;
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
    final initialRange = loadedEntries.isEmpty
        ? null
        : DateTimeRange(start: loadedEntries.first.date, end: DateTime.now());
    final initialFilteredEntries = _filterEntriesForRange(
      loadedEntries,
      initialRange,
    );
    setState(() {
      entries = loadedEntries;
      entriesFiltered = initialFilteredEntries;
      range = initialRange;
      maxVolume = values[0];
      colorReferenceMaxVolume = values[1];
      spots = _buildSpots(initialFilteredEntries);
    });
    if (initialRange != null) {
      _scheduleScrollToEnd();
    }
  }

  List<DayEntry> _filterEntriesForRange(
    List<DayEntry> sourceEntries,
    DateTimeRange? nextRange,
  ) {
    if (nextRange == null) {
      return sourceEntries;
    }

    return sourceEntries
        .where(
          (element) =>
              element.date.isAfter(
                nextRange.start.subtract(const Duration(days: 1)),
              ) &&
              element.date.isBefore(nextRange.end.add(const Duration(days: 1))),
        )
        .toList();
  }

  void filterEntries(DateTime start, DateTime end) {
    final nextRange = DateTimeRange(start: start, end: end);
    final filteredEntries = _filterEntriesForRange(entries, nextRange);

    setState(() {
      range = nextRange;
      entriesFiltered = filteredEntries;
      spots = _buildSpots(filteredEntries);
    });
    _scheduleScrollToEnd();
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
      range?.start ??
      (entriesFiltered.isEmpty ? null : entriesFiltered.first.date);

  DateTime? get _chartEndDate {
    if (range != null) {
      return range!.end;
    }
    if (entriesFiltered.isEmpty) {
      return null;
    }
    return entriesFiltered.last.date;
  }

  int get _chartDaySpan {
    final startDate = _chartStartDate;
    final endDate = _chartEndDate;
    if (startDate == null || endDate == null) {
      return 0;
    }
    return daysBetween(startDate, endDate);
  }

  double get _chartMaxX {
    final trailingSpot = spots.isEmpty ? 0.0 : spots.last.x;
    return math.max(_chartDaySpan.toDouble(), trailingSpot);
  }

  List<int> get _yAxisValues {
    final values = <int>[];
    for (int value = 0; value <= maxVolume; value += 50) {
      values.add(value);
    }
    if (values.isEmpty || values.last != maxVolume) {
      values.add(maxVolume);
    }
    return values;
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

  Widget _buildFixedYAxis(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartHeight = math.max(
          0.0,
          constraints.maxHeight - _bottomTitleReservedSize,
        );
        final labelStyle = theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
          fontWeight: FontWeight.w600,
        );
        final dividerColor = theme.dividerColor.withValues(alpha: 0.7);

        return Column(
          children: [
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(width: 1, color: dividerColor),
                  ),
                  for (final value in _yAxisValues)
                    Positioned(
                      right: 8,
                      top: chartHeight == 0
                          ? 0
                          : (chartHeight * (1 - (value / maxVolume))) - 10,
                      child: Text(
                        value.toString(),
                        style: labelStyle,
                        textAlign: TextAlign.right,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: _bottomTitleReservedSize),
          ],
        );
      },
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
                  }
                },
                child: Text(
                  "Range: ${DateFormat.yMMMMd().format(range!.start)} - ${DateFormat.yMMMMd().format(range!.end)}",
                ),
              ),
            ),
          ],
          if (range != null)
            AspectRatio(
              aspectRatio: 1,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  top: 8,
                  bottom: 12,
                  right: 16,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final plotViewportWidth = math.max(
                      0.0,
                      constraints.maxWidth - _yAxisWidth - _yAxisGap,
                    );
                    final chartWidth = math.max(
                      plotViewportWidth,
                      _chartRightPadding + ((_chartDaySpan + 1) * _minDayWidth),
                    );

                    return Row(
                      children: [
                        SizedBox(
                          width: _yAxisWidth,
                          child: _buildFixedYAxis(theme),
                        ),
                        const SizedBox(width: _yAxisGap),
                        Expanded(
                          child: Scrollbar(
                            controller: _chartScrollController,
                            interactive: true,
                            thumbVisibility: true,
                            trackVisibility: true,
                            thickness: _scrollbarThickness,
                            scrollbarOrientation: ScrollbarOrientation.bottom,
                            child: Stack(
                              children: [
                                SingleChildScrollView(
                                  controller: _chartScrollController,
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: chartWidth,
                                    child: LineChart(
                                      LineChartData(
                                        rangeAnnotations: RangeAnnotations(
                                          horizontalRangeAnnotations:
                                              _buildZoneAnnotations(theme),
                                        ),
                                        titlesData: FlTitlesData(
                                          rightTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
                                            ),
                                          ),
                                          topTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
                                            ),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize:
                                                  _bottomTitleReservedSize,
                                              interval: 1,
                                              getTitlesWidget: (value, meta) =>
                                                  _buildBottomDateTitle(
                                                    context,
                                                    value,
                                                    meta,
                                                  ),
                                            ),
                                          ),
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
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
                                          getDrawingHorizontalLine: (value) =>
                                              FlLine(
                                                color: theme.dividerColor
                                                    .withValues(
                                                      alpha: value % 100 == 0
                                                          ? 0.75
                                                          : 0.35,
                                                    ),
                                                strokeWidth: value % 100 == 0
                                                    ? 1.4
                                                    : 0.8,
                                              ),
                                          getDrawingVerticalLine: (value) =>
                                              FlLine(
                                                color: theme.dividerColor
                                                    .withValues(
                                                      alpha: value % 1 == 0
                                                          ? 0.5
                                                          : 0.22,
                                                    ),
                                                strokeWidth: value % 1 == 0
                                                    ? 1
                                                    : 0.6,
                                              ),
                                        ),
                                        borderData: FlBorderData(
                                          show: true,
                                          border: Border(
                                            top: BorderSide(
                                              color: theme.dividerColor
                                                  .withValues(alpha: 0.7),
                                            ),
                                            right: BorderSide(
                                              color: theme.dividerColor
                                                  .withValues(alpha: 0.7),
                                            ),
                                            bottom: BorderSide(
                                              color: theme.dividerColor
                                                  .withValues(alpha: 0.7),
                                            ),
                                            left: BorderSide.none,
                                          ),
                                        ),
                                        lineTouchData: LineTouchData(
                                          touchTooltipData: LineTouchTooltipData(
                                            fitInsideHorizontally: true,
                                            fitInsideVertically: true,
                                            getTooltipColor: (_) =>
                                                Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.grey.shade900
                                                : Colors.white,
                                            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                                              List data = [];
                                              for (
                                                int i = 0;
                                                i < entriesFiltered.length;
                                                i++
                                              ) {
                                                if (entriesFiltered[i]
                                                        .morningValue !=
                                                    -1) {
                                                  data.add({
                                                    "value": entriesFiltered[i]
                                                        .morningValue,
                                                    "date":
                                                        entriesFiltered[i].date,
                                                    "isMorning": true,
                                                  });
                                                }
                                                if (entriesFiltered[i]
                                                        .eveningValue !=
                                                    -1) {
                                                  data.add({
                                                    "value": entriesFiltered[i]
                                                        .eveningValue,
                                                    "date":
                                                        entriesFiltered[i].date,
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
                                                          text:
                                                              data[spot
                                                                  .spotIndex]["isMorning"]
                                                              ? "☀️"
                                                              : "🌙",
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 24,
                                                              ),
                                                        ),
                                                        const TextSpan(
                                                          text: "\n",
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              data[spot
                                                                      .spotIndex]["value"]
                                                                  .toString(),
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                              ),
                                                        ),
                                                        const TextSpan(
                                                          text: "\n",
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              DateFormat(
                                                                "dd.MM.yyyy",
                                                              ).format(
                                                                data[spot
                                                                    .spotIndex]["date"],
                                                              ),
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
                                            isCurved: false,
                                            barWidth: 2.2,
                                            dotData: FlDotData(
                                              show: true,
                                              getDotPainter:
                                                  (spot, percent, bar, index) =>
                                                      FlDotCrossPainter(
                                                        color: theme
                                                            .colorScheme
                                                            .primary,
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
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  right: 0,
                                  bottom: _scrollbarDragClearance,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onHorizontalDragUpdate: (details) =>
                                        _dragChartBy(details.delta.dx),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
