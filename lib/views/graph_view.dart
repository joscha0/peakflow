import 'dart:convert';
import 'dart:math' as math;

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:peakflow/db/prefs.dart';
import 'package:peakflow/global/consts.dart';
import 'package:peakflow/l10n/l10n.dart';
import 'package:peakflow/models/day_entry_model.dart';
import 'package:peakflow/providers/day_entries_provider.dart';
import 'package:peakflow/widgets/system_gesture_exclusion_region.dart';
import 'package:peakflow/widgets/timeline_slider_parts.dart';

enum _GraphRangePreset { all, last3Months, last12Months, custom }

class GraphView extends ConsumerStatefulWidget {
  const GraphView({super.key, this.showScaffold = true});

  final bool showScaffold;

  @override
  ConsumerState<GraphView> createState() => _GraphViewState();
}

class _GraphViewState extends ConsumerState<GraphView> {
  static const double _chartRightPadding = 16;
  static const double _yAxisWidth = 42;
  static const double _yAxisGap = 0;
  static const double _bottomTitleReservedSize = 58;
  static const double _scrollbarThickness = 68;
  static const double _scrollbarTopSpacing = 8;
  static const double _dragScrollMultiplier = 1;
  static const double _minDayWidth = 18;
  static const double _maxDayWidth = 32;
  static const double _maxGraphContentWidth = 1180;
  static const double _wideChartAspectRatio = 16 / 9;
  static const double _compactChartAspectRatio = 1;
  static final intl.DateFormat _tooltipDateFormat = intl.DateFormat(
    'dd.MM.yyyy',
  );

  int maxVolume = 850;
  int colorReferenceMaxVolume = 850;
  bool isLoading = true;
  List<DayEntry> entries = const [];
  List<DayEntry> entriesFiltered = const [];
  DateTimeRange? range;
  _GraphRangePreset selectedRangePreset = _GraphRangePreset.all;
  List<_ChartPoint> chartPoints = const [];
  _ChartPoint? selectedPoint;
  bool isGeneratingPdfReport = false;
  bool isGeneratingCsvReport = false;

  final ScrollController _chartScrollController = ScrollController();

  intl.DateFormat get _rangeDateFormat =>
      intl.DateFormat.yMMMMd(Localizations.localeOf(context).toLanguageTag());

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
      selectedRangePreset = _GraphRangePreset.all;
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

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTimeRange? get _fullDataRange {
    if (entries.isEmpty) {
      return null;
    }
    return DateTimeRange(start: entries.first.date, end: entries.last.date);
  }

  DateTime _subtractMonths(DateTime date, int months) {
    final normalizedDate = _normalizeDate(date);
    final totalMonths = (normalizedDate.year * 12) + normalizedDate.month - 1;
    final targetTotalMonths = totalMonths - months;
    final targetYear = targetTotalMonths ~/ 12;
    final targetMonth = (targetTotalMonths % 12) + 1;
    final targetDay = math.min(
      normalizedDate.day,
      DateUtils.getDaysInMonth(targetYear, targetMonth),
    );
    return DateTime(targetYear, targetMonth, targetDay);
  }

  DateTimeRange? _buildTrailingMonthsRange(int months) {
    final fullRange = _fullDataRange;
    if (fullRange == null) {
      return null;
    }

    final trailingStart = _subtractMonths(fullRange.end, months);
    return DateTimeRange(
      start: trailingStart.isBefore(fullRange.start)
          ? fullRange.start
          : trailingStart,
      end: fullRange.end,
    );
  }

  void _applyRange(
    DateTimeRange nextRange, {
    required _GraphRangePreset preset,
  }) {
    final normalizedStart = _normalizeDate(nextRange.start);
    final normalizedEnd = _normalizeDate(nextRange.end);
    final safeRange = normalizedStart.isAfter(normalizedEnd)
        ? DateTimeRange(start: normalizedEnd, end: normalizedEnd)
        : DateTimeRange(start: normalizedStart, end: normalizedEnd);
    final filteredEntries = _filterEntriesForRange(entries, safeRange);

    if (filteredEntries.isEmpty) {
      return;
    }

    final chartStart = filteredEntries.first.date;

    setState(() {
      range = safeRange;
      selectedRangePreset = preset;
      entriesFiltered = filteredEntries;
      chartPoints = _buildChartPoints(filteredEntries, chartStart);
      selectedPoint = null;
    });
    _scheduleScrollToEnd();
  }

  void _selectAllRange() {
    final fullRange = _fullDataRange;
    if (fullRange == null) {
      return;
    }
    _applyRange(fullRange, preset: _GraphRangePreset.all);
  }

  void _selectTrailingMonths(int months) {
    final nextRange = _buildTrailingMonthsRange(months);
    if (nextRange == null) {
      return;
    }

    _applyRange(
      nextRange,
      preset: months == 3
          ? _GraphRangePreset.last3Months
          : _GraphRangePreset.last12Months,
    );
  }

  Future<void> _pickCustomRange() async {
    final fullRange = _fullDataRange;
    if (fullRange == null) {
      return;
    }

    final picked = await showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomRangeSheet(
        fullRange: fullRange,
        initialRange: range ?? fullRange,
        dateFormat: _rangeDateFormat,
      ),
    );

    if (picked == null) {
      return;
    }

    _applyRange(picked, preset: _GraphRangePreset.custom);
  }

  String get _activeRangeLabel {
    final activeRange = range;
    if (activeRange == null) {
      return '';
    }
    return '${_rangeDateFormat.format(activeRange.start)} - ${_rangeDateFormat.format(activeRange.end)}';
  }

  Widget _buildRangePresetChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: selected ? theme.colorScheme.onPrimary : null,
      ),
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.62,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide(
        color: selected
            ? theme.colorScheme.primary
            : theme.dividerColor.withValues(alpha: 0.4),
      ),
      onSelected: (_) => onSelected(),
    );
  }

  Widget _buildRangeControls(ThemeData theme) {
    final activeRange = range;
    if (activeRange == null) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dateRangeTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _activeRangeLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.start,
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildRangePresetChip(
                  label: l10n.rangeAll,
                  selected: selectedRangePreset == _GraphRangePreset.all,
                  onSelected: _selectAllRange,
                ),
                _buildRangePresetChip(
                  label: l10n.rangeLast3Months,
                  selected:
                      selectedRangePreset == _GraphRangePreset.last3Months,
                  onSelected: () => _selectTrailingMonths(3),
                ),

                OutlinedButton.icon(
                  onPressed: _pickCustomRange,
                  icon: const Icon(Icons.date_range_rounded, size: 18),
                  label: Text(l10n.rangeCustom),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                    backgroundColor:
                        selectedRangePreset == _GraphRangePreset.custom
                        ? theme.colorScheme.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    side: BorderSide(
                      color: selectedRangePreset == _GraphRangePreset.custom
                          ? theme.colorScheme.primary
                          : theme.dividerColor.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

  _MeasurementStats get _selectedRangeStats =>
      _MeasurementStats.fromPoints(chartPoints);

  List<_ReportDay> _selectedRangeReportDays() {
    final days = <_ReportDay>[];
    for (final entry in entriesFiltered) {
      final sortedReadings = [...entry.readings]
        ..sort((first, second) {
          final firstMinutes = (first.time.hour * 60) + first.time.minute;
          final secondMinutes = (second.time.hour * 60) + second.time.minute;
          return firstMinutes.compareTo(secondMinutes);
        });

      final readings = <_ReportReading>[
        for (final reading in sortedReadings)
          _ReportReading(
            dateTime: DateTime(
              entry.date.year,
              entry.date.month,
              entry.date.day,
              reading.time.hour,
              reading.time.minute,
            ),
            value: reading.value,
            note: reading.note,
          ),
      ];

      days.add(
        _ReportDay(
          date: entry.date,
          note: entry.note,
          symptoms: _symptomsForEntry(entry),
          readings: readings,
        ),
      );
    }
    return days;
  }

  List<String> _symptomsForEntry(DayEntry entry) {
    final values = entry.checkboxValues;
    final symptoms = <String>[
      for (final symptom in defaultCheckboxValues.keys)
        if (values[symptom] ?? false) symptom,
    ];

    for (final item in values.entries) {
      if (item.value && !symptoms.contains(item.key)) {
        symptoms.add(item.key);
      }
    }

    return symptoms;
  }

  String _reportFileName() {
    final activeRange = range;
    final formatter = intl.DateFormat('yyyyMMdd');
    if (activeRange == null) {
      return 'peakflow-report.pdf';
    }
    return 'peakflow-report-${formatter.format(activeRange.start)}-${formatter.format(activeRange.end)}.pdf';
  }

  String _csvReportFileName() {
    final activeRange = range;
    final formatter = intl.DateFormat('yyyyMMdd');
    if (activeRange == null) {
      return 'peakflow-report.csv';
    }
    return 'peakflow-report-${formatter.format(activeRange.start)}-${formatter.format(activeRange.end)}.csv';
  }

  void _showReportMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  List<List<String>> _dayEntryToCsvRows(DayEntry entry) {
    final rows = <List<String>>[];
    final date = entry.date.toIso8601String().split('T').first;
    final symptoms = _symptomsForEntry(
      entry,
    ).map(context.l10n.symptomLabel).join(', ');
    final sortedReadings = [...entry.readings]
      ..sort((first, second) {
        final firstMinutes = (first.time.hour * 60) + first.time.minute;
        final secondMinutes = (second.time.hour * 60) + second.time.minute;
        return firstMinutes.compareTo(secondMinutes);
      });

    for (final reading in sortedReadings) {
      rows.add([
        date,
        '${reading.time.hour.toString().padLeft(2, '0')}:${reading.time.minute.toString().padLeft(2, '0')}',
        reading.value.toString(),
        reading.note,
        entry.note,
        symptoms,
      ]);
    }

    return rows;
  }

  String _buildSelectedRangeCsv() {
    final rows = <List<String>>[
      [
        context.l10n.dateLabel,
        context.l10n.timeLabel,
        context.l10n.reportValue,
        context.l10n.reportReadingNote,
        context.l10n.dayNotesLabel,
        context.l10n.symptomsTitle,
      ],
    ];

    for (final entry in entriesFiltered) {
      rows.addAll(_dayEntryToCsvRows(entry));
    }

    return const ListToCsvConverter().convert(rows);
  }

  Future<void> _generatePdfReport(int effectiveColorReferenceMaxVolume) async {
    if (isGeneratingPdfReport) {
      return;
    }

    setState(() {
      isGeneratingPdfReport = true;
    });

    final l10n = context.l10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    try {
      final report = _PeakFlowPdfReport(
        rangeLabel: _activeRangeLabel,
        days: _selectedRangeReportDays(),
        maxVolume: maxVolume,
        referenceMaxVolume: effectiveColorReferenceMaxVolume,
        l10n: l10n,
        localeName: localeName,
      );
      final bytes = await report.build();
      final outputPath = await FilePicker.saveFile(
        dialogTitle: l10n.savePdfReportDialogTitle,
        fileName: _reportFileName(),
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        bytes: bytes,
      );

      if (!mounted) {
        return;
      }

      if (outputPath != null || kIsWeb) {
        _showReportMessage(
          kIsWeb ? l10n.pdfReportDownloadStarted : l10n.pdfReportSaved,
        );
      }
    } catch (_) {
      if (mounted) {
        _showReportMessage(l10n.pdfReportGenerateFailed);
      }
    } finally {
      if (mounted) {
        setState(() {
          isGeneratingPdfReport = false;
        });
      }
    }
  }

  Future<void> _generateCsvReport() async {
    if (isGeneratingCsvReport) {
      return;
    }

    setState(() {
      isGeneratingCsvReport = true;
    });

    final l10n = context.l10n;
    try {
      final csv = _buildSelectedRangeCsv();
      final outputPath = await FilePicker.saveFile(
        dialogTitle: l10n.saveCsvReportDialogTitle,
        fileName: _csvReportFileName(),
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        bytes: Uint8List.fromList(utf8.encode(csv)),
      );

      if (!mounted) {
        return;
      }

      if (outputPath != null || kIsWeb) {
        _showReportMessage(
          kIsWeb ? l10n.csvReportDownloadStarted : l10n.csvReportSaved,
        );
      }
    } catch (_) {
      if (mounted) {
        _showReportMessage(l10n.csvReportGenerateFailed);
      }
    } finally {
      if (mounted) {
        setState(() {
          isGeneratingCsvReport = false;
        });
      }
    }
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

  double _chartAspectRatioForWidth(double width) {
    return width >= 720 ? _wideChartAspectRatio : _compactChartAspectRatio;
  }

  Widget _buildGraphContentFrame({required Widget child}) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxGraphContentWidth),
        child: child,
      ),
    );
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

  Widget _buildSelectedRangeStats(ThemeData theme) {
    final stats = _selectedRangeStats;
    final l10n = context.l10n;
    final hasMeasurements = stats.count > 0;
    final items = [
      _StatTileData(
        label: l10n.statAverage,
        value: hasMeasurements ? stats.average.round().toString() : '-',
        unit: hasMeasurements ? 'L/min' : null,
      ),
      _StatTileData(
        label: l10n.statHighest,
        value: hasMeasurements ? stats.highest.toString() : '-',
        unit: hasMeasurements ? 'L/min' : null,
      ),
      _StatTileData(
        label: l10n.statLowest,
        value: hasMeasurements ? stats.lowest.toString() : '-',
        unit: hasMeasurements ? 'L/min' : null,
      ),
      _StatTileData(
        label: l10n.statMeasurements,
        value: stats.count.toString(),
        unit: l10n.timesUnit,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 8.0;
          final columns = constraints.maxWidth >= 620
              ? 4
              : constraints.maxWidth >= 280
              ? 2
              : 1;
          final tileWidth =
              (constraints.maxWidth - (spacing * (columns - 1))) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final item in items)
                SizedBox(width: tileWidth, child: _buildStatTile(theme, item)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReportSection(
    ThemeData theme,
    int effectiveColorReferenceMaxVolume,
  ) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.reportsTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.exportReportFor(_activeRangeLabel),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.64),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 520;
              final pdfButton = FilledButton.icon(
                onPressed: chartPoints.isEmpty || isGeneratingPdfReport
                    ? null
                    : () =>
                          _generatePdfReport(effectiveColorReferenceMaxVolume),
                icon: isGeneratingPdfReport
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded),
                label: Text(
                  isGeneratingPdfReport ? l10n.generatingPdf : l10n.pdfReport,
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
              final csvButton = OutlinedButton.icon(
                onPressed: chartPoints.isEmpty || isGeneratingCsvReport
                    ? null
                    : _generateCsvReport,
                icon: isGeneratingCsvReport
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : const Icon(Icons.table_chart_outlined),
                label: Text(
                  isGeneratingCsvReport ? l10n.generatingCsv : l10n.csvReport,
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: pdfButton),
                    const SizedBox(width: 12),
                    Expanded(child: csvButton),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [pdfButton, const SizedBox(height: 10), csvButton],
              );
            },
          ),
          SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatTile(ThemeData theme, _StatTileData item) {
    final valueStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
    );
    final unitStyle = valueStyle?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
      fontWeight: FontWeight.w700,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                text: item.value,
                children: [
                  if (item.unit != null)
                    TextSpan(text: ' ${item.unit}', style: unitStyle),
                ],
              ),
              maxLines: 1,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedYAxis(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartHeight = math.max(
          0.0,
          constraints.maxHeight -
              _bottomTitleReservedSize -
              _scrollbarTopSpacing -
              _scrollbarThickness,
        );
        final labelStyle = theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
          fontWeight: FontWeight.w600,
        );
        final dividerColor = theme.dividerColor.withValues(alpha: 0.7);

        return Column(
          children: [
            SizedBox(
              height: chartHeight,
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
            const SizedBox(
              height:
                  _bottomTitleReservedSize +
                  _scrollbarTopSpacing +
                  _scrollbarThickness,
            ),
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
    final effectiveColorReferenceMaxVolume = ref
        .watch(colorReferenceMaxValueProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => colorReferenceMaxVolume,
        );

    final body = isLoading
        ? const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(),
            ),
          )
        : entries.isEmpty
        ? Center(child: Text(context.l10n.noDataAvailable))
        : range == null
        ? const SizedBox.shrink()
        : Column(
            children: [
              _buildGraphContentFrame(child: _buildRangeControls(theme)),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildGraphContentFrame(
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: _chartAspectRatioForWidth(
                            MediaQuery.sizeOf(context).width,
                          ),
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
                                  constraints.maxWidth -
                                      _yAxisWidth -
                                      _yAxisGap,
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
                                final dayWidth = _resolveDayWidth(
                                  plotViewportWidth,
                                );
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
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    child: SizedBox(
                                                      width: chartWidth,
                                                      height: chartAreaHeight,
                                                      child: CustomPaint(
                                                        painter: _PeakFlowChartPainter(
                                                          theme: theme,
                                                          points: chartPoints,
                                                          selectedPoint:
                                                              selectedPoint,
                                                          startDate:
                                                              _chartStartDate,
                                                          daySpan:
                                                              _chartDaySpan,
                                                          maxVolume: maxVolume,
                                                          colorReferenceMaxVolume:
                                                              effectiveColorReferenceMaxVolume,
                                                          dayWidth: dayWidth,
                                                          chartRightPadding:
                                                              _chartRightPadding,
                                                          bottomTitleReservedSize:
                                                              _bottomTitleReservedSize,
                                                          viewportWidth:
                                                              plotViewportWidth,
                                                          scrollController:
                                                              _chartScrollController,
                                                          stableLabel: context
                                                              .l10n
                                                              .zoneStable,
                                                          cautionLabel: context
                                                              .l10n
                                                              .zoneCaution,
                                                          actionNeededLabel: context
                                                              .l10n
                                                              .zoneActionNeeded,
                                                          localeName:
                                                              Localizations.localeOf(
                                                                context,
                                                              ).toLanguageTag(),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Positioned.fill(
                                                  child: GestureDetector(
                                                    behavior:
                                                        HitTestBehavior.opaque,
                                                    onTapDown: (details) =>
                                                        _selectPointAtPosition(
                                                          localPosition: details
                                                              .localPosition,
                                                          chartHeight:
                                                              chartHeight,
                                                          dayWidth: dayWidth,
                                                        ),
                                                    onHorizontalDragUpdate:
                                                        (details) =>
                                                            _dragChartBy(
                                                              details.delta.dx,
                                                            ),
                                                  ),
                                                ),
                                                _buildTooltipOverlay(
                                                  theme: theme,
                                                  viewportWidth:
                                                      plotViewportWidth,
                                                  chartHeight: chartHeight,
                                                  dayWidth: dayWidth,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(
                                            height: _scrollbarTopSpacing,
                                          ),
                                          _ChartTimelineSlider(
                                            controller: _chartScrollController,
                                            thickness: _scrollbarThickness,
                                            startDate: _chartStartDate,
                                            endDate: _chartEndDate,
                                            dayWidth: dayWidth,
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
                        _buildSelectedRangeStats(theme),
                        _buildReportSection(
                          theme,
                          effectiveColorReferenceMaxVolume,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );

    if (!widget.showScaffold) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.dataScreenTitle)),
      body: body,
    );
  }
}

class _CustomRangeSheet extends StatefulWidget {
  const _CustomRangeSheet({
    required this.fullRange,
    required this.initialRange,
    required this.dateFormat,
  });

  final DateTimeRange fullRange;
  final DateTimeRange initialRange;
  final intl.DateFormat dateFormat;

  @override
  State<_CustomRangeSheet> createState() => _CustomRangeSheetState();
}

class _CustomRangeSheetState extends State<_CustomRangeSheet> {
  late DateTime start;
  late DateTime end;
  bool isEditingStart = true;

  @override
  void initState() {
    super.initState();
    start = _normalizeDate(widget.initialRange.start);
    end = _normalizeDate(widget.initialRange.end);
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  void _selectBoundary(bool editingStart) {
    setState(() {
      isEditingStart = editingStart;
    });
  }

  void _onDateChanged(DateTime value) {
    final normalizedValue = _normalizeDate(value);
    setState(() {
      if (isEditingStart) {
        start = normalizedValue;
        if (start.isAfter(end)) {
          end = start;
        }
      } else {
        end = normalizedValue;
        if (end.isBefore(start)) {
          start = end;
        }
      }
    });
  }

  Widget _buildBoundaryButton({
    required ThemeData theme,
    required String label,
    required DateTime value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.14)
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.52,
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.dividerColor.withValues(alpha: 0.45),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.dateFormat.format(value),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: selected ? theme.colorScheme.primary : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeDate = isEditingStart ? start : end;
    final bottomSafeArea = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottomSafeArea),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.customRangeTitle,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.customRangeDescription,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildBoundaryButton(
                    theme: theme,
                    label: context.l10n.startLabel,
                    value: start,
                    selected: isEditingStart,
                    onTap: () => _selectBoundary(true),
                  ),
                  const SizedBox(width: 10),
                  _buildBoundaryButton(
                    theme: theme,
                    label: context.l10n.endLabel,
                    value: end,
                    selected: !isEditingStart,
                    onTap: () => _selectBoundary(false),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: ColoredBox(
                  color: theme.colorScheme.surfaceContainerLowest,
                  child: CalendarDatePicker(
                    key: ValueKey(
                      '${isEditingStart ? 'start' : 'end'}-${activeDate.toIso8601String()}',
                    ),
                    initialDate: activeDate,
                    firstDate: widget.fullRange.start,
                    lastDate: widget.fullRange.end,
                    currentDate: activeDate,
                    onDateChanged: _onDateChanged,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(context.l10n.cancel),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pop(DateTimeRange(start: start, end: end));
                    },
                    child: Text(context.l10n.apply),
                  ),
                ],
              ),
            ],
          ),
        ),
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

class _ReportReading {
  const _ReportReading({
    required this.dateTime,
    required this.value,
    required this.note,
  });

  final DateTime dateTime;
  final int value;
  final String note;
}

class _ReportDay {
  const _ReportDay({
    required this.date,
    required this.note,
    required this.symptoms,
    required this.readings,
  });

  final DateTime date;
  final String note;
  final List<String> symptoms;
  final List<_ReportReading> readings;
}

class _ReportMonth {
  const _ReportMonth({required this.month, required this.days});

  final DateTime month;
  final List<_ReportDay> days;

  List<_ReportReading> get readings => [
    for (final day in days) ...day.readings,
  ];
}

enum _PeakFlowZone { stable, caution, actionNeeded }

class _ZoneTotals {
  const _ZoneTotals({
    required this.stable,
    required this.caution,
    required this.actionNeeded,
    required this.actionNeededReadings,
  });

  final int stable;
  final int caution;
  final int actionNeeded;
  final List<_ReportReading> actionNeededReadings;
}

class _PeakFlowPdfReport {
  _PeakFlowPdfReport({
    required this.rangeLabel,
    required this.days,
    required this.maxVolume,
    required this.referenceMaxVolume,
    required this.l10n,
    required this.localeName,
  });

  final String rangeLabel;
  final List<_ReportDay> days;
  final int maxVolume;
  final int referenceMaxVolume;
  final AppLocalizations l10n;
  final String localeName;

  intl.DateFormat get _dateFormat => intl.DateFormat.yMMMd(localeName);
  intl.DateFormat get _dateTimeFormat =>
      intl.DateFormat.yMMMd(localeName).add_Hm();
  intl.DateFormat get _timeFormat => intl.DateFormat.Hm(localeName);
  intl.DateFormat get _generatedFormat =>
      intl.DateFormat.yMMMd(localeName).add_Hm();
  intl.DateFormat get _monthFormat => intl.DateFormat.yMMMM(localeName);

  List<_ReportReading> get readings => [
    for (final day in days) ...day.readings,
  ];

  Future<Uint8List> build() async {
    final document = pw.Document();
    final zoneTotals = _buildZoneTotals();
    final stats = _statsFromReadings(readings);
    final months = _buildMonths();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            l10n.reportPageOf(context.pageNumber, context.pagesCount),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          pw.Text(
            l10n.peakFlowReportTitle,
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(l10n.reportRange(rangeLabel)),
          pw.Text(
            l10n.reportGenerated(_generatedFormat.format(DateTime.now())),
          ),
          pw.SizedBox(height: 16),
          _sectionTitle(l10n.reportStats),
          _keyValueGrid([
            (
              l10n.reportAverage,
              stats.count == 0 ? '-' : '${stats.average.round()} L/min',
            ),
            (
              l10n.statHighest,
              stats.count == 0 ? '-' : '${stats.highest} L/min',
            ),
            (l10n.statLowest, stats.count == 0 ? '-' : '${stats.lowest} L/min'),
            (l10n.readingsTitle, stats.count.toString()),
          ]),
          pw.SizedBox(height: 12),
          _sectionTitle(l10n.reportReadingsByZone),
          _keyValueGrid([
            (l10n.zoneStable, zoneTotals.stable.toString()),
            (l10n.zoneCaution, zoneTotals.caution.toString()),
            (l10n.zoneActionNeeded, zoneTotals.actionNeeded.toString()),
            (l10n.reportReferenceMax, '$referenceMaxVolume L/min'),
          ]),
          pw.SizedBox(height: 10),
          _sectionTitle(l10n.reportActionNeededDates),
          if (zoneTotals.actionNeededReadings.isEmpty)
            pw.Text(l10n.reportNoActionNeeded)
          else
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (final reading in zoneTotals.actionNeededReadings)
                  pw.Text(
                    '${_dateTimeFormat.format(reading.dateTime)} - ${reading.value} L/min',
                  ),
              ],
            ),
          pw.SizedBox(height: 18),
          if (months.isEmpty)
            pw.Text(l10n.reportNoSavedReadingsRange)
          else
            for (final month in months) ..._buildMonthSection(month),
        ],
      ),
    );

    return document.save();
  }

  _MeasurementStats _statsFromReadings(List<_ReportReading> sourceReadings) {
    if (sourceReadings.isEmpty) {
      return const _MeasurementStats(
        count: 0,
        average: 0,
        highest: 0,
        lowest: 0,
      );
    }

    var total = 0;
    var highest = sourceReadings.first.value;
    var lowest = sourceReadings.first.value;
    for (final reading in sourceReadings) {
      total += reading.value;
      highest = math.max(highest, reading.value);
      lowest = math.min(lowest, reading.value);
    }

    return _MeasurementStats(
      count: sourceReadings.length,
      average: total / sourceReadings.length,
      highest: highest,
      lowest: lowest,
    );
  }

  List<_ReportMonth> _buildMonths() {
    final grouped = <DateTime, List<_ReportDay>>{};
    for (final day in days) {
      final month = DateTime(day.date.year, day.date.month);
      grouped.putIfAbsent(month, () => <_ReportDay>[]).add(day);
    }

    final months = grouped.entries
        .map(
          (entry) => _ReportMonth(
            month: entry.key,
            days: entry.value
              ..sort((first, second) => first.date.compareTo(second.date)),
          ),
        )
        .toList();
    months.sort((first, second) => first.month.compareTo(second.month));
    return months;
  }

  _ZoneTotals _buildZoneTotals() {
    var stable = 0;
    var caution = 0;
    final actionNeededReadings = <_ReportReading>[];

    for (final reading in readings) {
      switch (_zoneForValue(reading.value)) {
        case _PeakFlowZone.stable:
          stable++;
        case _PeakFlowZone.caution:
          caution++;
        case _PeakFlowZone.actionNeeded:
          actionNeededReadings.add(reading);
      }
    }

    return _ZoneTotals(
      stable: stable,
      caution: caution,
      actionNeeded: actionNeededReadings.length,
      actionNeededReadings: actionNeededReadings,
    );
  }

  _PeakFlowZone _zoneForValue(int value) {
    final safeReference = math.max(1, referenceMaxVolume);
    if (value < safeReference * 0.5) {
      return _PeakFlowZone.actionNeeded;
    }
    if (value < safeReference * 0.8) {
      return _PeakFlowZone.caution;
    }
    return _PeakFlowZone.stable;
  }

  String _zoneLabel(int value) {
    switch (_zoneForValue(value)) {
      case _PeakFlowZone.stable:
        return l10n.zoneStable;
      case _PeakFlowZone.caution:
        return l10n.zoneCaution;
      case _PeakFlowZone.actionNeeded:
        return l10n.zoneActionNeeded;
    }
  }

  List<pw.Widget> _buildMonthSection(_ReportMonth month) {
    final monthReadings = month.readings;
    return [
      pw.NewPage(),
      pw.Text(
        _monthFormat.format(month.month),
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 8),
      _buildMonthGraph(month),
      pw.SizedBox(height: 12),
      if (monthReadings.isEmpty)
        pw.Text(l10n.reportNoSavedReadingsMonth)
      else
        for (final day in month.days) _buildDayDetails(day),
      pw.SizedBox(height: 12),
    ];
  }

  pw.Widget _buildMonthGraph(_ReportMonth month) {
    final monthReadings = month.readings;
    if (monthReadings.isEmpty) {
      return _emptyGraphBox(l10n.reportNoGraphReadingsMonth);
    }

    final daysInMonth = DateTime(
      month.month.year,
      month.month.month + 1,
      0,
    ).day;
    final chartEndDay = daysInMonth + 1.0;
    final safeMaxVolume = math.max(1, maxVolume).toDouble();
    final safeReference = referenceMaxVolume.clamp(1, maxVolume).toDouble();
    final redLimit = safeReference * 0.5;
    final orangeLimit = safeReference * 0.8;
    final data = monthReadings.map((reading) {
      final x =
          reading.dateTime.day +
          (((reading.dateTime.hour * 60) + reading.dateTime.minute) / 1440);
      return pw.PointChartValue(x.toDouble(), reading.value.toDouble());
    }).toList();

    final xAxisValues = <double>[
      for (var day = 1; day <= daysInMonth + 1; day++) day.toDouble(),
    ];
    final yAxisValues = <double>[
      for (var index = 0; index <= 4; index++) (safeMaxVolume / 4) * index,
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          height: 190,
          child: pw.Chart(
            grid: pw.CartesianGrid(
              xAxis: pw.FixedAxis<double>(
                xAxisValues,
                divisions: true,
                divisionsColor: PdfColors.grey300,
                divisionsWidth: 0.25,
                textStyle: const pw.TextStyle(
                  fontSize: 5.5,
                  color: PdfColor(1, 1, 1, 0),
                ),
                angle: -math.pi / 2,
                format: (value) => value > daysInMonth
                    ? ''
                    : value.round().toString().padLeft(2, '0'),
              ),
              yAxis: pw.FixedAxis<double>(
                yAxisValues,
                divisions: true,
                divisionsColor: PdfColors.grey400,
                textStyle: const pw.TextStyle(fontSize: 8),
                format: (value) => value.round().toString(),
              ),
            ),
            datasets: [
              _ZoneBandDataSet(
                minX: 1,
                maxX: chartEndDay,
                stableLimit: safeReference,
                redLimit: redLimit,
                orangeLimit: orangeLimit,
              ),
              _CenteredDayLabelDataSet(daysInMonth: daysInMonth),
              pw.LineDataSet(
                data: [
                  pw.PointChartValue(1, redLimit),
                  pw.PointChartValue(chartEndDay, redLimit),
                ],
                color: PdfColors.red700,
                lineWidth: 0.8,
                drawPoints: false,
              ),
              pw.LineDataSet(
                data: [
                  pw.PointChartValue(1, orangeLimit),
                  pw.PointChartValue(chartEndDay, orangeLimit),
                ],
                color: PdfColors.amber800,
                lineWidth: 0.8,
                drawPoints: false,
              ),
              pw.LineDataSet(
                data: data,
                color: PdfColors.blue700,
                lineWidth: 1.8,
                pointSize: 2.6,
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          l10n.reportXAxisDescription,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
      ],
    );
  }

  pw.Widget _emptyGraphBox(String message) {
    return pw.Container(
      height: 120,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey500),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        message,
        style: const pw.TextStyle(color: PdfColors.grey700),
      ),
    );
  }

  pw.Widget _buildDayDetails(_ReportDay day) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _dateFormat.format(day.date),
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            l10n.reportDayNote(day.note.trim().isEmpty ? '-' : day.note.trim()),
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            l10n.reportSymptoms(
              day.symptoms.isEmpty
                  ? '-'
                  : day.symptoms.map(l10n.symptomLabel).join(', '),
            ),
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 6),
          if (day.readings.isEmpty)
            pw.Text(
              l10n.reportNoReadingsDay,
              style: const pw.TextStyle(fontSize: 9),
            )
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.topLeft,
              columnWidths: const {
                0: pw.FixedColumnWidth(48),
                1: pw.FixedColumnWidth(52),
                2: pw.FixedColumnWidth(82),
                3: pw.FlexColumnWidth(),
              },
              headers: [
                l10n.reportTime,
                l10n.reportValue,
                l10n.reportZone,
                l10n.reportReadingNote,
              ],
              data: [
                for (final reading in day.readings)
                  [
                    _timeFormat.format(reading.dateTime),
                    '${reading.value} L/min',
                    _zoneLabel(reading.value),
                    reading.note.trim().isEmpty ? '-' : reading.note.trim(),
                  ],
              ],
            ),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
    );
  }

  pw.Widget _keyValueGrid(List<(String, String)> items) {
    return pw.Wrap(
      spacing: 10,
      runSpacing: 6,
      children: [
        for (final item in items)
          pw.Container(
            width: 240,
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: '${item.$1}: ',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.TextSpan(text: item.$2),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ZoneBandDataSet extends pw.Dataset {
  _ZoneBandDataSet({
    required this.minX,
    required this.maxX,
    required this.stableLimit,
    required this.redLimit,
    required this.orangeLimit,
  });

  final double minX;
  final double maxX;
  final double stableLimit;
  final double redLimit;
  final double orangeLimit;

  @override
  void layout(
    pw.Context context,
    pw.BoxConstraints constraints, {
    bool parentUsesSize = false,
  }) {
    box = PdfRect.fromPoints(PdfPoint.zero, constraints.biggest);
  }

  @override
  void paintBackground(pw.Context context) {
    final grid = pw.Chart.of(context).grid;
    final left = grid.toChart(PdfPoint(minX, 0)).x;
    final right = grid.toChart(PdfPoint(maxX, 0)).x;
    final bottom = grid.toChart(PdfPoint(minX, 0)).y;
    final redTop = grid.toChart(PdfPoint(minX, redLimit)).y;
    final orangeTop = grid.toChart(PdfPoint(minX, orangeLimit)).y;
    final stableTop = grid.toChart(PdfPoint(minX, stableLimit)).y;
    final width = right - left;

    void fillBand(double y, double height, PdfColor color) {
      if (width <= 0 || height <= 0) {
        return;
      }

      context.canvas
        ..setFillColor(color)
        ..drawRect(left, y, width, height)
        ..fillPath();
    }

    fillBand(bottom, redTop - bottom, PdfColors.deepOrange100);
    fillBand(redTop, orangeTop - redTop, PdfColors.amber100);
    fillBand(orangeTop, stableTop - orangeTop, PdfColors.green100);
  }
}

class _CenteredDayLabelDataSet extends pw.Dataset {
  _CenteredDayLabelDataSet({required this.daysInMonth});

  final int daysInMonth;

  @override
  void layout(
    pw.Context context,
    pw.BoxConstraints constraints, {
    bool parentUsesSize = false,
  }) {
    box = PdfRect.fromPoints(PdfPoint.zero, constraints.biggest);
  }

  @override
  void paintForeground(pw.Context context) {
    final grid = pw.Chart.of(context).grid;

    for (var day = 1; day <= daysInMonth; day++) {
      final point = grid.toChart(PdfPoint(day + 0.5, 0));
      pw.Widget.draw(
        pw.Transform.rotateBox(
          angle: -math.pi / 2,
          child: pw.Text(
            day.toString(),
            style: const pw.TextStyle(fontSize: 5.5, color: PdfColors.grey700),
          ),
        ),
        offset: PdfPoint(point.x, point.y - 4),
        alignment: pw.Alignment.topCenter,
        context: context,
      );
    }
  }
}

class _MeasurementStats {
  const _MeasurementStats({
    required this.count,
    required this.average,
    required this.highest,
    required this.lowest,
  });

  factory _MeasurementStats.fromPoints(List<_ChartPoint> points) {
    if (points.isEmpty) {
      return const _MeasurementStats(
        count: 0,
        average: 0,
        highest: 0,
        lowest: 0,
      );
    }

    var total = 0;
    var highest = points.first.value;
    var lowest = points.first.value;

    for (final point in points) {
      total += point.value;
      highest = math.max(highest, point.value);
      lowest = math.min(lowest, point.value);
    }

    return _MeasurementStats(
      count: points.length,
      average: total / points.length,
      highest: highest,
      lowest: lowest,
    );
  }

  final int count;
  final double average;
  final int highest;
  final int lowest;
}

class _StatTileData {
  const _StatTileData({required this.label, required this.value, this.unit});

  final String label;
  final String value;
  final String? unit;
}

class _ChartTimelineSlider extends StatefulWidget {
  const _ChartTimelineSlider({
    required this.controller,
    required this.thickness,
    required this.startDate,
    required this.endDate,
    required this.dayWidth,
  });

  final ScrollController controller;
  final double thickness;
  final DateTime? startDate;
  final DateTime? endDate;
  final double dayWidth;

  @override
  State<_ChartTimelineSlider> createState() => _ChartTimelineSliderState();
}

class _ChartTimelineSliderState extends State<_ChartTimelineSlider> {
  static const double _handleWidth = 12;
  static const double _handleHeight = 44;
  static const double _trackHeight = 2;
  static const double _labelWidth = 48;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return SystemGestureExclusionRegion(
      child: SizedBox(
        height: widget.thickness,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: widget.controller,
              builder: (context, child) {
                if (!widget.controller.hasClients ||
                    widget.controller.position.maxScrollExtent <= 0) {
                  return const SizedBox.shrink();
                }

                final maxScrollExtent =
                    widget.controller.position.maxScrollExtent;
                final trackWidth = math.max(
                  0.0,
                  constraints.maxWidth - _handleWidth,
                );
                final scrollFraction = maxScrollExtent <= 0 || trackWidth == 0
                    ? 0.0
                    : (widget.controller.offset / maxScrollExtent)
                          .clamp(0.0, 1.0)
                          .toDouble();
                final handleLeft = trackWidth * scrollFraction;
                final markers = _visibleMarkers(
                  markers: _buildMarkers(maxScrollExtent, localeName),
                  trackWidth: trackWidth,
                );

                void jumpToTrackPosition(double localDx) {
                  if (trackWidth == 0) {
                    return;
                  }
                  final nextHandleLeft = (localDx - (_handleWidth / 2))
                      .clamp(0.0, trackWidth)
                      .toDouble();
                  final nextOffset =
                      (nextHandleLeft / trackWidth) * maxScrollExtent;
                  widget.controller.jumpTo(
                    nextOffset.clamp(0.0, maxScrollExtent),
                  );
                }

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) =>
                      jumpToTrackPosition(details.localPosition.dx),
                  onHorizontalDragStart: (details) {
                    setState(() => _isDragging = true);
                    jumpToTrackPosition(details.localPosition.dx);
                  },
                  onHorizontalDragUpdate: (details) =>
                      jumpToTrackPosition(details.localPosition.dx),
                  onHorizontalDragEnd: (_) =>
                      setState(() => _isDragging = false),
                  onHorizontalDragCancel: () =>
                      setState(() => _isDragging = false),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: _handleWidth / 2,
                        right: _handleWidth / 2,
                        top: (_handleHeight - _trackHeight) / 2,
                        height: _trackHeight,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: _isDragging ? 0.28 : 0.16,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      for (final marker in markers)
                        _ChartTimelineMarkerLabel(
                          marker: marker,
                          trackWidth: trackWidth,
                          labelWidth: _labelWidth,
                          isActive:
                              (marker.fraction - scrollFraction).abs() < 0.04,
                        ),
                      Positioned(
                        left: handleLeft,
                        top: 0,
                        child: TimelineSliderHandle(
                          key: const ValueKey('graphTimelineHandle'),
                          isDragging: _isDragging,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<_ChartTimelineMarker> _buildMarkers(
    double maxScrollExtent,
    String localeName,
  ) {
    final startDate = widget.startDate;
    final endDate = widget.endDate;
    if (startDate == null || endDate == null || maxScrollExtent <= 0) {
      return const [];
    }

    final normalizedStart = _normalizeDate(startDate);
    final normalizedEnd = _normalizeDate(endDate);
    final showMonths = _monthSpan(normalizedStart, normalizedEnd) < 24;
    final markers = <_ChartTimelineMarker>[];

    if (showMonths) {
      var month = DateTime(normalizedStart.year, normalizedStart.month);
      while (!month.isAfter(normalizedEnd)) {
        markers.add(
          _ChartTimelineMarker(
            label: intl.DateFormat.MMM(localeName).format(month),
            fraction: _fractionForDate(
              month,
              normalizedStart,
              normalizedEnd,
              maxScrollExtent,
            ),
          ),
        );
        month = DateTime(month.year, month.month + 1);
      }
      return markers;
    }

    for (int year = normalizedStart.year; year <= normalizedEnd.year; year++) {
      final yearStart = DateTime(year);
      markers.add(
        _ChartTimelineMarker(
          label: year.toString(),
          fraction: _fractionForDate(
            yearStart,
            normalizedStart,
            normalizedEnd,
            maxScrollExtent,
          ),
        ),
      );
    }

    return markers;
  }

  List<_ChartTimelineMarker> _visibleMarkers({
    required List<_ChartTimelineMarker> markers,
    required double trackWidth,
  }) {
    if (markers.length <= 1) {
      return markers;
    }

    final minSpacing = _usesMonthMarkers ? 38.0 : 48.0;
    final visible = <_ChartTimelineMarker>[];
    double? previousCenter;

    for (final marker in markers) {
      final center = marker.fraction * trackWidth;
      if (previousCenter != null && center - previousCenter < minSpacing) {
        continue;
      }
      visible.add(marker);
      previousCenter = center;
    }

    return visible;
  }

  bool get _usesMonthMarkers {
    final startDate = widget.startDate;
    final endDate = widget.endDate;
    if (startDate == null || endDate == null) {
      return false;
    }
    return _monthSpan(_normalizeDate(startDate), _normalizeDate(endDate)) < 24;
  }

  double _fractionForDate(
    DateTime date,
    DateTime start,
    DateTime end,
    double maxScrollExtent,
  ) {
    final clampedDate = date.isBefore(start)
        ? start
        : (date.isAfter(end) ? end : date);
    final dayOffset = _daysBetween(start, clampedDate);
    final scrollOffset = math.min(maxScrollExtent, dayOffset * widget.dayWidth);
    return maxScrollExtent == 0 ? 0 : scrollOffset / maxScrollExtent;
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  int _daysBetween(DateTime from, DateTime to) {
    return (to.difference(from).inHours / 24).round();
  }

  int _monthSpan(DateTime start, DateTime end) {
    return ((end.year - start.year) * 12) + end.month - start.month;
  }
}

class _ChartTimelineMarker {
  const _ChartTimelineMarker({required this.label, required this.fraction});

  final String label;
  final double fraction;
}

class _ChartTimelineMarkerLabel extends StatelessWidget {
  const _ChartTimelineMarkerLabel({
    required this.marker,
    required this.trackWidth,
    required this.labelWidth,
    required this.isActive,
  });

  final _ChartTimelineMarker marker;
  final double trackWidth;
  final double labelWidth;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final center = (marker.fraction * trackWidth) + 6;
    final left = (center - (labelWidth / 2))
        .clamp(0.0, math.max(0.0, trackWidth + 12 - labelWidth))
        .toDouble();
    final color = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.62);

    return Positioned(
      left: left,
      top: 46,
      width: labelWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 1,
            height: 5,
            margin: const EdgeInsets.only(bottom: 2),
            color: color.withValues(alpha: isActive ? 0.75 : 0.36),
          ),
          Text(
            marker.label,
            maxLines: 1,
            overflow: TextOverflow.visible,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
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
    required this.stableLabel,
    required this.cautionLabel,
    required this.actionNeededLabel,
    required this.localeName,
  }) : super(repaint: scrollController);

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
  final String stableLabel;
  final String cautionLabel;
  final String actionNeededLabel;
  final String localeName;

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
    _paintAverageLine(
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
    _paintZoneLabels(
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
        oldDelegate.scrollController != scrollController ||
        oldDelegate.stableLabel != stableLabel ||
        oldDelegate.cautionLabel != cautionLabel ||
        oldDelegate.actionNeededLabel != actionNeededLabel ||
        oldDelegate.localeName != localeName;
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

  void _paintZoneLabels({
    required Canvas canvas,
    required double plotHeight,
    required double visibleLeft,
    required double visibleRight,
  }) {
    final safeReferenceMax = colorReferenceMaxVolume.clamp(1, maxVolume);
    final redLimit = safeReferenceMax * 0.5;
    final orangeLimit = safeReferenceMax * 0.8;

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(visibleLeft, 0, visibleRight, plotHeight));

    _paintZoneLabel(
      canvas: canvas,
      label: stableLabel,
      color: const Color(0xFF43A047),
      top: _yForValue(safeReferenceMax.toDouble(), plotHeight),
      bottom: _yForValue(orangeLimit.toDouble(), plotHeight),
      visibleLeft: visibleLeft,
      visibleRight: visibleRight,
    );
    _paintZoneLabel(
      canvas: canvas,
      label: cautionLabel,
      color: const Color(0xFFFFB300),
      top: _yForValue(orangeLimit.toDouble(), plotHeight),
      bottom: _yForValue(redLimit.toDouble(), plotHeight),
      visibleLeft: visibleLeft,
      visibleRight: visibleRight,
    );
    _paintZoneLabel(
      canvas: canvas,
      label: actionNeededLabel,
      color: const Color(0xFFE53935),
      top: _yForValue(redLimit.toDouble(), plotHeight),
      bottom: plotHeight,
      visibleLeft: visibleLeft,
      visibleRight: visibleRight,
    );

    canvas.restore();
  }

  void _paintZoneLabel({
    required Canvas canvas,
    required String label,
    required Color color,
    required double top,
    required double bottom,
    required double visibleLeft,
    required double visibleRight,
  }) {
    final zoneHeight = bottom - top;
    if (zoneHeight < 18 || visibleRight <= visibleLeft) {
      return;
    }

    final textStyle = theme.textTheme.labelSmall?.copyWith(
      color: color,
      fontWeight: FontWeight.w700,
    );
    final maxWidth = math.max(0.0, visibleRight - visibleLeft - 8);
    final textPainter = TextPainter(
      text: TextSpan(text: label, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);

    final labelTop = zoneHeight >= textPainter.height + 8
        ? top + 2
        : top + ((zoneHeight - textPainter.height) / 2);
    final dx = visibleRight - textPainter.width - 3;
    textPainter.paint(canvas, Offset(dx, labelTop));
  }

  void _paintGrid({
    required Canvas canvas,
    required double plotHeight,
    required double visibleLeft,
    required double visibleRight,
  }) {
    final dividerColor = theme.dividerColor;
    final chartStartDate = startDate;
    final isLightMode = theme.brightness == Brightness.light;
    final majorHorizontalAlpha = isLightMode ? 0.18 : 0.32;
    final minorHorizontalAlpha = isLightMode ? 0.07 : 0.12;
    final extraHorizontalAlpha = isLightMode ? 0.18 : 0.32;
    final monthBoundaryAlpha = isLightMode ? 0.14 : 0.22;
    final minorVerticalAlpha = isLightMode ? 0.05 : 0.08;

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(visibleLeft, 0, visibleRight, plotHeight));

    for (int value = 0; value <= maxVolume; value += 50) {
      final y = _yForValue(value.toDouble(), plotHeight);
      canvas.drawLine(
        Offset(visibleLeft, y),
        Offset(visibleRight, y),
        Paint()
          ..color = dividerColor.withValues(
            alpha: value % 100 == 0
                ? majorHorizontalAlpha
                : minorHorizontalAlpha,
          )
          ..strokeWidth = value % 100 == 0 ? 0.9 : 0.6,
      );
    }
    if (maxVolume % 50 != 0) {
      final y = _yForValue(maxVolume.toDouble(), plotHeight);
      canvas.drawLine(
        Offset(visibleLeft, y),
        Offset(visibleRight, y),
        Paint()
          ..color = dividerColor.withValues(alpha: extraHorizontalAlpha)
          ..strokeWidth = 0.9,
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
            alpha: isMonthBoundary ? monthBoundaryAlpha : minorVerticalAlpha,
          )
          ..strokeWidth = isMonthBoundary ? 0.8 : 0.55,
      );
    }

    canvas.restore();
  }

  void _paintAverageLine({
    required Canvas canvas,
    required double plotHeight,
    required double visibleLeft,
    required double visibleRight,
  }) {
    if (points.isEmpty || visibleRight <= visibleLeft) {
      return;
    }

    final total = points.fold<int>(0, (sum, point) => sum + point.value);
    final average = total / points.length;
    final y = _yForValue(average, plotHeight);
    final paint = Paint()
      ..color = theme.colorScheme.onSurface.withValues(alpha: 0.62)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(visibleLeft, 0, visibleRight, plotHeight));
    _drawDashedLine(
      canvas: canvas,
      start: Offset(visibleLeft, y),
      end: Offset(visibleRight, y),
      paint: paint,
      dashWidth: 7,
      gapWidth: 6,
    );
    canvas.restore();
  }

  void _drawDashedLine({
    required Canvas canvas,
    required Offset start,
    required Offset end,
    required Paint paint,
    required double dashWidth,
    required double gapWidth,
  }) {
    final delta = end - start;
    final distance = delta.distance;
    if (distance <= 0) {
      return;
    }

    final direction = delta / distance;
    var drawn = 0.0;
    while (drawn < distance) {
      final dashEnd = math.min(drawn + dashWidth, distance);
      canvas.drawLine(
        start + (direction * drawn),
        start + (direction * dashEnd),
        paint,
      );
      drawn = dashEnd + gapWidth;
    }
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
        text: intl.DateFormat('MMM yyyy', localeName).format(monthDate),
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
