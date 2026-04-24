import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:peakflow/db/prefs.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/providers/day_entries_provider.dart';

class GraphView extends ConsumerStatefulWidget {
  const GraphView({super.key});

  @override
  ConsumerState<GraphView> createState() => _GraphViewState();
}

class _GraphViewState extends ConsumerState<GraphView> {
  static const double _chartRightPadding = 16;
  static const double _yAxisWidth = 42;
  static const double _yAxisGap = 0;
  static const double _bottomTitleReservedSize = 58;
  static const double _scrollbarThickness = 24;
  static const double _scrollbarTopSpacing = 8;
  static const double _dragScrollMultiplier = 1;
  static const double _minDayWidth = 18;
  static const double _maxDayWidth = 32;
  static final intl.DateFormat _rangeDateFormat = intl.DateFormat.yMMMMd();
  static final intl.DateFormat _tooltipDateFormat = intl.DateFormat(
    'dd.MM.yyyy',
  );

  int maxVolume = 850;
  int colorReferenceMaxVolume = 850;
  bool isLoading = true;
  List<DayEntry> entries = const [];
  List<DayEntry> entriesFiltered = const [];
  DateTimeRange? range;
  List<_ChartPoint> chartPoints = const [];
  _ChartPoint? selectedPoint;

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

  List<_ChartPoint> _buildChartPoints(
    List<DayEntry> filteredEntries,
    DateTime? startDate,
  ) {
    if (startDate == null) {
      return const [];
    }

    final points = <_ChartPoint>[];
    for (final entry in filteredEntries) {
      final dayIndex = daysBetween(startDate, entry.date).toDouble();
      if (entry.morningValue != -1) {
        points.add(
          _ChartPoint(
            x: dayIndex + 0.25,
            value: entry.morningValue,
            date: entry.date,
            label: 'AM',
          ),
        );
      }
      if (entry.eveningValue != -1) {
        points.add(
          _ChartPoint(
            x: dayIndex + 0.75,
            value: entry.eveningValue,
            date: entry.date,
            label: 'PM',
          ),
        );
      }
    }
    return List.unmodifiable(points);
  }

  int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  Future<void> getData() async {
    final entriesFuture = ref.read(entryListProvider.notifier).getEntries();
    final valuesFuture = Future.wait<int>([
      getDeviceMaxValue(),
      getColorReferenceMaxValue(),
    ]);
    final loadedEntries = await entriesFuture;
    final values = await valuesFuture;
    if (!mounted) {
      return;
    }

    final sortedEntries = [...loadedEntries]
      ..sort((first, second) => first.date.compareTo(second.date));

    final initialRange = sortedEntries.isEmpty
        ? null
        : DateTimeRange(
            start: sortedEntries.first.date,
            end: sortedEntries.last.date,
          );
    final initialFilteredEntries = _filterEntriesForRange(
      sortedEntries,
      initialRange,
    );
    final startDate =
        initialRange?.start ??
        (initialFilteredEntries.isEmpty
            ? null
            : initialFilteredEntries.first.date);

    setState(() {
      entries = sortedEntries;
      entriesFiltered = initialFilteredEntries;
      range = initialRange;
      maxVolume = values[0];
      colorReferenceMaxVolume = values[1];
      chartPoints = _buildChartPoints(initialFilteredEntries, startDate);
      selectedPoint = null;
      isLoading = false;
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
        .toList(growable: false);
  }

  void filterEntries(DateTime start, DateTime end) {
    final nextRange = DateTimeRange(start: start, end: end);
    final filteredEntries = _filterEntriesForRange(entries, nextRange);

    setState(() {
      range = nextRange;
      entriesFiltered = filteredEntries;
      chartPoints = _buildChartPoints(filteredEntries, nextRange.start);
      selectedPoint = null;
    });
    _scheduleScrollToEnd();
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

  double _resolveDayWidth(double viewportWidth) {
    final dayCount = math.max(_chartDaySpan + 1, 1);
    final targetContentWidth = math.max(viewportWidth * 1.5, 2400.0);
    return (targetContentWidth / dayCount).clamp(_minDayWidth, _maxDayWidth);
  }

  double _yPositionForValue(double value, double chartHeight) {
    if (maxVolume <= 0) {
      return chartHeight;
    }
    return chartHeight * (1 - (value / maxVolume));
  }

  _ChartPoint? _findNearestPoint(double logicalX) {
    if (chartPoints.isEmpty) {
      return null;
    }

    int low = 0;
    int high = chartPoints.length;
    while (low < high) {
      final mid = low + ((high - low) >> 1);
      if (chartPoints[mid].x < logicalX) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }

    final closestIndex = low.clamp(0, chartPoints.length - 1);
    _ChartPoint closest = chartPoints[closestIndex];
    if (low > 0) {
      final previous = chartPoints[low - 1];
      if ((previous.x - logicalX).abs() <= (closest.x - logicalX).abs()) {
        closest = previous;
      }
    }
    if (low + 1 < chartPoints.length) {
      final next = chartPoints[low + 1];
      if ((next.x - logicalX).abs() < (closest.x - logicalX).abs()) {
        closest = next;
      }
    }
    return closest;
  }

  void _selectPointAtPosition({
    required Offset localPosition,
    required double chartHeight,
    required double dayWidth,
  }) {
    if (chartPoints.isEmpty || localPosition.dy > chartHeight) {
      if (selectedPoint != null) {
        setState(() => selectedPoint = null);
      }
      return;
    }

    final scrollOffset = _chartScrollController.hasClients
        ? _chartScrollController.offset
        : 0.0;
    final contentX = scrollOffset + localPosition.dx;
    final logicalX = contentX / dayWidth;
    final nearestPoint = _findNearestPoint(logicalX);
    if (nearestPoint == null) {
      return;
    }

    final dx = (nearestPoint.x * dayWidth) - contentX;
    final dy =
        _yPositionForValue(nearestPoint.value.toDouble(), chartHeight) -
        localPosition.dy;
    final distance = math.sqrt((dx * dx) + (dy * dy));

    if (distance > 32) {
      if (selectedPoint != null) {
        setState(() => selectedPoint = null);
      }
      return;
    }

    if (selectedPoint != nearestPoint) {
      setState(() => selectedPoint = nearestPoint);
    }
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

  Widget _buildTooltipOverlay({
    required ThemeData theme,
    required double viewportWidth,
    required double chartHeight,
    required double dayWidth,
  }) {
    final point = selectedPoint;
    if (point == null) {
      return const SizedBox.shrink();
    }

    const tooltipWidth = 112.0;
    const tooltipHeight = 84.0;

    return AnimatedBuilder(
      animation: _chartScrollController,
      builder: (context, child) {
        final scrollOffset = _chartScrollController.hasClients
            ? _chartScrollController.offset
            : 0.0;
        final pointX = (point.x * dayWidth) - scrollOffset;
        final pointY = _yPositionForValue(point.value.toDouble(), chartHeight);

        if (pointX < -24 || pointX > viewportWidth + 24) {
          return const SizedBox.shrink();
        }

        final left = (pointX - (tooltipWidth / 2)).clamp(
          4.0,
          viewportWidth - tooltipWidth - 4,
        );
        final preferredTop = pointY - tooltipHeight - 12;
        final top = preferredTop < 4
            ? (pointY + 12).clamp(4.0, chartHeight - tooltipHeight - 4)
            : preferredTop.clamp(4.0, chartHeight - tooltipHeight - 4);

        return Positioned(
          left: left,
          top: top,
          child: IgnorePointer(
            child: Container(
              width: tooltipWidth,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey.shade900
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.75),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: DefaultTextStyle(
                style:
                    theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ) ??
                    const TextStyle(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      point.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      point.value.toString(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_tooltipDateFormat.format(point.date)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Data')),
      body: isLoading
          ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(),
              ),
            )
          : Column(
              children: [
                if (entries.isEmpty)
                  const Expanded(
                    child: Center(child: Text('No data available yet.')),
                  ),
                if (range != null)
                  Padding(
                    padding: const EdgeInsets.all(8),
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
                        'Range: ${_rangeDateFormat.format(range!.start)} - ${_rangeDateFormat.format(range!.end)}',
                      ),
                    ),
                  ),
                if (range != null)
                  AspectRatio(
                    aspectRatio: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        top: 8,
                        right: 16,
                        bottom: 12,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final plotViewportWidth = math.max(
                            0.0,
                            constraints.maxWidth - _yAxisWidth - _yAxisGap,
                          );
                          final chartHeight = math.max(
                            0.0,
                            constraints.maxHeight -
                                _bottomTitleReservedSize -
                                _scrollbarThickness -
                                _scrollbarTopSpacing,
                          );
                          final chartAreaHeight = math.max(
                            0.0,
                            constraints.maxHeight -
                                _scrollbarThickness -
                                _scrollbarTopSpacing,
                          );
                          final dayWidth = _resolveDayWidth(plotViewportWidth);
                          final chartWidth = math.max(
                            plotViewportWidth,
                            _chartRightPadding +
                                ((_chartDaySpan + 1) * dayWidth),
                          );

                          return Row(
                            children: [
                              SizedBox(
                                width: _yAxisWidth,
                                child: _buildFixedYAxis(theme),
                              ),
                              const SizedBox(width: _yAxisGap),
                              Expanded(
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: chartAreaHeight,
                                      child: Stack(
                                        children: [
                                          RepaintBoundary(
                                            child: SingleChildScrollView(
                                              controller:
                                                  _chartScrollController,
                                              physics:
                                                  const ClampingScrollPhysics(),
                                              scrollDirection: Axis.horizontal,
                                              child: SizedBox(
                                                width: chartWidth,
                                                height: chartAreaHeight,
                                                child: CustomPaint(
                                                  painter: _PeakFlowChartPainter(
                                                    theme: theme,
                                                    points: chartPoints,
                                                    selectedPoint:
                                                        selectedPoint,
                                                    startDate: _chartStartDate,
                                                    daySpan: _chartDaySpan,
                                                    maxVolume: maxVolume,
                                                    colorReferenceMaxVolume:
                                                        colorReferenceMaxVolume,
                                                    dayWidth: dayWidth,
                                                    chartRightPadding:
                                                        _chartRightPadding,
                                                    bottomTitleReservedSize:
                                                        _bottomTitleReservedSize,
                                                    viewportWidth:
                                                        plotViewportWidth,
                                                    scrollController:
                                                        _chartScrollController,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned.fill(
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTapDown: (details) =>
                                                  _selectPointAtPosition(
                                                    localPosition:
                                                        details.localPosition,
                                                    chartHeight: chartHeight,
                                                    dayWidth: dayWidth,
                                                  ),
                                              onHorizontalDragUpdate:
                                                  (details) => _dragChartBy(
                                                    details.delta.dx,
                                                  ),
                                            ),
                                          ),
                                          _buildTooltipOverlay(
                                            theme: theme,
                                            viewportWidth: plotViewportWidth,
                                            chartHeight: chartHeight,
                                            dayWidth: dayWidth,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      height: _scrollbarTopSpacing,
                                    ),
                                    _ChartScrollbar(
                                      controller: _chartScrollController,
                                      theme: theme,
                                      thickness: _scrollbarThickness,
                                    ),
                                  ],
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

class _ChartPoint {
  const _ChartPoint({
    required this.x,
    required this.value,
    required this.date,
    required this.label,
  });

  final double x;
  final int value;
  final DateTime date;
  final String label;
}

class _ChartScrollbar extends StatelessWidget {
  const _ChartScrollbar({
    required this.controller,
    required this.theme,
    required this.thickness,
  });

  final ScrollController controller;
  final ThemeData theme;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: thickness,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final hasClients = controller.hasClients;
              final maxScrollExtent = hasClients
                  ? controller.position.maxScrollExtent
                  : 0.0;
              final viewportWidth = hasClients
                  ? controller.position.viewportDimension
                  : constraints.maxWidth;
              final contentWidth = viewportWidth + maxScrollExtent;
              final minThumbWidth = math.min(constraints.maxWidth, 72.0);
              final thumbWidth = contentWidth <= 0
                  ? constraints.maxWidth
                  : math.max(
                      minThumbWidth,
                      constraints.maxWidth * (viewportWidth / contentWidth),
                    );
              final availableTravel = math.max(
                0.0,
                constraints.maxWidth - thumbWidth,
              );
              final thumbLeft = maxScrollExtent <= 0 || availableTravel == 0
                  ? 0.0
                  : availableTravel * (controller.offset / maxScrollExtent);

              void jumpToTrackPosition(double localDx) {
                if (!hasClients ||
                    maxScrollExtent <= 0 ||
                    availableTravel == 0) {
                  return;
                }
                final nextThumbLeft = (localDx - (thumbWidth / 2)).clamp(
                  0.0,
                  availableTravel,
                );
                final nextOffset =
                    (nextThumbLeft / availableTravel) * maxScrollExtent;
                controller.jumpTo(nextOffset.clamp(0.0, maxScrollExtent));
              }

              void dragBy(double deltaDx) {
                if (!hasClients ||
                    maxScrollExtent <= 0 ||
                    availableTravel == 0) {
                  return;
                }
                final scrollDelta =
                    deltaDx * (maxScrollExtent / availableTravel);
                final nextOffset = (controller.offset + scrollDelta).clamp(
                  0.0,
                  maxScrollExtent,
                );
                controller.jumpTo(nextOffset);
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) =>
                    jumpToTrackPosition(details.localPosition.dx),
                onHorizontalDragUpdate: (details) => dragBy(details.delta.dx),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.45,
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: thumbLeft,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: thumbWidth,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.9,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.28,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.keyboard_arrow_left_rounded,
                                size: 20,
                                color: theme.colorScheme.onPrimary,
                              ),
                              Container(
                                width: 18,
                                height: 4,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onPrimary.withValues(
                                    alpha: 0.7,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_right_rounded,
                                size: 20,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PeakFlowChartPainter extends CustomPainter {
  _PeakFlowChartPainter({
    required this.theme,
    required this.points,
    required this.selectedPoint,
    required this.startDate,
    required this.daySpan,
    required this.maxVolume,
    required this.colorReferenceMaxVolume,
    required this.dayWidth,
    required this.chartRightPadding,
    required this.bottomTitleReservedSize,
    required this.viewportWidth,
    required this.scrollController,
  }) : super(repaint: scrollController);

  static final intl.DateFormat _monthLabelDateFormat = intl.DateFormat(
    'MMM yyyy',
  );

  final ThemeData theme;
  final List<_ChartPoint> points;
  final _ChartPoint? selectedPoint;
  final DateTime? startDate;
  final int daySpan;
  final int maxVolume;
  final int colorReferenceMaxVolume;
  final double dayWidth;
  final double chartRightPadding;
  final double bottomTitleReservedSize;
  final double viewportWidth;
  final ScrollController scrollController;

  @override
  void paint(Canvas canvas, Size size) {
    final plotHeight = math.max(0.0, size.height - bottomTitleReservedSize);
    if (plotHeight <= 0) {
      return;
    }

    final scrollOffset = scrollController.hasClients
        ? scrollController.offset
        : 0.0;
    final visibleLeft = scrollOffset.clamp(0.0, size.width);
    final visibleRight = (scrollOffset + viewportWidth).clamp(0.0, size.width);

    _paintZones(
      canvas: canvas,
      plotHeight: plotHeight,
      visibleLeft: visibleLeft,
      visibleRight: visibleRight,
    );
    _paintGrid(
      canvas: canvas,
      plotHeight: plotHeight,
      visibleLeft: visibleLeft,
      visibleRight: visibleRight,
    );
    _paintLine(
      canvas: canvas,
      plotHeight: plotHeight,
      visibleLeft: visibleLeft,
      visibleRight: visibleRight,
    );
    _paintSelection(
      canvas: canvas,
      plotHeight: plotHeight,
      visibleLeft: visibleLeft,
      visibleRight: visibleRight,
    );
    _paintBorder(
      canvas: canvas,
      plotHeight: plotHeight,
      visibleLeft: visibleLeft,
      visibleRight: visibleRight,
      contentWidth: size.width,
    );
    _paintBottomLabels(
      canvas: canvas,
      plotHeight: plotHeight,
      visibleLeft: visibleLeft,
      visibleRight: visibleRight,
      contentWidth: size.width,
    );
  }

  @override
  bool shouldRepaint(covariant _PeakFlowChartPainter oldDelegate) {
    return oldDelegate.theme != theme ||
        oldDelegate.points != points ||
        oldDelegate.selectedPoint != selectedPoint ||
        oldDelegate.startDate != startDate ||
        oldDelegate.daySpan != daySpan ||
        oldDelegate.maxVolume != maxVolume ||
        oldDelegate.colorReferenceMaxVolume != colorReferenceMaxVolume ||
        oldDelegate.dayWidth != dayWidth ||
        oldDelegate.chartRightPadding != chartRightPadding ||
        oldDelegate.bottomTitleReservedSize != bottomTitleReservedSize ||
        oldDelegate.viewportWidth != viewportWidth ||
        oldDelegate.scrollController != scrollController;
  }

  void _paintZones({
    required Canvas canvas,
    required double plotHeight,
    required double visibleLeft,
    required double visibleRight,
  }) {
    final safeReferenceMax = colorReferenceMaxVolume.clamp(1, maxVolume);
    final redLimit = safeReferenceMax * 0.5;
    final orangeLimit = safeReferenceMax * 0.8;
    final zoneAlpha = theme.brightness == Brightness.dark ? 0.26 : 0.34;

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(visibleLeft, 0, visibleRight, plotHeight));

    canvas.drawRect(
      Rect.fromLTRB(
        visibleLeft,
        _yForValue(redLimit.toDouble(), plotHeight),
        visibleRight,
        plotHeight,
      ),
      Paint()..color = const Color(0xFFE64A19).withValues(alpha: zoneAlpha),
    );
    canvas.drawRect(
      Rect.fromLTRB(
        visibleLeft,
        _yForValue(orangeLimit.toDouble(), plotHeight),
        visibleRight,
        _yForValue(redLimit.toDouble(), plotHeight),
      ),
      Paint()..color = const Color(0xFFFFB300).withValues(alpha: zoneAlpha),
    );
    canvas.drawRect(
      Rect.fromLTRB(
        visibleLeft,
        _yForValue(safeReferenceMax.toDouble(), plotHeight),
        visibleRight,
        _yForValue(orangeLimit.toDouble(), plotHeight),
      ),
      Paint()..color = const Color(0xFF43A047).withValues(alpha: zoneAlpha),
    );

    canvas.restore();
  }

  void _paintGrid({
    required Canvas canvas,
    required double plotHeight,
    required double visibleLeft,
    required double visibleRight,
  }) {
    final dividerColor = theme.dividerColor;
    final chartStartDate = startDate;

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(visibleLeft, 0, visibleRight, plotHeight));

    for (int value = 0; value <= maxVolume; value += 50) {
      final y = _yForValue(value.toDouble(), plotHeight);
      canvas.drawLine(
        Offset(visibleLeft, y),
        Offset(visibleRight, y),
        Paint()
          ..color = dividerColor.withValues(
            alpha: value % 100 == 0 ? 0.75 : 0.35,
          )
          ..strokeWidth = value % 100 == 0 ? 1.4 : 0.8,
      );
    }
    if (maxVolume % 50 != 0) {
      final y = _yForValue(maxVolume.toDouble(), plotHeight);
      canvas.drawLine(
        Offset(visibleLeft, y),
        Offset(visibleRight, y),
        Paint()
          ..color = dividerColor.withValues(alpha: 0.75)
          ..strokeWidth = 1.4,
      );
    }

    final firstDay = math.max(0, (visibleLeft / dayWidth).floor() - 1);
    final lastDay = math.min(daySpan + 1, (visibleRight / dayWidth).ceil() + 1);

    for (int day = firstDay; day <= lastDay; day++) {
      final x = day * dayWidth;
      if (x < visibleLeft - dayWidth || x > visibleRight + dayWidth) {
        continue;
      }
      final isMonthBoundary =
          chartStartDate != null &&
          day <= daySpan &&
          chartStartDate.add(Duration(days: day)).day == 1;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, plotHeight),
        Paint()
          ..color = dividerColor.withValues(
            alpha: isMonthBoundary ? 0.52 : 0.22,
          )
          ..strokeWidth = isMonthBoundary ? 1.4 : 0.8,
      );
    }

    canvas.restore();
  }

  void _paintLine({
    required Canvas canvas,
    required double plotHeight,
    required double visibleLeft,
    required double visibleRight,
  }) {
    if (points.isEmpty) {
      return;
    }

    final logicalMinX = (visibleLeft / dayWidth) - 1;
    final logicalMaxX = (visibleRight / dayWidth) + 1;
    final startIndex = math.max(0, _lowerBound(points, logicalMinX) - 1);
    final endIndex = math.min(
      points.length,
      _upperBound(points, logicalMaxX) + 1,
    );
    if (startIndex >= endIndex) {
      return;
    }

    final path = Path();
    for (int index = startIndex; index < endIndex; index++) {
      final point = points[index];
      final offset = Offset(
        point.x * dayWidth,
        _yForValue(point.value.toDouble(), plotHeight),
      );
      if (index == startIndex) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(visibleLeft, 0, visibleRight, plotHeight));
    canvas.drawPath(
      path,
      Paint()
        ..color = theme.colorScheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    final visiblePointCount = endIndex - startIndex;
    final shouldDrawDots = visiblePointCount <= 100 && dayWidth >= 10;
    if (shouldDrawDots) {
      final dotPaint = Paint()..color = theme.colorScheme.primary;
      for (int index = startIndex; index < endIndex; index++) {
        final point = points[index];
        canvas.drawCircle(
          Offset(
            point.x * dayWidth,
            _yForValue(point.value.toDouble(), plotHeight),
          ),
          2.8,
          dotPaint,
        );
      }
    }

    canvas.restore();
  }

  void _paintSelection({
    required Canvas canvas,
    required double plotHeight,
    required double visibleLeft,
    required double visibleRight,
  }) {
    final point = selectedPoint;
    if (point == null) {
      return;
    }

    final x = point.x * dayWidth;
    if (x < visibleLeft - 1 || x > visibleRight + 1) {
      return;
    }

    final y = _yForValue(point.value.toDouble(), plotHeight);

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(visibleLeft, 0, visibleRight, plotHeight));
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, plotHeight),
      Paint()
        ..color = theme.colorScheme.primary.withValues(alpha: 0.18)
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(
      Offset(x, y),
      6,
      Paint()..color = theme.colorScheme.surface,
    );
    canvas.drawCircle(
      Offset(x, y),
      4,
      Paint()..color = theme.colorScheme.primary,
    );
    canvas.restore();
  }

  void _paintBorder({
    required Canvas canvas,
    required double plotHeight,
    required double visibleLeft,
    required double visibleRight,
    required double contentWidth,
  }) {
    final borderPaint = Paint()
      ..color = theme.dividerColor.withValues(alpha: 0.7)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(visibleLeft, 0),
      Offset(visibleRight, 0),
      borderPaint,
    );
    canvas.drawLine(
      Offset(visibleLeft, plotHeight),
      Offset(visibleRight, plotHeight),
      borderPaint,
    );

    if (contentWidth <= visibleRight + 0.5) {
      final x = contentWidth - 0.5;
      canvas.drawLine(Offset(x, 0), Offset(x, plotHeight), borderPaint);
    }
  }

  void _paintBottomLabels({
    required Canvas canvas,
    required double plotHeight,
    required double visibleLeft,
    required double visibleRight,
    required double contentWidth,
  }) {
    final chartStartDate = startDate;
    if (chartStartDate == null) {
      return;
    }

    final firstDay = math.max(0, (visibleLeft / dayWidth).floor());
    final lastDay = math.min(daySpan, (visibleRight / dayWidth).ceil());
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
      fontWeight: FontWeight.w600,
    );
    final monthLabelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.92),
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
    );
    final dividerPaint = Paint()
      ..color = theme.dividerColor.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    const dayRowHeight = 22.0;
    final monthRowTop = plotHeight + dayRowHeight;

    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(
        visibleLeft,
        plotHeight,
        visibleRight,
        plotHeight + bottomTitleReservedSize,
      ),
    );

    canvas.drawLine(
      Offset(visibleLeft, monthRowTop),
      Offset(visibleRight, monthRowTop),
      dividerPaint,
    );

    for (int day = firstDay; day <= lastDay; day++) {
      final x = day * dayWidth;
      final centerX = x + (dayWidth / 2);
      final labelDate = chartStartDate.add(Duration(days: day));
      final textPainter = TextPainter(
        text: TextSpan(text: labelDate.day.toString(), style: labelStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: dayWidth);

      final dx = (centerX - (textPainter.width / 2))
          .clamp(
            visibleLeft,
            math.max(visibleLeft, contentWidth - textPainter.width),
          )
          .toDouble();
      textPainter.paint(canvas, Offset(dx, plotHeight + 4));
    }

    int? segmentStartDay;
    DateTime? segmentDate;
    for (int day = firstDay; day <= lastDay + 1; day++) {
      if (day > lastDay) {
        if (segmentStartDay != null && segmentDate != null) {
          _paintMonthSegment(
            canvas: canvas,
            visibleLeft: visibleLeft,
            visibleRight: visibleRight,
            monthRowTop: monthRowTop,
            contentWidth: contentWidth,
            labelStyle: monthLabelStyle,
            startDay: segmentStartDay,
            endDayExclusive: day,
            monthDate: segmentDate,
          );
        }
        break;
      }

      final date = chartStartDate.add(Duration(days: day));
      final isNewMonth =
          segmentDate == null ||
          segmentDate.month != date.month ||
          segmentDate.year != date.year;
      if (isNewMonth) {
        if (segmentStartDay != null && segmentDate != null) {
          _paintMonthSegment(
            canvas: canvas,
            visibleLeft: visibleLeft,
            visibleRight: visibleRight,
            monthRowTop: monthRowTop,
            contentWidth: contentWidth,
            labelStyle: monthLabelStyle,
            startDay: segmentStartDay,
            endDayExclusive: day,
            monthDate: segmentDate,
          );
        }
        segmentStartDay = day;
        segmentDate = date;
      }
    }

    canvas.restore();
  }

  void _paintMonthSegment({
    required Canvas canvas,
    required double visibleLeft,
    required double visibleRight,
    required double monthRowTop,
    required double contentWidth,
    required TextStyle? labelStyle,
    required int startDay,
    required int endDayExclusive,
    required DateTime monthDate,
  }) {
    final left = (startDay * dayWidth)
        .clamp(visibleLeft, visibleRight)
        .toDouble();
    final right = (endDayExclusive * dayWidth)
        .clamp(visibleLeft, visibleRight)
        .toDouble();
    if (right <= left) {
      return;
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: _monthLabelDateFormat.format(monthDate),
        style: labelStyle,
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: math.max(0, right - left - 8));

    final dx = ((left + right - textPainter.width) / 2)
        .clamp(
          visibleLeft,
          math.max(visibleLeft, contentWidth - textPainter.width),
        )
        .toDouble();

    canvas.drawLine(
      Offset(left, monthRowTop),
      Offset(left, monthRowTop + (bottomTitleReservedSize - 22)),
      Paint()
        ..color = theme.dividerColor.withValues(alpha: 0.7)
        ..strokeWidth = 1,
    );
    textPainter.paint(canvas, Offset(dx, monthRowTop + 6));
  }

  double _yForValue(double value, double plotHeight) {
    if (maxVolume <= 0) {
      return plotHeight;
    }
    return plotHeight * (1 - (value / maxVolume));
  }
}

int _lowerBound(List<_ChartPoint> points, double targetX) {
  int low = 0;
  int high = points.length;
  while (low < high) {
    final mid = low + ((high - low) >> 1);
    if (points[mid].x < targetX) {
      low = mid + 1;
    } else {
      high = mid;
    }
  }
  return low.clamp(0, points.length);
}

int _upperBound(List<_ChartPoint> points, double targetX) {
  int low = 0;
  int high = points.length;
  while (low < high) {
    final mid = low + ((high - low) >> 1);
    if (points[mid].x <= targetX) {
      low = mid + 1;
    } else {
      high = mid;
    }
  }
  return low.clamp(0, points.length);
}
